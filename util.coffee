#
#
#

_ = require "underscore"

#
capitalize = (str) ->
  str.charAt(0).toUpperCase() + str.slice 1

#
module.exports.handleError = (error, response) ->
  
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
      error = new Error capitalize error.toString()
  
  error?.message ?= response.body
  return error
