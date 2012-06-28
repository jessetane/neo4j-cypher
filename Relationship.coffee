#
#
#


_ = require "underscore"
util = require "./util"
handleError = util.handleError
request = require "request"
BaseNode = require "./BaseNode"


module.exports = class Relationship extends BaseNode
  @type: "relationship"
  @types: {}
  
  #
  save: (cb) =>
    if not @self
      return cb handleError "Relationships cannot be created directly"
    opts = 
      url: @self + "/properties"
      json: @serialize()
    request.put opts, (err, resp, data) =>
      cb packageError err, resp

  #
  fetchEndNode: (cb) =>
    Node = require "./Node"
    node = new Node @db, self: @data.end
    node.fetch (err, resp, data) =>
      if not err = handleError err, resp
        type = Node.types[node.properties.type]
        if type?
          node = new type node.data
        @end = node
      cb err
  