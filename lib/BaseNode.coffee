#
#
#


util = require "./util"
GraphDatabase = require "./GraphDatabase"


module.exports = class BaseNode

  # getter
  @::__defineGetter__ "basetype", -> if @ instanceof require "./Node" then require "./Node" else require "./Relationship"
  @::__defineGetter__ "basename", -> if @ instanceof require "./Node" then "node" else "relationship"
  @::__defineGetter__ "self", -> @data?.self
  @::__defineGetter__ "id", -> (util.id @self) or @properties.id

  #
  constructor: (data) ->
    @basetype.types[@constructor.name] ?= @constructor
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
  index: (index, key, value, cb) =>
    if not @self?
      cb new Error type + " must exist in order to index"
    else
      type = @basename + "_index"
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
    type = @basename + "_index"
    opts = 
      url: "#{@db.services[type]}/#{index}/#{key}/#{@id}"
      method: "DELETE"
    @db.request opts, (err, resp) =>
      cb @db.handleError err, resp

  # M07 doesn't seem to be ready for this yet!
  #
  # save: (cb) =>
  #   if not @self?
  #     cb new Error type + " must exist in order to index"
  #   else
  #     q = """
  #     START n=node(#{@id})
  #     SET n={map}
  #     RETURN n
  #     """
  #     @db.cypherRaw q, { map: @serialize() }, (err, paths) =>
  #       if not err
  #         @deserialize paths[0][0].data
  #       cb err

  #
  save: (cb) =>
    if @self
      url = @self + "/properties"
      method = "PUT"
    else if @basename is "relationship"
      cb new Error "Relationships cannot be created directly"
    else
      url = "#{@db.services[@basename]}"
      method = "POST"
    opts = 
      url: url
      method: method
      json: @serialize()
    @db.request opts, (err, resp, data) =>
      if not err = @db.handleError err, resp
        @deserialize data
      cb err

  #
  delete: (cb) =>
    if @basename == "node"
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
