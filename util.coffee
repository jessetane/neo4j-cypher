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
    if _.isString response.body
      try
        error.message = JSON.parse(response.body.message).exception
      catch e
        try
          error.message = JSON.parse(response.body).exception
    else
      error.message = response.body.message or response.body.exception
    
  # other types
  else if error and error not instanceof Error
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
    else if error
      error = new Error exports.capitalize error.toString()
  
  if error and response then console.log "DEBUG", response.body
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
  return sorted
 
#     
exports.id = (url) ->
  if url
    _.last url.split "/"

#
exports.proxyProperty = (klass, propertyName) ->
  klass::__defineGetter__ propertyName, -> @properties[propertyName]
  klass::__defineSetter__ propertyName, (val) -> @properties[propertyName] = val

###
exports.proxyProperty = (klass, propertyName, encode) ->
  klass::__defineGetter__ propertyName, -> 
    val = @properties[propertyName]
    if encode
      val = decodeURIComponent val
    return val
  klass::__defineSetter__ propertyName, (val) -> 
    if encode
      val = encodeURIComponent val
    @properties[propertyName] = val
###
