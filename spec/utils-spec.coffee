utils = require "../lib/utils"

describe "utils", ->
  configuration =
    short_url_length: 22
    short_url_length_https: 23

  describe "tweetCount", ->
    it "should return text size on count field", ->
      {remaining} = utils.tweetCount "12345", configuration
      expect(remaining).toBe 135

    describe "when text size is over 140", ->
      it "should return true on isOver field", ->
        {isOver} = utils.tweetCount ((i % 10) + "" for i in [1..141]).join(""), configuration
        expect(isOver).toBe(true)

    describe "when text size is under 140", ->
      it "should return true on isOver field", ->
        {isOver} = utils.tweetCount ((i % 10) + "" for i in [1..140]).join(""), configuration
        expect(isOver).not.toBe(true)

    it "should return remaining and isOver", ->
      [
        {
          params:
            text: "abcdef http://google.com"
            configuration: configuration
          expected:
            remaining: 111
            isOver: false
        }
        {
          params:
            text: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaLearn Portuguese faster by using flashcards with pictures. #LearnPortuguese #PortugueseFlashcards "
            configuration: configuration
          expected:
            remaining: -1
            isOver: true
        }
      ].forEach (item) ->
        {text, configuration} = item.params
        {remaining, isOver} = utils.tweetCount text, configuration
        expect(remaining).toBe item.expected.remaining
        expect(isOver).toBe item.expected.isOver
