#
#
#


_ = require "underscore"
util = require "./util"
handleError = util.handleError
request = require "request"
BaseNode = require "./BaseNode"


module.exports = class Relationship extends BaseNode
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
    node.fetch (err, resp) =>
      if not err = handleError err, resp
        type = Node.types[node.properties._type_]
        if type?
          node = new type @db, node.data
        @end = node
      cb err
  
  #
  delete: (jobs, cb) =>
    if not jobs
      master = true
      jobs = []

    jobs.push
      to: @self.split(@db.url)[1]
      method: "DELETE"

    if master
      super jobs, cb
    else
      if @end
        @end.delete null, jobs, ->
          cb null, jobs
      else
        cb null, jobs