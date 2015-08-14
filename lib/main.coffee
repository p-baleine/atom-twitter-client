AtomTwitterOpenerView = require './atom-twitter-opener-view'

module.exports =
  config:
    timlineBufferSize:
      default: 100
      type: "integer"
      description: "How many tweets a timeline keeps."
      order: 1
    homeTimelineLasts:
      default: 10
      minimum: 0
      maximum: 50
      type: "integer"
      description: "How many last tweets to get when opening 'twitter home'."
      order: 2
    proxy:
      default: ""
      type: "string"
      description: "Proxy setting passed to `request` module."
      order: 3
    createInDevMode:
      default: false
      type: 'boolean'

  activate: (state) ->
    @openerView = new AtomTwitterOpenerView state

  deactivate: ->
    @openerView?.destroy()
