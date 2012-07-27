#
#
#


util = require "./util"
handleError = util.handleError
request = require "request"
GraphDatabase = require "./GraphDatabase"


module.exports = class BaseNode
  
  # getter
  @::__defineGetter__ "nodetype", -> if @ instanceof require "./Node" then "node" else "relationship"
  @::__defineGetter__ "self", -> @data?.self
  @::__defineGetter__ "id", -> (util.id @self) or @properties.id
  
  #
  constructor: (data) ->
    @db = GraphDatabase.databases.default
    @deserialize data
  
  #
  deserialize: (data) =>
    @data = data or @data or {}
    @properties = util.extend @properties or {}, data?.data or data
  
  #
  serialize: =>
    @properties
  
  #
  save: (cb) =>
    if @self
      url = @self + "/properties"
      method = "put"
    else if @nodetype == "relationship"
      cb handleError "Relationships cannot be created directly"
    else
      url = "#{@db.services[@nodetype]}"
      method = "post"
    opts = url: url, json: @serialize()
    request[method] opts, (err, resp, data) =>
      if not err = handleError err, resp
        @deserialize data
      cb err
  
  #
  index: (index, key, value, cb) =>
    if not @self?
      cb handleError type + " must exist in order to index"
    else
      type = @nodetype + "_index"
      opts =
        url: "#{@db.services[type]}/#{index}"
        json:
          uri: @self
          key: key
          value: value
      response = request.post opts, (err, resp) =>
        cb handleError err, resp
  
  #
  deindex: (index, key, cb) =>
    type = @nodetype + "_index"
    opts = url: "#{@db.services[type]}/#{index}/#{key}/#{@id}"
    response = request.del opts, (err, resp) =>
      cb handleError err, resp
  
  #
  delete: (cb) =>
    if @nodetype == "node"
      q="""
      START n=node(#{@id})
      MATCH n-[r?]-()
      DELETE r, n
      """
    else
      q="""
      START r=relationship(#{@id})
      DELETE r
      """
    @db.cypherRaw q, null, cb
