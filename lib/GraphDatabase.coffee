#
#
#


request = require "request"
backoff = require "backoff"
util = require "./util"


#
module.exports = class GraphDatabase
  @databases: {}
  
  #
  constructor: (host, port, statusHandler) ->
    @constructor.databases.default ?= @
    @url = host + ":" + port + "/db/data"
    @version = ""
    @services = {}
    @connected = false
    @statusHandler = statusHandler
  
  #
  connect: (cb) =>
    @connecting = true
    opts =
      url: @url
      method: "GET"
    request opts, (err, resp, body) =>
      @connecting = false
      if not err = @handleError err, resp
        @services = JSON.parse body
        @version = @services.neo4j_version
        @connected = true
      @statusHandler?()
      cb? err
  
  #
  reconnect: =>
    @reconnecting = backoff.exponential initialDelay: 250
    @reconnecting.on "backoff", (attempt, delay) =>
      if not @connected
        if not @connecting
          @connect()
        @reconnecting.backoff()
      else
        delete @reconnecting
    @reconnecting.backoff()
  
  #
  cypherRaw: (query, params, cb) =>
    query = query: query
    if params then query.params = params
    opts = 
      url: "#{@services.cypher}"
      method: "POST"
      json: query
    @request opts, (err, resp, data) =>
      err = @handleError(err, resp)
      cb err, data?.data
  
  #
  cypher: (query, params, output, cb) =>
    @cypherRaw query, params, (err, paths) =>
      if err
        cb err
      else
        Node = require "./Node"
        Relationship = require "./Relationship"
        nodepaths = paths.map (path) =>
          path.map (node, i) =>
            if not node
              return null
            else
              klass = output?[i] or if node.all_relationships? then Node else Relationship
              new klass node
        cb err, nodepaths
  
  #
  request: (opts, cb) =>
    if @connected?
      request arguments...
    else if @reconnecting
      cb new Error "Database is attempting to reconnect - tried #{@reconnecting.backoffNumber_} time(s)"
    else
      cb new Error "Database is not connected"
  
  #
  handleError: (error, response) =>
    if response?.statusCode >= 400
      error = new Error
      if response.body?
        body = response.body
        if _.isString body
          try
            body = JSON.parse body
          catch e
            body = { message: response.body }  # maybe HTML error?
        if body.message?
          error.message = body.message.exception or body.message
        else if body.exception?
          error.message = body.exception
      else
        error.message = "Unknown neo4j error"
     
    # ECONNREFUSED means the db could not be contacted
    # attempt to reconnect with exponential backoff
    else if error?.code == "ECONNREFUSED"
      @connected = false
      @statusHandler error
      if not @reconnecting?
        @reconnect()
    
    return error

  # Deletes all nodes in the graph, but doesn't account for indexes...
  delete: (cb) =>
    q = """
    START n=nodes(*)
    MATCH n-[r?]-()
    DELETE r, n
    """
    @cypherRaw q, null, cb
