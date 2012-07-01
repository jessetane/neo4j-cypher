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
buildup = ->
  console.log "buildup"
  ops = []
  
  # make some users
  a = new Node db, name:"A"
  b = new Node db, name:"B"
  c = new Node db, name:"C"
  ops = ops.concat [
    (cb) -> a.createAndIndex "users", "name", cb
    (cb) -> b.createAndIndex "users", "name", cb
    (cb) -> c.createAndIndex "users", "name", cb
  ]

  # make some groups
  g1 = new Node db, name:"G1"
  g2 = new Node db, name:"G2"
  g3 = new Node db, name:"G3"
  ops = ops.concat [
    (cb) -> g1.save cb
    (cb) -> g2.save cb
    (cb) -> g3.save cb
  ]

  # make some sources
  a_twitter = new Node db, name:"Twitter"
  a_insta = new Node db, name:"Instagram"
  b_twitter = new Node db, name:"Twitter"
  b_insta = new Node db, name:"Instagram"                                       
  c_twitter = new Node db, name:"Twitter"
  c_insta = new Node db, name:"Instagram"
  ops = ops.concat [
    (cb) -> a_twitter.save cb
    (cb) -> a_insta.save cb
    (cb) -> b_twitter.save cb
    (cb) -> b_insta.save cb
    (cb) -> c_twitter.save cb
    (cb) -> c_insta.save cb
  ]
  
  # make some feeds
  f1 = new Node db, tag:"g1"
  f2 = new Node db, tag:"g1"
  f3 = new Node db, tag:"g1"
  f4 = new Node db, tag:"g1"
  f5 = new Node db, tag:"g1"
  f6 = new Node db, tag:"g1"
  ops = ops.concat [
    (cb) -> f1.save cb
    (cb) -> f2.save cb
  ]
  
  async.parallel ops, (err, res) ->
    if err = handleError err, res
      console.log "Test stage 1 failed :(", err
    else
      
      # stage two, form relationships
      ops = [
        
        # join groups
        (cb) -> a.createRelationship "BelongsTo", g1, since:"1999", cb
        (cb) -> b.createRelationship "BelongsTo", g1, since:"1999", cb
        (cb) -> c.createRelationship "BelongsTo", g1, since:"1999", cb
        
        # add sources
        (cb) -> a.createRelationship "SwipesFrom", a_twitter, null, cb
        (cb) -> a.createRelationship "SwipesFrom", a_insta, null, cb
        (cb) -> b.createRelationship "SwipesFrom", b_twitter, null, cb
        (cb) -> b.createRelationship "SwipesFrom", b_insta, null, cb
        (cb) -> c.createRelationship "SwipesFrom", c_twitter, null, cb
        (cb) -> c.createRelationship "SwipesFrom", c_insta, null, cb
        
        # a connects a feed to g1 sourced from Twitter
        (cb) -> f1.createRelationship "Feeds", g1, null, cb
        (cb) -> f1.createRelationship "ConnectedBy", a, null, cb
        (cb) -> f1.createRelationship "SourcedFrom", a_twitter, null, cb
        
        # b connects a feed to g1 sourced from Instagram
        (cb) -> f2.createRelationship "Feeds", g1, null, cb
        (cb) -> f2.createRelationship "ConnectedBy", b, null, cb
        (cb) -> f2.createRelationship "SourcedFrom", b_insta, null, cb
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
