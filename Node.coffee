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
  @type: "node"
  @types: {}
  
  #
  fetchAllRelationships: (fetchEndNodes, cb) =>
    @fetchRelationships null, null, fetchEndNodes, cb
  
  #
  fetchRelationships: (types, direction, fetchEndNodes, cb) =>
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
          type = Relationship.types[relationship.type]
          if not type? then type = Relationship
          rel = new type @db, relationship
          rel.start = @
          rels.push rel
          @relationships[relationship.type] ?= []
          @relationships[relationship.type].push rel
        if fetchEndNodes
          ops = []
          rels.forEach (rel) => ops.push (cb) => rel.fetchEndNode cb
          async.parallel ops, cb
        else
          cb()
  
  #
  createRelationship: (node, type, properties, cb) =>
    if not @self
      return cb handleError "Node must exist to create relationships"
    data.to = @self
    data.type = type
    data.data = properties
    opts = url: @self + "/relationships", json: data
    request.post opts, (err, resp, data) =>
      if not err = handleError err, resp
        rel = new Relationship @db, JSON.parse data
        rel.start = @
        @relationships ?= {}
        @relationships[type] ?= []
        @relationships[type].push rel
      cb err
  
  #
  save: (cb) =>
    if @self
      url = @self + "/properties"
      method = "put"
    else
      url = "#{@db.services.node}"
      method = "post"
    opts = url: url, json: @serialize()
    request[method] opts, (err, resp, data) =>
      cb hanleError err, resp
