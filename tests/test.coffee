#
#
#

console.dir = require "cdir"


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
  #cypher()


#
Node.types.Person = class Person extends Node
  constructor: (db, data) ->
    console.log "Person (Node)"
    super db, data
  
  delete: (batch, deps, cb) =>
    super batch, "Owns", cb

#
Node.types.Possession = class Possession extends Node
  constructor: (db, data) ->
    console.log "Possession (Node)"
    super db, data
    
  delete: (batch, deps, cb) =>
    super batch, "Stores", cb

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
  a = new Person db, { name:"A", born: new Date }
  b = new Person db, { name:"B", age: 10 }
  c = new Person db, { name:"C", age: 72 }
  ops = ops.concat [
    (cb) -> a.createAndIndex "users", "name", cb
    (cb) -> b.createAndIndex "users", "name", cb
    (cb) -> c.createAndIndex "users", "name", cb
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
  
  # make three vanilla nodes
  one = new Node db, storage:"unit"
  two = new Node db, storage:"r2d2"
  three = new Node db, storage:"thunderclap"
  ops = ops.concat [
    (cb) -> one.save cb
    (cb) -> two.save cb
    (cb) -> three.save cb
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
        (cb) -> b.createRelationship "Owns", money, null, cb
        (cb) -> c.createRelationship "Owns", money, null, cb
        (cb) -> money.createRelationship "Stores", one, null, cb
        (cb) -> money.createRelationship "Stores", two, null, cb
        (cb) -> money.createRelationship "Stores", three, null, cb
        (cb) -> a.createRelationship "Mega", one, null, cb
        (cb) -> a.createRelationship "Mega", two, null, cb
        (cb) -> b.createRelationship "Mega", three, null, cb
      ]
      
      async.parallel ops, (err, res) ->
        if err = handleError err, res
          console.log "Test stage 2 failed :(", err
        else
          console.log "All tests succeeded :)"
          #teardown()
          
#
cypher = ->
  q = """
  START n=node:Users("name:*")
  MATCH n<-[:Stores]-()<-[:Owns]-d
  RETURN n
  """
  db.cypher q, null, (err, data) ->
    console.dir data.data
  

#
teardown = ->
  console.log "teardown"
  db.queryNodeIndex "users", "*", "*", (err, people) =>
    ops = []
    people.forEach (person) => ops.push (cb) => person.delete null, null, cb
    async.parallel ops, (err) =>
      if err
        console.log "Test failed :(", err.message, err.details
      else
        console.log "All tests succeeded :)"
