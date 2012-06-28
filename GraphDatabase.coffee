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
    @url = host + ":" + port
    @version = ""
    @services = {}
    opts =
      url: @url + "/db/data"
    request.get opts, (err, resp, body) =>
      if not err = handleError err, resp
        @services = JSON.parse body
        @version = @services.neo4j_version
      cb err
  
  #
  queryIndex: (type, index, key, val, cb) ->
    baseType = if type == "node" then require "./Node" else require "./Relationship"
    type = type + "_index"
    query = encodeURIComponent key + ":" + val
    opts = url: "#{@services[type]}/#{index}?query=#{query}"
    request.get opts, (err, resp, data) =>
      results = JSON.parse data
      results = results.map (result) =>
        type = baseType[result.data.type]
        if not type? then type = baseType
        new type @db, result
      if results.length == 1 then results = results[0]
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
