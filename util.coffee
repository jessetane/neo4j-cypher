#
#
#

_ = require "underscore"

#
exports.capitalize = (str) ->
  str.charAt(0).toUpperCase() + str.slice 1

#
exports.handleError = (error, response) ->
  
  # http errors
  if not error and response?.statusCode >= 400
    error = new Error response.body
    try
      error.message = JSON.parse(response.body.message).exception
    catch e
      try
        error.message = response.body.exception
    
  # other types
  else if error and not error instanceof Error
    
    # neo4j errors are http response objects
    if error.statusCode
      if error.body
        dbError = error.body
        try
          dbError = JSON.parse dbError
      else
        dbError = "Unknown database error"
      error = new Error dbError.message or dbError

    # hm, some other type... string?
    else
      error = new Error exports.capitalize error.toString()
  
  error?.message ?= response.body
  return error

# for deletion, we need relationships 
# to be deleted before nodes
exports.sortBatchForDelete = (batch) ->
  sorted = []
  _.each batch, (job) =>
    if job.to.search("node") > -1
      sorted.push job
    else
      sorted.unshift job
 
#     
exports.id = (url) ->
  _.last url.split "/"

#
exports.proxyProperty = (klass, propertyName) ->
  Object.defineProperty klass::, propertyName,
    get: ->
      return @property[propertyName]
    set: (val) ->
      @property[propertyName] = val
