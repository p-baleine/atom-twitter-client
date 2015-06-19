fs = require "fs"
request = require 'request'
url = require "url"

TwitterStreamClient = require "../lib/twitter-stream-client"

describe "TwitterStreamClient", ->
  it "should be a function", ->
    expect(typeof TwitterStreamClient).toBe "function"

  describe "connect", ->
    fakeRequest =
      on: -> @

    beforeEach ->
      spyOn(request, "post").andCallFake -> fakeRequest

    it "should request to specified endpoint", ->
      new TwitterStreamClient("http://google.com").connect()
      params = request.post.calls[0].args[0]
      expect(params.url).toMatch /http:\/\/google\.com/

    it "should request with specified oauth params", ->
      new TwitterStreamClient("http://google.com", consumer_key: "abc").connect()
      params = request.post.calls[0].args[0]
      expect(params.oauth.consumer_key).toBe "abc"

    it "should request with specified proxy settin", ->
      new TwitterStreamClient("http://google.com", {}, proxy: "http://proxy:8080").connect()
      params = request.post.calls[0].args[0]
      expect(params.proxy).toBe "http://proxy:8080"

    it "should request with `delimited=length`", ->
      new TwitterStreamClient("http://google.com", {}, proxy: "http://proxy:8080").connect()
      params = request.post.calls[0].args[0]
      expect(url.parse(params.url, true).query.delimited).toBe "length"

  describe "on `data` event", ->
    fakeRequest =
      on: -> @

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
