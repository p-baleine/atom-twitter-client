fs = require "fs"
request = require 'request'
{Emitter} = require 'atom'
url = require "url"

TwitterStreamClient = require "../lib/twitter-stream-client"

describe "TwitterStreamClient", ->
  it "should be a function", ->
    expect(typeof TwitterStreamClient).toBe "function"

  describe "connect", ->
    fakeRequest =
      on: -> @
      abort: ->
      destroy: ->

    beforeEach ->
      spyOn(request, "post").andCallFake -> fakeRequest

    it "should request to specified endpoint", ->
      stream = new TwitterStreamClient("http://google.com").connect()
      params = request.post.calls[0].args[0]
      expect(params.url).toMatch /http:\/\/google\.com/
      stream.destroy()

    it "should request with specified oauth params", ->
      stream = new TwitterStreamClient("http://google.com", consumer_key: "abc").connect()
      params = request.post.calls[0].args[0]
      expect(params.oauth.consumer_key).toBe "abc"
      stream.destroy()

    it "should request with specified proxy settin", ->
      stream = new TwitterStreamClient("http://google.com", {}, proxy: "http://proxy:8080").connect()
      params = request.post.calls[0].args[0]
      expect(params.proxy).toBe "http://proxy:8080"
      stream.destroy()

    it "should request with `delimited=length`", ->
      stream = new TwitterStreamClient("http://google.com", {}, proxy: "http://proxy:8080").connect()
      params = request.post.calls[0].args[0]
      expect(url.parse(params.url, true).query.delimited).toBe "length"
      stream.destroy()

  describe "on `data` event", ->
    fakeRequest =
      on: -> @
      abort: ->
      destroy: ->

    beforeEach ->
      spyOn(request, "post").andCallFake -> fakeRequest
      spyOn(fakeRequest, "on").andCallFake -> fakeRequest

    describe "when blank lines are delivered", ->
      it "should return immediately", ->
        onTweet = jasmine.createSpy "tweet"
        stream = new TwitterStreamClient "http://google.com"
        stream.on "tweet", onTweet
        stream.connect()

        cb = fakeRequest.on.calls.filter((call) -> call.args[0] is "data")[0].args[1]

        cb("")

        expect(onTweet).not.toHaveBeenCalled()

        stream.destroy()

    describe "when tweet message is delivered", ->
      prepareFixtures = ->
        fixtureFiles = fs.readdirSync "#{__dirname}/fixtures"
        chunks = fixtureFiles.map (file) -> fs.readFileSync "#{__dirname}/fixtures/#{file}", encoding: "utf8"
        messages = chunks.join("")
        .replace(/^\d+$/gm, "")
        .split(/\r\n/)
        .filter((line) -> line.length isnt 0)
        .map((jsonStr) -> JSON.parse jsonStr)
        { chunks: chunks, messages: messages }

      describe "when all data is arrived", ->
        it "should emit `tweet`", ->
          {chunks, messages} = prepareFixtures()
          notifiedTweets = messages.filter((m) -> m.text)
          notifiedDeletes = messages.filter((m) -> m.delete)
          notifiedFriends = messages.filter((m) -> m.friends)

          onTweet = jasmine.createSpy "tweet"
          onDelete = jasmine.createSpy "delete"
          onFriend = jasmine.createSpy "friends"
          stream = new TwitterStreamClient "http://google.com"
          stream.on "tweet", onTweet
          stream.on "friends", onFriend
          stream.on "delete", onDelete
          stream.connect()

          cb = fakeRequest.on.calls.filter((call) -> call.args[0] is "data")[0].args[1]

          chunks.forEach (chunk) -> cb(chunk)

          expect(onTweet.calls.length).toBe notifiedTweets.length
          expect(onDelete.calls.length).toBe notifiedDeletes.length
          expect(onFriend.calls.length).toBe notifiedFriends.length
          expect(onTweet.calls.map((call) -> call.args[0].text))
          .toEqual notifiedTweets.map((m) -> m.text)

          stream.destroy()

    describe "disconnect message", ->
      it "should emit the message name", ->
        stream = new TwitterStreamClient "http://google.com"
        onError = jasmine.createSpy "error"
        stream.on "error", onError
        stream.connect()

        cb = fakeRequest.on.calls.filter((call) -> call.args[0] is "data")[0].args[1]

        chunk = JSON.stringify
          disconnect:
            code: 4
        chunk = "#{chunk.length}\r\n#{chunk}"

        cb(chunk)

        expect(onError).toHaveBeenCalled()

        stream.destroy()

  describe "reconnecting", ->
    class FakeRequest extends Emitter
      on: ->
        super
        @
      abort: ->
        @emit "end"
      destroy: ->

    beforeEach ->
      jasmine.useRealClock()

    describe "when 90 second passsed from last `data` event", ->
      it "should abort request", ->
        fakeRequest = new FakeRequest
        spyOn(request, "post").andCallFake -> fakeRequest
        spyOn(fakeRequest, "abort")
        stream = new TwitterStreamClient "http://google.com", {},
          reconnecting_interval: 150
          reconnecting_timeout: 900

        stream.connect()

        waitsFor (done) ->
          setTimeout done, 910
        , 1000

        runs ->
          expect(fakeRequest.abort).toHaveBeenCalled()
          stream.destroy()

      it "should reconnect immediately", ->
        fakeRequest = new FakeRequest
        spyOn(request, "post").andCallFake -> fakeRequest
        stream = new TwitterStreamClient "http://google.com", {},
          reconnecting_interval: 150
          reconnecting_timeout: 900

        stream.connect()

        waitsFor (done) ->
          setTimeout done, 910
        , 1000

        runs ->
          expect(request.post.callCount).toBe 2
          stream.destroy()
