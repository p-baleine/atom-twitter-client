_ = require "underscore"
AtomTwitterTimelineItemView = require "./atom-twitter-timeline-item-view"
{ScrollView} = require 'atom-space-pen-views'
TwitterStream = require './twitter-stream'

class AtomTwitterTimelineView extends ScrollView
  REFRESH_TIME_INTERVAL: 60000

  @content: ->
    @div class: 'twitter panel', =>
      @div class: 'panel-body padded', =>
        @div class: "loading", outlet: "loading", =>
          @div class: "loading-spinner-tiny inline-block"
          @p class: "inline-block", "fetching..."
        @ul class: 'tweets', outlet: 'list'

  initialize: (@stream, @rest, @id, @query, @bufferSize, @eventBus, @mutedUserIds) ->
    super

  attached: () ->
    @stream.on 'error', (err) -> throw err
    @stream.on "response", @removeLoadingImage
    @stream.on @id, @addItem
    @timer = setInterval =>
      @list.find(".tweet").trigger "refresh-time"
    , @REFRESH_TIME_INTERVAL

  removeLoadingImage: => @loading.hide()

  detached: ->
    @stream.off @id, @addItem
    clearInterval @timer
    @timer = null

  addItem: (tweet) =>
    return if @mutedUserIds and @mutedUserIds.indexOf(tweet.user.id) isnt -1
    @list.find(".tweet")[-1..].remove() if @list.find(".tweet").length > @bufferSize
    tweet = _.extend {}, tweet.retweeted_status, retweeted_by: tweet.user if tweet.retweeted_status?
    @list.prepend(new AtomTwitterTimelineItemView tweet, @rest, @eventBus)

  getTitle: -> @query

exports.PublicTimelineView = class PublicTimelineView extends AtomTwitterTimelineView
exports.UserTimelineView = class UserTimelineView extends AtomTwitterTimelineView
  attached: () ->
    super

    @rest.getHomeTimeline(atom.config.get "atom-twitter-client.homeTimelineLasts")
    .then (data) =>
      data = data.reverse()
      @addItem tweet for tweet in data
