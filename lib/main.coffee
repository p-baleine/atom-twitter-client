AtomTwitterOpenerView = require './atom-twitter-opener-view'

module.exports =
  config:
    createInDevMode:
      default: false
      type: 'boolean'
    consumerKey:
      default: ""
      type: "string"
      description: "Twitter Applications\' consumer key."
      order: 1
    consumerSecret:
      default: ""
      type: "string"
      description: "Twitter Applications\' consumer secret."
      order: 2
    accessToken:
      default: ""
      type: "string"
      description: "Twitter Applications\' access token."
      order: 3
    accessTokenSecret:
      default: ""
      type: "string"
      description: "Twitter Applications\' access token secret."
      order: 4
    timlineBufferSize:
      default: 500
      type: "integer"
      description: "How many tweets a timeline keeps."
      order: 5
    proxy:
      default: ""
      type: "string"
      description: "Proxy setting passed to `request` module."
      order: 6

  activate: ->
    @view = new AtomTwitterOpenerView()

  deactivate: ->
    @view?.destroy()
