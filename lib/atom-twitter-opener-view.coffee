{$, View, TextEditorView} = require 'atom-space-pen-views'
AtomTwitterTimelineView = require './atom-twitter-timeline-view'
{AuthorizationRequired} = require "./exceptions"
{CompositeDisposable} = require 'atom'
{PublicStream,UserStream} = require './twitter-stream'
TwitterRestClient = require "./twitter-rest-client"
url = require 'url'
utils = require "./utils"

module.exports =
class AtomTwitterOpenerView extends View
  atomTwitterTimelineViewDict: {}
  modalPanel: null
  subscriptions: null

  @content: ->
    @div class: 'twitter-opener', =>
      @subview 'miniEditor', new TextEditorView mini: true, placeholderText: "Search..."

  initialize: (state) ->
    {oauth} = @getConfigs()
    @currentUserId = utils.getCurrentUserId()
    @publicStream = new PublicStream oauth
    @userStream = new UserStream oauth
    @rest = new TwitterRestClient oauth
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

    @userStream.on "favorite", @notifyFavorite

  destroy: ->
    @publicStream.destroy()
    @userStream.destroy()
    @subscriptions.dispose()
    @modalPanel?.destroy()
    view.destroy() for view in @atomTwitterTimelineViewDict

  search: ->
    @previouslyFocusedElement = $(document.activeElement)
    @modalPanel.show()
    @miniEditor.focus()

  home: ->
    return if "__user" in @atomTwitterTimelineViewDict
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

AtomTwitterOpenerView::getConfigs = ->
  oauth:
    consumer_key: atom.config.get "atom-twitter.consumerKey"
    consumer_secret: atom.config.get "atom-twitter.consumerSecret"
    token: atom.config.get "atom-twitter.accessToken"
    token_secret: atom.config.get "atom-twitter.accessTokenSecret"
