uuid = require 'uuid'
{Emitter} = require 'atom'
TwitterStreamClient = require "./twitter-stream-client"
{AuthorizationRequired} = require "./exceptions"

class TwitterStream extends Emitter
  constructor: (@oauth, @options) ->
    super
    @client = null
    @initialize()

  initialize: ->

  onError: (err) => @emit "error", err

  onResponse: (response) =>
    if response.statusCode is 200
      @emit "response", response
    else
      if response.statusMessage.match /Authorization Required/
        @emit "error", new AuthorizationRequired
      else
        @emit "error", response.statusMessage

  destroy: ->
    @client?.destroy()
    @dispose()

class PublicStream extends TwitterStream
  END_POINT: "https://stream.twitter.com/1.1/statuses/filter.json"

  initialize: ->
    @tracks = {}

  connect: (query) ->
    throw new Error "already set query" if query in @tracks

    id = "tweet-public-#{uuid.v4()}" # TODO rename
    @tracks[query] = id: id, re: new RegExp(query, "im")

    # we have to reconnect to endpoint to add a new query.
    @client.destroy() if @client?
    @client = new TwitterStreamClient @END_POINT, @oauth, @options

    @client.on "tweet", (tweet) =>
      @emit id, tweet for query, {id, re} of @tracks when tweet.text.match re

    @client.on "error", @onError
    @client.on "response", @onResponse

    @client.connect form: { track: Object.keys(@tracks).join(',') }

    id

class UserStream extends TwitterStream
  END_POINT: "https://userstream.twitter.com/1.1/user.json"

  initialize: ->
    @client = new TwitterStreamClient @END_POINT, @oauth, @options

  connect: ->
    id = "tweet-user"

    @client.on "tweet", (tweet) => @emit id, tweet
    @client.on "error", @onError
    @client.on "response", @onResponse
    @client.on "favorite", (event) => @emit "favorite", event

    @client.connect()

    id

exports.PublicStream = PublicStream
exports.UserStream = UserStream
