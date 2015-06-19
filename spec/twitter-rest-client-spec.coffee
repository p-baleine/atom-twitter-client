request = require 'request'
Promise = require "bluebird"

TwitterRestClient = require '../lib/twitter-rest-client'

describe "TwitterRestClient", ->
  fakeRequest =
    on: -> @

  describe "createFavorite", ->
    beforeEach ->
      spyOn(request, "post").andCallFake -> fakeRequest

    it "should return a promise", ->
      expect(new TwitterRestClient().createFavorite() instanceof Promise).toBe true

    it "should request to /favorite", ->
      new TwitterRestClient().createFavorite("123")
      expect(request.post).toHaveBeenCalled()
      params = request.post.calls[0].args[0]
      expect(params.url).toMatch /https:\/\/api\.twitter\.com\/1\.1\/favorites\/create\.json/

    it "should request to /favorite with specified id", ->
      new TwitterRestClient().createFavorite("123")
      expect(request.post).toHaveBeenCalled()
      params = request.post.calls[0].args[0]
      expect(params.url).toMatch /id=123/
