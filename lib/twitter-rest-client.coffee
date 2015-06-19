_ = require "underscore"
Promise = require "bluebird"
request = require "request"

module.exports =
class TwitterRestClient
  constructor: (@oauth, @options) ->

  createFavorite: (id) ->
    @post "/favorites/create.json?id=#{id}"

  destroyFavorite: (id) ->
    @post "/favorites/destroy.json?id=#{id}"

  post: (endpoint) ->
    new Promise (resolve, reject) =>
      buffer = ""
      params = _.extend { url: "https://api.twitter.com/1.1#{endpoint}", oauth: @oauth }, @options
      request
      .post params
      .on "response", (response) -> reject response.statusMessage unless response.statusCode is 200
      .on "data", (data) ->
        buffer += data.toString("utf8")
      .on "end", ->
        try
          resolve JSON.parse buffer
        catch error
          reject error
      .on "error", (err) -> reject err
