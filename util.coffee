#
#
#

#
capitalize = (str) ->
  str.charAt(0).toUpperCase() + str.slice 1

#
module.exports.handleError = (error, response) ->
  
  # http errors
  if not error and response?.statusCode >= 400
    error = new Error response.statusCode
    error.message = response.statusCode
  
  # other types, let 
  else if error and not error instanceof Error
    
    # neo4j errors are http response objects
    if error.statusCode
      if error.body
        dbError = error.body
        try
          dbError = JSON.parse dbError
      else
        dbError = "Unknown database error"
      message = dbError.message or dbError
      error = new Error message
      error.message = message

    # hm, some other type... string?
    else
      message = capitalize error.toString()
      error = new Error message
      error.message = message

  else if error
    # make sure we have some kind of message
    error.message ?= error.toString()
    
  return error
