db = require "db.js"
Promise = require "bluebird"

SCHEMA =
  server: "atom-twitter"
  version: 1
  schema:
    accounts:
      key: { keyPath: "user_id" }

exports.open = ->
  new Promise (resolve, reject) ->
    db.open SCHEMA
    .then resolve
