AtomTwitterOpenerView = require './atom-twitter-opener-view'

module.exports =
  config:
    createInDevMode:
      default: false
      type: 'boolean'
    proxy:
      default: ""
      type: "string"
      description: "Proxy setting passed to `request` module."
      order: 6

  activate: (state) ->
    @openerView = new AtomTwitterOpenerView state

  deactivate: ->
    @openerView?.destroy()
