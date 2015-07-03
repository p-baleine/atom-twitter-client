_ = require "underscore"
AtomTwitterTimelineItemView = require "./atom-twitter-timeline-item-view"
{ScrollView} = require 'atom-space-pen-views'
TwitterStream = require './twitter-stream'

module.exports =
class AtomTwitterTimelineView extends ScrollView
  REFRESH_TIME_INTERVAL: 60000

  @content: ->
    @div class: 'twitter panel', =>
      @div class: 'panel-body padded', =>
        @ul class: 'tweets', outlet: 'list'

  initialize: (@stream, @rest, @id, @query, @bufferSize) ->
    super
    @stream.on 'error', (err) -> throw err
    @stream.on @id, @addItem
    @timer = setInterval =>
      @list.find(".tweet").trigger "refresh-time"
    , @REFRESH_TIME_INTERVAL

  ditached: ->
    @stream.off @id, @addItem
    clearInterval @timer
    @timer = null

  addItem: (tweet) =>
    @list.find(".tweet")[-1..].remove() if @list.find(".tweet").length > @bufferSize
    tweet = _.extend {}, tweet.retweeted_status, retweeted_by: tweet.user if tweet.retweeted_status?
    @list.prepend new AtomTwitterTimelineItemView tweet, @rest

  getTitle: -> @query
