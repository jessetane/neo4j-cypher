#
#
#


request = require "request"
util = require "./util"
handleError = util.handleError


module.exports = class GraphDatabase
  @databases: {}
  
  #
  constructor: (host, port, cb) ->
    @constructor.databases.default ?= @
    @url = host + ":" + port + "/db/data"
    @version = ""
    @services = {}
    opts =
      url: @url
    request.get opts, (err, resp, body) =>
      if not err = handleError err, resp
        @services = JSON.parse body
        @version = @services.neo4j_version
      cb? err
  
  #
  cypherRaw: (query, params, cb) =>
    query = query: query
    if params then query.params = params
    opts = 
      url: "#{@services.cypher}"
      json: query
    request.post opts, (err, resp, data) =>
      err = handleError(err, resp)
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
  delete: (cb) =>
    q = """
    START n=nodes(*)
    MATCH n-[r?]-()
    DELETE r, n
    """
    @cypherRaw q, null, cb
