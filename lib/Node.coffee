#
#
#


async = require "async"
util = require "./util"
BaseNode = require "./BaseNode"


module.exports = class Node extends BaseNode
  @types: {}    

  #
  createAndIndexUnique: (index, key, value, cb) =>
    index = index or @constructor.index
    key = key or @constructor.indexKey
    opts = 
      url: "#{@db.services.node_index}/#{index}?unique"
      method: "POST"
      json:
        key: key
        value: value
        properties: @serialize()
    @db.request opts, (err, resp, data) =>
      if resp.statusCode is 200
        err = new Error "Node exists"
      else
        err = @db.handleError err, resp
      if data
        @deserialize data
      cb err
