{$, View, TextEditorView} = require 'atom-space-pen-views'
utils  = require "./utils"

module.exports =
class AtomTwitterTweetEditorView extends View
  @content: ->
    editorView = new TextEditorView
      placeholderText: "What's happening?"
      attributes: "gutter-hidden": true
    editorView.element.component.editor.toggleSoftWrapped()

    @div class: "twitter post", =>
      @div class: "content block", =>
        @subview "tweet", editorView
      @div class: "action block", =>
        @button
          class: "inline-block btn btn-lg icon icon-pencil pull-right"
          click: "updateStatus"
          outlet: "post"
          "Tweet"
        @p class: "counter inline-block pull-right", outlet: "counter", "0"

  initialize: ->
    @model = @tweet.getModel()
    @model.onDidStopChanging => @updateCount()

  setUp: (@parent, @configuration, @rest, @optionalTweet) ->
    @model.getBuffer().setText "@#{@optionalTweet.user.screen_name} " if @optionalTweet


  updateCount: ->
    text = @model.getBuffer().getText()
    {remaining, isOver} = utils.tweetCount text, @configuration
    @counter.text(remaining).toggleClass "over", isOver
    @post.prop "disabled", isOver

  updateStatus: ->
    text = @model.getBuffer().getText()
    {isOver} = utils.tweetCount text, @configuration
    return if isOver
    @parent.close()
    @model.getBuffer().setText ""
    @rest.updateStatus text, in_reply_to_status_id: @optionalTweet?.user.id
    .done utils.noop, (err) -> throw err

  focus: -> @tweet.focus()
