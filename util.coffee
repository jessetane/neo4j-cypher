#
#
#

#
exports.capitalize = (str) ->
  str.charAt(0).toUpperCase() + str.slice 1
 
#     
exports.id = (url) ->
  if url
    parts = url.split "/"
    parts[parts.length-1]

#
exports.proxyProperty = (klass, propertyName) ->
  klass::__defineGetter__ propertyName, -> @properties[propertyName]
  klass::__defineSetter__ propertyName, (val) -> @properties[propertyName] = val

#
exports.extend = (x, y) ->
  for k,v of y
    x[k] = v
  return x