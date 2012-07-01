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
      cb handleError err, resp
