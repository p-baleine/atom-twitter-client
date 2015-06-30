_ = require "underscore"
{$, View, TextEditorView} = require 'atom-space-pen-views'
AtomTwitterTimelineView = require './atom-twitter-timeline-view'
{CompositeDisposable} = require 'atom'
database = require "./database"
Logger = require "./logger"
Promise = require "bluebird"
{PublicStream,UserStream} = require './twitter-stream'
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
      @subview 'miniEditor', new TextEditorView mini: true, placeholderText: "Search..."

  log: new Logger("AtomTwitterOpenerView")

  initialize: (state) ->
    bufferSize = atom.config.get "atom-twitter.timlineBufferSize"

    @modalPanel = atom.workspace.addModalPanel(item: @)

    atom.commands.add @element,
      'core:confirm': => @confirm()
      'core:cancel': => @close()

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-twitter:search': => @search()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-twitter:home': => @home()

    atom.workspace.addOpener (uriToOpen) =>
      {protocol, host, pathname, query} = url.parse uriToOpen, on
      return unless protocol is 'twitter:'

      switch host
        when "search"
          title = "#{query.q} - Twitter Search"
          view = new AtomTwitterTimelineView @publicStream, @rest, query.id, title, bufferSize
          @atomTwitterTimelineViewDict[query.q] = view
        when "home"
          title = "Twitter Home"
          view = new AtomTwitterTimelineView @userStream, @rest, query.id, title, bufferSize
          @atomTwitterTimelineViewDict["__user"] = view

  destroy: ->
    @publicStream?.destroy()
    @userStream?.destroy()
    @subscriptions.dispose()
    @modalPanel?.destroy()
    view.destroy() for view in @atomTwitterTimelineViewDict

  search: ->
    @prepare()
    .then =>
      @previouslyFocusedElement = $(document.activeElement)
      @modalPanel.show()
      @miniEditor.focus()

  home: ->
    return if "__user" in @atomTwitterTimelineViewDict

    @prepare()
    .then =>
      id = @userStream.connect()
      uri = "twitter://home?id=#{id}"
      atom.workspace.open uri, split: 'right', searchAllPanes: on
      @close()

  confirm: ->
    query = @miniEditor.getText().trim()
    return unless query.length > 0
    @miniEditor.setText("")
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

      database.open()
      .then (db) =>
        db.accounts.query().filter().execute()
        .then (accounts) =>
          if accounts.length is 0
            @log.info "start authentication"
            child = window.open AUTH_URL
            window.addEventListener "message", (message) =>
              @log.info "store account information (user_id: #{message.data.user_id})"

              child.close()

              data =
                user_id: parseInt message.data.user_id, 10
                screen_name: message.data.screen_name
                consumer_key: message.data.consumer_key
                consumer_secret: message.data.consumer_secret
                token: message.data.oauth_token
                token_secret: message.data.oauth_token_secret

              db.accounts.add data
              .then (account) =>
                @prepareAuth account[0]
                resolve()
            , off
          else
            @log.info "open with exist account (user_id: #{accounts[0].user_id})"
            @prepareAuth accounts[0]
            resolve()

  prepareAuth: (account) ->
    oauth = _.pick account, "consumer_key", "consumer_secret", "token", "token_secret"
    @currentUserId = account.user_id
    @rest = new TwitterRestClient oauth
    @publicStream = new PublicStream oauth
    @userStream = new UserStream oauth
    @userStream.on "favorite", @notifyFavorite
