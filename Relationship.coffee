#
#
#


util = require "./util"
handleError = util.handleError
request = require "request"
BaseNode = require "./BaseNode"


module.exports = class Relationship extends BaseNode
  @types: {}
