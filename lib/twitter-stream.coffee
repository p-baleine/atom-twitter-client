uuid = require 'uuid'
{Emitter} = require 'atom'
{userStream, publicStream} = require "twitter-streaming-client"

class TwitterStream extends Emitter
  constructor: (@oauth, @options) ->
    super
    @client = null
    @initialize()

  initialize: ->

  onError: (err) => @emit "error", err

  onResponse: (response) =>
    @emit "response", response

  destroy: ->
    @client?.close()
    @dispose()

class PublicStream extends TwitterStream
  initialize: ->
    @tracks = {}

  connect: (query) ->
    throw new Error "already set query" if query in @tracks

    id = "tweet-public-#{uuid.v4()}" # TODO rename
    @tracks[query] = id: id, re: new RegExp(query, "im")

    # we have to reconnect to endpoint to add a new query.
    @client.close() if @client?
    @client = publicStream @oauth

    @client.on "status", (status) =>
      @emit id, status for query, {id, re} of @tracks when status.text.match re

    @client.on "error", @onError
    @client.on "response", @onResponse

    @client.open form: { track: Object.keys(@tracks).join(',') }

    id

class UserStream extends TwitterStream
  connect: ->
    id = "tweet-user"

    @client.close() if @client?
    @client = userStream @oauth

    @client.on "status", (status) => @emit id, status
    @client.on "error", @onError
    @client.on "response", @onResponse
    @client.on "favorite", (event) => @emit "favorite", event

    @client.open()

    id

exports.PublicStream = PublicStream
exports.UserStream = UserStream
