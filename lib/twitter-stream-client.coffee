_ = require "underscore"
request = require 'request'
url = require "url"
{Emitter} = require 'atom'
Logger = require "./logger"

module.exports =
class TwitterStreamClient extends Emitter
  @DISCONNECT_MESSAGE:
    1: "Shutdown"
    2: "Duplicate stream"
    3: "Control request"
    4: "Stall"
    5: "Normal"
    6: "Token revoked"
    7: "Admin logout"
    9: "Max message limit"
    10: "Stream exception"
    11: "Broker stall"
    12: "Shed load"

  @STATE:
    READING_LENGTH: 0
    READING_DATA: 1
    ABORT: 2

  log: new Logger("TwitterStreamClient")

  constructor: (@endpoint, @oauth, @options = {}) ->
    super

    @request = null
    @length = 0
    @buffer = ''
    @state = TwitterStreamClient.STATE.READING_LENGTH
    @lastError = null
    @params = {}
    @lastDataArrivedTime = 0
    @reconnectingCount = 0
    @timer = null
    @retryTimer = null

    @reconnectingInterval = @options.reconnecting_interval or 15000
    @reconnectingTimeout = @options.reconnecting_timeout or 90000
    @maxReconnectingCount = @options.max_reconnecting_count or 7

    # ensure delimited=length option
    parsed = url.parse(@endpoint, true)
    unless parsed.query.delimited
      parsed.query.delimited = "length"
      @endpoint = url.format parsed

  connect: (params) ->
    @params = params or @params
    obj = _.extend { url: @endpoint, oauth: @oauth }, @params, @options

    @log.debug "request to #{obj.url}"

    @setReconnectingTimer()

    @request = request
    .post obj
    .on "error", (err) => @emit "error", err
    .on "response", (response) => @emit "response", response
    .on "end", @tryReconnect
    .on "data", (data) =>
      @lastDataArrivedTime = Date.now()
      data = data.toString("utf8")
      idx = 0

      while idx < data.length
        switch @state
          when TwitterStreamClient.STATE.READING_LENGTH
            idx = @readLine idx, data
            unless @isBlankLine()
              @length = parseInt @buffer, 10
              if isNaN @length
                @lastError = "length is not a number #{data}"
                @state = TwitterStreamClient.STATE.ABORT
              else
                @clearBuffer()
                @state = TwitterStreamClient.STATE.READING_DATA
            else
              @log.debug "blank line..."
          when TwitterStreamClient.STATE.READING_DATA
            idx = @readLength idx, data
            if @isDataEnd()
              message = null
              try
                message = JSON.parse @buffer
                @emitMessage message
                @state = TwitterStreamClient.STATE.READING_LENGTH
              catch error
                @lastError = error
                @state = TwitterStreamClient.STATE.ABORT
              finally
                @length = 0
                @clearBuffer()
          when TwitterStreamClient.STATE.ABORT
            @emit "error", @lastError
          else
            throw new Error "unknown state"

      @emit "error", @lastError if @state is TwitterStreamClient.STATE.ABORT
    @

  setReconnectingTimer: ->
    clearInterval @timer if @timer?
    @timer = setInterval =>
      return unless Date.now() - @lastDataArrivedTime >= @reconnectingTimeout
      @log.debug "no data was received in #{@reconnectingTimeout}ms, disconnection"
      clearInterval @timer
      @request.abort()
    , @reconnectingInterval

  tryReconnect: =>
    return @emit "error", "streaming api is not available" if @reconnectingCount > @maxReconnectingCount

    timeout = if @reconnectingCount is 0 then 0 else Math.pow(2, @reconnectingCount - 1) * 5 * 1000

    @log.debug "try reconnecting after #{timeout}ms"

    @retryTimer = setTimeout =>
      @connect()
    , timeout

    @reconnectingCount += 1

  readLine: (idx, data) ->
    end = data.indexOf "\r\n", idx
    @buffer = data[idx..end]
    end + 2

  readLength: (idx, data) ->
    end = @length - @buffer.length
    @buffer += data[idx...(idx + end)]
    idx + end

  isDataEnd: ->
    @buffer.length is @length

  isBlankLine: () ->
    @buffer.replace(/[\n\r]/g, "").length is 0

  clearBuffer: ->
    @buffer = ""

  emitMessage: (message) ->
    # TODO more robust message parser
    # https://github.com/yusuke/twitter4j/blob/master/twitter4j-core/src/main/java/twitter4j/JSONObjectType.java#L69
    if message.text
      @emit "tweet", message
    else if message.delete
      @emit "delete", message
    else if message.limit
      @emit "limit", message
    else if message.friends
      @emit "friends", message
    else if message.event
      switch message.event
        when "favorite" then @emit "favorite", message
        else @emit "unknown event", message
    else if message.disconnect
      throw @DISCONNECT_MESSAGE[message.disconnect.code]
    else
      @emit "unknown", message

  emit: ->
    super arguments...
    @log.debug arguments...

  destroy: ->
    @request.destroy() if @request?
    @dispose()
    clearInterval @timer
    clearTimeout @retryTimer
