#
#
#


_ = require "underscore"
async = require "async"
request = require "request"
neo4j = require "../index.js"
util = require "../util"
handleError = util.handleError

Node = neo4j.Node
Relationship = neo4j.Relationship
db = new neo4j.GraphDatabase "http://localhost", "7474", (err) -> 
  console.log "DB connected! Running tests...", db
  buildup()
  #teardown()


#
Node.types.Person = class Person extends Node
  constructor: (db, data) ->
    console.log "Person (Node)"
    super db, data
  
  delete: (deps, jobs, cb) =>
    super "Owns", jobs, cb

#
Node.types.Possession = class Possession extends Node
  constructor: (db, data) ->
    console.log "Possession (Node)"
    super db, data

#
Relationship.types.Knows = class Knows extends Relationship
  constructor: (db, data) ->
    console.log "Knows (Relationship)"
    super db, data

#
Relationship.types.Owns = class Owns extends Relationship
  constructor: (db, data) ->
    console.log "Owns (Relationship)"
    super db, data




#
buildup = ->
  console.log "buildup"
  ops = []
  
  # make 3 people
  a = new Person db, { name:"A", age: 42 }
  b = new Person db, { name:"B", age: 10 }
  c = new Person db, { name:"C", age: 72 }
  ops = ops.concat [
    (cb) -> a.createAndIndexUnique "people", "name", cb
    (cb) -> b.createAndIndexUnique "people", "name", cb
    (cb) -> c.createAndIndexUnique "people", "name", cb
  ]

  # make three possessions
  keys = new Possession db, name:"keys"
  money = new Possession db, name:"money"
  cigarettes = new Possession db, name:"cigarettes"
  ops = ops.concat [
    (cb) -> keys.save cb
    (cb) -> money.save cb
    (cb) -> cigarettes.save cb
  ]
  
  async.parallel ops, (err, res) ->
    if err = handleError err, res
      console.log "Test stage 1 failed :(", err
    else
      
      # stage two, form relationships
      ops = [
        (cb) -> a.createRelationship "Knows", b, since:"highschool", cb
        (cb) -> a.createRelationship "Knows", c, since:"2007", cb
        (cb) -> c.createRelationship "Knows", b, since:"the beginning of time", cb
        (cb) -> a.createRelationship "Owns", keys, null, cb
        (cb) -> a.createRelationship "Owns", money, null, cb
        (cb) -> a.createRelationship "Owns", cigarettes, null, cb
      ]
      
      async.parallel ops, (err, res) ->
        if err = handleError err, res
          console.log "Test stage 2 failed :(", err
        else
          console.log "All tests succeeded :)"
          teardown()
          
          
#
teardown = ->
  console.log "teardown"
  db.queryNodeIndex "people", "*", "*", (err, people) =>
    jobs = []
    ops = []
    people.forEach (person) => ops.push (cb) => person.delete null, null, cb
    async.parallel ops, (err) =>
      if err
        console.log "Test failed :(", err.message, err.details
      else
        console.log "All tests succeeded :)"
