request = require 'request'
uuid = require "uuid"

{PublicStream, UserStream} = require '../lib/twitter-stream'

describe "PublicStream", ->
  it "should be a function", ->
    expect(typeof PublicStream).toBe "function"

  describe "connect", ->
    fakeRequest =
      on: -> @
      destroy: -> @
      abort: -> @

    beforeEach ->
      spyOn(request, "post").andCallFake -> fakeRequest
      spyOn(fakeRequest, "destroy").andCallFake -> fakeRequest
      spyOn(uuid, "v4").andCallFake -> "abcdef"

    it "should be a function", ->
      expect(typeof new PublicStream().connect).toBe "function"

    it "should return an uuid", ->
      stream = new PublicStream()
      expect(new PublicStream().connect()).toBe "tweet-public-abcdef"
      stream.destroy()

    it "should request with POST method", ->
      stream = new PublicStream()
      stream.connect()
      expect(request.post).toHaveBeenCalled()
      stream.destroy()

    it "should request to /statuses/filter endpoint", ->
      stream = new PublicStream()
      stream.connect()
      params = request.post.calls[0].args[0]
      expect(params.url).toMatch /https:\/\/stream\.twitter\.com\/1.1\/statuses\/filter.json/
      stream.destroy()

    it "should request with oauth parameters", ->
      stream = new PublicStream("oauth")
      stream.connect()
      params = request.post.calls[0].args[0]
      expect(params.oauth).not.toBe undefined
      stream.destroy()

    it "should request with a specified query", ->
      stream = new PublicStream()
      stream.connect("abcde")
      params = request.post.calls[0].args[0]
      expect(params.form?.track).toBe "abcde"
      stream.destroy()

    describe "when instanciate with proxy", ->
      it "should request with proxy", ->
        stream = new PublicStream("auth", proxy: "hoge")
        stream.connect()
        params = request.post.calls[0].args[0]
        expect(params.proxy).toBe "hoge"
        stream.destroy()

    describe 'multiple queries', ->
      describe 'when two queries are specified', ->
        it 'should destroy old connection', ->
          stream = new PublicStream()
          stream.connect("abc")
          stream.connect("def")
          expect(fakeRequest.destroy).toHaveBeenCalled()
          stream.destroy()

        it 'should request with specified queries', ->
          stream = new PublicStream()
          stream.connect("abc")
          stream.connect("def")
          expect(request.post.calls.length).toEqual 2
          tracks = request.post.calls[1].args[0].form.track.split ','
          expect("abc" in tracks).toBe true
          expect("def" in tracks).toBe true
          stream.destroy()

  describe "on `data` event", ->
    fakeRequest =
      on: -> @
      destroy: -> @
      abort: -> @

    beforeEach ->
      spyOn(request, "post").andCallFake -> fakeRequest
      spyOn(fakeRequest, "on").andCallFake -> fakeRequest

    describe "when valid json string is emitted", ->
      beforeEach ->
        spyOn(uuid, "v4").andCallFake -> "abcdef"

      it "should emit `tweet-public-<uuid>` with parsed tweet", ->
        called = false

        runs ->
          stream = new PublicStream()
          stream.on "tweet-public-abcdef", (tweet) ->
            expect(typeof tweet).toBe "object"
            expect(tweet.text).toBe "aaa"
            called = true
            stream.destroy()

          stream.connect "aaa"

          callback = fakeRequest.on.calls.filter((call) -> call.args[0] is "data")[0].args[1]
          callback("17\r\n{ \"text\": \"aaa\" }")

        waitsFor -> called

    describe 'multiple queries', ->
      it 'should emit `tweet` events to intereseted listeners', ->
        onTweet1 = jasmine.createSpy "tweet1"
        onTweet2 = jasmine.createSpy "tweet2"
        stream = new PublicStream

        e1 = stream.connect "abc"
        stream.on e1, onTweet1
        cb1 = fakeRequest.on.calls.filter((call) -> call.args[0] is "data")[0].args[1]

        cb1("17\r\n{ \"text\": \"abc\" }")
        cb1("17\r\n{ \"text\": \"def\" }")

        e2 = stream.connect "def"
        stream.on e2, onTweet2
        cb2 = fakeRequest.on.calls.filter((call) -> call.args[0] is "data")[1].args[1]

        cb2("17\r\n{ \"text\": \"abc\" }")
        cb2("17\r\n{ \"text\": \"def\" }")

        expect(onTweet1.calls.length).toBe 2
        expect(onTweet2.calls.length).toBe 1

        stream.destroy()
