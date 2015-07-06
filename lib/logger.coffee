format = require("util").format
moment = require("moment-twitter")

development = atom.config.get "atom-twitter-client.createInDevMode"

module.exports =
class Logger
  constructor: (@tag) ->

  error: ->  @print "error", arguments...
  warn: -> @print "warn", arguments...
  info: -> @print "info", arguments...
  log: -> @print "log", arguments...
  debug: -> @print "debug", arguments...

  print: (level, args...) ->
    return if @[level.toUpperCase()] < @level
    header = format "[%s] %s:", moment().format(), @tag
    console[level].apply console, [header].concat args

Logger::ERROR = 4
Logger::WARN = 3
Logger::INFO = 2
Logger::LOG = 1
Logger::DEBUG = 0

Logger::level = if development then Logger::DEBUG else Logger::INFO
