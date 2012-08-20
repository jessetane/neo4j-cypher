#
#
#


util = require "./util"
GraphDatabase = require "./GraphDatabase"


module.exports = class BaseNode
  
  # getter
  @::__defineGetter__ "nodetype", -> if @ instanceof require "./Node" then require "./Node" else require "./Relationship"
  @::__defineGetter__ "self", -> @data?.self
  @::__defineGetter__ "id", -> (util.id @self) or @properties.id
  
  #
  constructor: (data) ->
    @nodetype.types[@constructor.name] ?= @constructor
    @db = GraphDatabase.databases.default
    @deserialize data
  
  #
  deserialize: (data) =>
    @data = data or @data or {}
    @properties = util.extend @properties or {}, data?.data or data
  
  #
  serialize: =>
    @properties
  
  # NOTE: This may be unsafe as it looks nodes up by ID (Neo4j recycles ID's)
  save: (cb) =>
    if not @self?
      cb new Error type + " must exist in order to index"
    else
      q = """
      START n=node(#{@id})
      SET n={params}
      RETURN n
      """
      @db.cypherRaw { params: @serialize() }, (err, paths) =>
        if not err
          @deserialize paths[0][0].data
        cb err
  
  #
  index: (index, key, value, cb) =>
    if not @self?
      cb new Error type + " must exist in order to index"
    else
      type = @nodetype + "_index"
      opts =
        url: "#{@db.services[type]}/#{index}"
        method: "POST"
        json:
          uri: @self
          key: key
          value: value
      @db.request opts, (err, resp) =>
        cb @db.handleError err, resp
  
  #
  deindex: (index, key, cb) =>
    type = @nodetype + "_index"
    opts = 
      url: "#{@db.services[type]}/#{index}/#{key}/#{@id}"
      method: "DELETE"
    @db.request opts, (err, resp) =>
      cb @db.handleError err, resp
  
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
