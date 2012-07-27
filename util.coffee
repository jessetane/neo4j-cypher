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
    error = new Error
    if _.isString response.body
      try
        error.message = JSON.parse(response.body.message).exception
      catch e
        try
          error.message = JSON.parse(response.body).exception
    else
      if response.body?
        error.message = response.body.message or response.body.exception
      else if response.statusCode
        error.message = response.statusCode
      else
        error.message = "Unknown Neo4j error"
    
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
  
  #if error and response then console.log "DEBUG", response.body
  return error
 
#     
exports.id = (url) ->
  if url
    parts = url.split "/"
    parts[parts.length-1]

#
exports.proxyProperty = (klass, propertyName) ->
  klass::__defineGetter__ propertyName, -> @properties[propertyName]
  klass::__defineSetter__ propertyName, (val) -> @properties[propertyName] = val

# should we make hard copies of these from underscore?
exports.extend = _.extend
