AtomTwitterOpenerView = require './atom-twitter-opener-view'

module.exports =
  config:
    timlineBufferSize:
      default: 100
      type: "integer"
      description: "How many tweets a timeline keeps."
      order: 1
    proxy:
      default: ""
      type: "string"
      description: "Proxy setting passed to `request` module."
      order: 2
    createInDevMode:
      default: false
      type: 'boolean'

  activate: (state) ->
    @openerView = new AtomTwitterOpenerView state

  deactivate: ->
    @openerView?.destroy()
