AtomTwitterTimelineItemView = require "../lib/atom-twitter-timeline-item-view"

describe "AtomTwitterTimelineItemView", ->
  describe "applyAnchorTag", ->
    tweet =
      text: "お茶かなぁ ( #ラブライブ！応援キャス【μ'ses】 ラブライブ系雑談 http://t.co/OGPY28bZwC )"
      entities:
        urls: [
          url: "http://t.co/OGPY28bZwC"
          expanded_url: "http://cas.st/ab556ec"
          display_url:"cas.st/ab556ec"
          indices: [37, 59]
        ]

    it "should apply anchor tags", ->
      applied = AtomTwitterTimelineItemView.applyEntities(tweet.text, tweet.entities)
      expect(applied).toMatch /<a href="http:\/\/cas\.st\/ab556ec">cas\.st\/ab556ec<\/a>/
