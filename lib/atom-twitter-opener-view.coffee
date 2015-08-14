_ = require "underscore"
{$, View, TextEditorView} = require 'atom-space-pen-views'
{UserTimelineView, PublicTimelineView} = require './atom-twitter-timeline-view'
{CompositeDisposable, Emitter} = require 'atom'
database = require "./database"
Logger = require "./logger"
Promise = require "bluebird"
{PublicStream,UserStream} = require './twitter-stream'
AtomTwitterTweetEditorView = require "./atom-twitter-tweet-editor-view"
TwitterRestClient = require "./twitter-rest-client"
url = require 'url'

AUTH_URL = "https://atom-twitter-auth-serv.herokuapp.com/auth"

module.exports =
class AtomTwitterOpenerView extends View
  atomTwitterTimelineViewDict: {}
  modalPanel: null
  subscriptions: null
  publicStream: null

  @content: ->
    @div class: 'twitter-opener', =>
      @subview 'searchWordEditor', new TextEditorView mini: true, placeholderText: "Search tweets..."
      @subview "tweetEditor", new AtomTwitterTweetEditorView

  log: new Logger("AtomTwitterOpenerView")

  initialize: (state) ->
    bufferSize = atom.config.get "atom-twitter-client.timlineBufferSize" or 50

    @modalPanel = atom.workspace.addModalPanel(item: @)

    @eventBus = new Emitter

    atom.commands.add @element,
      'core:confirm': => @confirm()
      'core:cancel': => @close()

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-twitter:search': => @search()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-twitter:home': => @home()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-twitter:tweet': => @tweet()
    @eventBus.on 'atom-twitter:tweet', @tweet

    atom.workspace.addOpener (uriToOpen) =>
      {protocol, host, pathname, query} = url.parse uriToOpen, on
      return unless protocol is 'twitter:'

      switch host
        when "search"
          title = "#{query.q} - Twitter Search"
          view = new PublicTimelineView @publicStream, @rest, query.id, title, bufferSize, @eventBus
          @atomTwitterTimelineViewDict[query.q] = view
        when "home"
          title = "Twitter Home"
          view = new UserTimelineView @userStream, @rest, query.id, title, bufferSize, @eventBus, @mutedUserIds
          @atomTwitterTimelineViewDict["__user"] = view

  destroy: ->
    @publicStream?.destroy()
    @userStream?.destroy()
    @subscriptions.dispose()
    @modalPanel?.destroy()
    view.destroy() for view in @atomTwitterTimelineViewDict

  search: ->
    @tweetEditor.hide()

    @prepare()
    .done =>
      @previouslyFocusedElement = $(document.activeElement)
      @modalPanel.show()
      @tweetEditor.hide()
      @searchWordEditor.show()
      @searchWordEditor.focus()
    , (err) -> throw err

  home: ->
    return if "__user" in @atomTwitterTimelineViewDict

    @searchWordEditor.hide()
    @tweetEditor.hide()

    @prepare()
    .done =>
      id = @userStream.connect()
      uri = "twitter://home?id=#{id}"
      atom.workspace.open uri, split: 'right', searchAllPanes: on
      @close()
    , (err) -> throw err

  tweet: (options) =>
    @searchWordEditor.hide()

    @prepare()
    .done =>
      @tweetEditor.setUp @, @configuration, @rest, options
      @previouslyFocusedElement = $(document.activeElement)
      @modalPanel.show()
      @searchWordEditor.hide()
      @tweetEditor.show()
      @tweetEditor.focus()
    , (err) -> throw err

  confirm: ->
    query = @searchWordEditor.getText().trim()
    return unless query.length > 0
    @searchWordEditor.setText("")
    return if query in @atomTwitterTimelineViewDict
    id = @publicStream.connect query
    uri = "twitter://search?q=#{query}&id=#{id}"
    atom.workspace.open uri, split: 'right', searchAllPanes: on
    @close()

  close: ->
    return unless @modalPanel.isVisible()
    @modalPanel.hide()
    @previouslyFocusedElement?.focus()

  notifyFavorite: (event) =>
    return unless event.target.id is @currentUserId
    atom.notifications.addInfo """
    #{event.source.name} favorited your Tweet
    <p class="twitter info text-subtle">#{event.target_object.text}</p>
    <img class="twitter info profile-image" src="#{event.source.profile_image_url}" />
    """

  isPrepared: -> @publicStream?

  prepare: ->
    new Promise (resolve, reject) =>
      return resolve() if @isPrepared()

      @getAccount()
      .then (account) =>
        oauth = _.pick account, "consumer_key", "consumer_secret", "token", "token_secret"
        @currentUserId = account.user_id
        @rest = new TwitterRestClient oauth
        @publicStream = new PublicStream oauth
        @userStream = new UserStream oauth
        @userStream.on "favorite", @notifyFavorite

        @rest.getConfiguration()
      .then (@configuration) =>
        @rest.getMutedUserIds()
      .then (@mutedUserIds) =>
        resolve()
      .catch reject

  getAccount: ->
    new Promise (resolve, reject) =>
      database.open()
      .then (db) =>
        db.accounts.query().filter().execute()
        .then (accounts) =>
          if accounts.length is 0
            @log.debug "start authentication"
            child = window.open AUTH_URL
            window.addEventListener "message", (message) =>
              @log.debug "store account information (user_id: #{message.data.user_id})"

              child.close()

              data =
                user_id: parseInt message.data.user_id, 10
                screen_name: message.data.screen_name
                consumer_key: message.data.consumer_key
                consumer_secret: message.data.consumer_secret
                token: message.data.oauth_token
                token_secret: message.data.oauth_token_secret

              db.accounts.add(data).then (account) ->
                resolve account[0]
            , off
          else
            @log.debug "open with exist account (user_id: #{accounts[0].user_id})"
            resolve accounts[0]
