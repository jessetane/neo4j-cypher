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
  @::__defineGetter__ "id", -> util.id @self
  
  #
  constructor: (data={}) ->
    @db = GraphDatabase.databases.default
    @deserialize data
  
  #
  deserialize: (data={}) =>
    @data = data
    @properties = _.extend @properties or {}, data.data or data
  
  #
  serialize: =>
    @properties
  
  #
  save: (cb) =>
    if @self
      url = @self + "/properties"
      method = "put"
    else if @nodetype == "relationship"
      cb new Error "Relationships cannot be created directly"
    else
      url = "#{@db.services[@nodetype]}"
      method = "post"
      @properties._type_ = @constructor.name
    opts = url: url, json: @serialize()
    request[method] opts, (err, resp, data) =>
      if not err = handleError err, resp
        @deserialize data
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
      
  #
  delete: (cb) =>
    job = 
      to: @self.split(@db.url)[1]
      method: "DELETE"
    
    # if we have a callback, we are master
    if _.isFunction cb
      @db.batchUnique batch, cb
    
    # otherwise, just return the job
    else
      return job
