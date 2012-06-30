#
#
#


_ = require "underscore"
util = require "./util"
handleError = util.handleError
request = require "request"
GraphDatabase = require "./GraphDatabase"


module.exports = class BaseNode
  
  # getter
  @::__defineGetter__ "nodetype", -> if @ instanceof require "./Node" then "node" else "relationship"
  @::__defineGetter__ "self", -> @data?.self
  
  #
  constructor: (db, data={}) ->
    @db = db
    @deserialize data
  
  #
  deserialize: (data={}) =>
    @data = data
    @properties = data.data or data
  
  #
  serialize: =>
    JSON.stringify @properties
  
  #
  fetch: (cb) =>
    if @self
      opts = url: @self
    else
      index = encodeURIComponent @constructor.index
      key = encodeURIComponent @constructor.indexKey
      val = encodeURIComponent @properties[@constructor.indexKey]
      type = @nodetype + "_index"
      opts = url: "#{@db.services[type]}/#{index}/#{key}/#{val}"
    request.get opts, (err, resp, data) =>
      if not err = handleError err, resp
        @deserialize JSON.parse data
      cb err
  
  #
  index: (index, key, cb) =>
    if not @self?
      cb handleError type + " must exist in order to index"
    else
      type = @nodetype + "_index"
      url: "#{@db.services[type]}/#{index}"
      json:
        uri: url
        key: key
        value: @properties[key]
      response = request.post opts, (err, resp) =>
        cb handleError err, resp
