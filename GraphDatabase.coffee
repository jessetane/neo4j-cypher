#
#
#


_ = require "underscore"
request = require "request"
util = require "./util"
handleError = util.handleError


module.exports = class GraphDatabase
  @db: null
  
  #
  constructor: (host, port, cb) ->
    @constructor.db = @
    @url = host + ":" + port + "/db/data"
    @version = ""
    @services = {}
    opts =
      url: @url
    request.get opts, (err, resp, body) =>
      if not err = handleError err, resp
        @services = JSON.parse body
        @version = @services.neo4j_version
      cb err
  
  #
  transact: (jobs, cb) =>
    to = []
    sorted = []
    _.each jobs, (job) =>
      if job.to not in to
        to.push job.to
        if job.to.search("node") > -1
          sorted.push job
        else
          sorted.unshift job
    console.log "JOBS", sorted
    opts = url: @services.batch, json: sorted
    request.post opts, (err, resp, data) =>
      cb handleError(err, resp), data
  
  #
  queryNodeIndex: (args...) =>
    @queryIndex "node", args...
    
  #
  queryRelationshipIndex: (args...) =>
    @queryIndex "relationship", args...
  
  #
  queryIndex: (type, index, key, val, cb) ->
    baseType = if type == "node" then require "./Node" else require "./Relationship"
    type = type + "_index"
    query = encodeURIComponent key + ":" + val
    opts = url: "#{@services[type]}/#{index}?query=#{query}"
    request.get opts, (err, resp, data) =>
      results = JSON.parse data
      results = results.map (result) =>
        klass = baseType.types[result.type or result.data._type_] or baseType
        new klass @, result
      cb handleError(err, resp), results
  
  
  ### i hate SQL, do we really need this?
  cypher: (query, params, cb) ->
    query = { query: query }
    if params then query.params = params
    opts = 
      url: "#{@services.cypher}"
      json: query
    request.post opts, (err, resp, data) =>
      cb handleError(err, resp), data
  ###
