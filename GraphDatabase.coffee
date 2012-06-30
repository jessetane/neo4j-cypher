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
      cb? err
  
  #
  batch: (batch, cb) =>
    opts = url: @services.batch, json: batch
    request.post opts, (err, resp, data) =>
      cb handleError(err, resp), data
  
  # super lame but we need this 
  # until the batch API improves
  batchUnique: (batch, cb) =>
    @queued ?= {}
    @pending ?= {}
    pending = []
    unique = []
    queuekey = null
    lookup = {}
    _.each @pending, (pendingBatch) => 
      pendingBatch.forEach (job) => lookup[JSON.stringify job] = pendingBatch
      pending = pending.concat pendingBatch
    pending.reverse()
    batch.forEach (job) =>
      duplicate = _.find pending, (pendingJob) => if _.isEqual job, pendingJob then pendingJob
      if duplicate
        queuekey = lookup[JSON.stringify duplicate][0]
      else
        unique.push job
    if unique.length == 0
      cb()
    else
      batchkey = JSON.stringify unique[0]
      @pending[batchkey] = unique
      @queued[batchkey] = []
      batchRequest = =>
        @batch unique, (args...) =>
          @queued[batchkey].forEach (job) => job()
          if _.keys(@queued).length is 0 
            delete @pending
          delete @queued[batchkey]
          cb args...
      if not @queued[JSON.stringify queuekey]?.push batchRequest
        batchRequest()
  
  #
  queryNodeIndex: (args...) =>
    @queryIndex "node", args...
    
  #
  queryRelationshipIndex: (args...) =>
    @queryIndex "relationship", args...
  
  #
  queryIndex: (type, index, key, val, cb) =>
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
  
  # TODO
  cypher: (query, params, cb) =>
    query = query: query
    if params then query.params = params
    opts = 
      url: "#{@services.cypher}"
      json: query
    request.post opts, (err, resp, data) =>
      cb handleError(err, resp), data
