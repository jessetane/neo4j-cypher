#
#
#


_ = require "underscore"
async = require "async"
request = require "request"
util = require "./util"
handleError = util.handleError
BaseNode = require "./BaseNode"


module.exports = class Node extends BaseNode
  @types: {}
  
  #
  createAndIndex: (index, key, cb) =>
    console.log "create"
    
  #
  createAndIndexUnique: (index, key, cb) =>
    index = index or @constructor.index
    key = key or @constructor.indexKey
    @properties._type_ = @constructor.name
    opts = 
      url: "#{@db.services.node_index}/#{index}?unique"
      json: 
        key: key
        value: @properties[key]
        properties: @properties
    request.post opts, (err, resp, data) =>
      if resp.statusCode is 200
        err = new Error 409
        err.message = "Node exists"
      else 
        err = handleError err, resp
      if not err
        @deserialize data
      cb err
  
  #
  createRelationship: (type, node, properties, cb) =>
    if not @self or not node.self
      return cb handleError "Nodes must exist to create relationships"
    data = {}
    data.to = node.self
    data.type = type
    data.data = properties
    opts = url: @self + "/relationships", json: data
    request.post opts, (err, resp, data) =>
      if not err = handleError err, resp
        Relationship = require "./Relationship"
        klass = Relationship.types[type] or Relationship
        rel = new klass @db, data
        rel.start = @
        rel.end = node
        @relationships ?= {}
        @relationships[type] ?= []
        @relationships[type].push rel
      cb err
      
  #
  fetchAllRelationships: (relationshipTypesToFetchEndNodesFor, cb) =>
    @fetchRelationships null, null, relationshipTypesToFetchEndNodesFor, cb
  
  #
  fetchRelationships: (types, direction, relationshipTypesToFetchEndNodesFor, cb) =>
    Relationship = require "./Relationship"
    url = "#{@self}/relationships/"
    if direction
      url += direction
    else 
      url += "all"
    if types
      if not _.isArray types then types = [types]
      url += "/" + encodeURIComponent types.join "&"
    opts = url: url
    request.get opts, (err, resp, data) =>
      if err = handleError err, resp
        cb err
      else
        data = JSON.parse data
        @relationships ?= {}
        rels = []
        data.forEach (relationship) =>
          klass = Relationship.types[relationship.type] or Relationship
          rel = new klass @db, relationship
          rel.start = @
          rels.push rel
          @relationships[relationship.type] ?= []
          @relationships[relationship.type].push rel
        if relationshipTypesToFetchEndNodesFor?
          if not _.isBoolean relationshipTypesToFetchEndNodesFor
            relTypes = relationshipTypesToFetchEndNodesFor
            if not _.isArray relTypes
              relTypes = [ relTypes ]
          ops = []
          rels.forEach (rel) => 
            if not relTypes? or rel.data.type in relTypes
              ops.push (cb) => rel.fetchEndNode cb
          async.parallel ops, cb
        else
          cb()
  
  #
  save: (cb) =>
    if @self
      url = @self + "/properties"
      method = "put"
    else
      url = "#{@db.services.node}"
      method = "post"
      @properties._type_ = @constructor.name
    opts = url: url, json: @properties
    request[method] opts, (err, resp, data) =>
      if not err = handleError err, resp
        @deserialize data
      cb err

  #
  delete: (relationshipsToDeleteEndNodesFor, jobs, cb) =>
    if not jobs
      master = true
      jobs = []
    
    jobs.push
      to: @self.split(@db.url)[1]
      method: "DELETE"
    
    @relationships = null
    @fetchRelationships null, null, relationshipsToDeleteEndNodesFor, (err) =>
      ops = []
      _.each @relationships, (relType) =>
        relType.forEach (rel) =>
          ops.push (cb) => rel.delete jobs, cb
      async.parallel ops, (err) =>
        if not master
          cb null, jobs
        else
          
          # for deletion, we need relationships 
          # to be deleted before nodes
          resources = []
          sorted = []
          _.each jobs, (job) =>
            if job.to not in resources
              resources.push job.to
              if job.to.search("node") > -1
                sorted.push job
              else
                sorted.unshift job
          
          super sorted, (err) =>
            if err
              cb err
              ###
              # there is always the chance that a mutual
              # relationship was deleted by a parallel
              # request, so it's worth retrying at least until
              # we don't get a RelationshipNotFoundException
              if err.message.search("RelationshipNotFoundException") > -1
                @_backoff ?= 100
                console.log "RelationshipNotFoundException - retrying in " + @_backoff + "ms..."
                setTimeout => 
                  @delete relationshipsToDeleteEndNodesFor, null, cb
                , @_backoff += 100
              else
                cb err
              ###
            else
              cb()
