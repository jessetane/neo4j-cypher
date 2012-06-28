#
#
#


_ = require "underscore"
util = require "./util"
handleError = util.handleError
request = require "request"
GraphDatabase = require "./GraphDatabase"


module.exports = class BaseNode
  @type = null # subclasses must implement
  
  # getter
  @::__defineGetter__ "self", -> @data?.self
  
  #
  constructor: (db, data={}) ->
    @db = db
    @deserialize data
  
  #
  deserialize: (data={}) =>
    @data = data
    @properties = data.data
  
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
      type = @constructor.type + "_index"
      opts = url: "#{@db.services[type]}/#{index}/#{key}/#{val}"
    request.get opts, (err, resp, data) =>
      if not err = handleError err, resp
        @deserialize JSON.parse data
      cb err
  
  #
  delete: (force=false, cb) =>
    opts = url: @self
    request.del opts, (err, resp, data) =>
      cb handleError err, resp
  
  #
  index: (index, key, cb) =>
    if not dbobj.self?
      cb handleError type + " must exist in order to index"
    else
      type = @constructor.type + "_index"
      url: "#{@db.services[type]}/#{index}"
      json:
        uri: url
        key: key
        value: dbobj[key]
      response = request.post opts, (err, resp, data) =>
        cb handleError err, resp
        