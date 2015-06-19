moment = require 'moment-twitter'
{View} = require 'atom-space-pen-views'

module.exports =
class AtomTwitterTimelineItemView extends View
  @content: (tweet) ->
    @li class: 'tweet tick', =>
      @div class: 'content', =>
        @div class: 'header', =>
          if tweet.retweeted_by?
            @div class: "retweeted_by", =>
              @i class: "fa fa-retweet"
              @a
                class: "text-subtle"
                href: "https://twitter.com/#{tweet.retweeted_by.screen_name}"
                "#{tweet.retweeted_by.name} retweeted"
          @a class: 'user', 'href': "https://twitter.com/#{tweet.user.screen_name}", =>
            @img class: 'image', src: tweet.user.profile_image_url
            @span
              class: 'name text-highlight'
              tweet.user.name
            @span class: 'screen-name text-subtle', =>
              @s "@"
              @b tweet.user.screen_name
          @span
            class: 'time text-subtle'
            outlet: "time"
            AtomTwitterTimelineItemView.formatCreatedAt(tweet.created_at)
        @p
          class: 'body', =>
            @raw tweet.text
        if tweet.entities.media?.length > 0
          @a class: "media", href: tweet.entities.media[0].expanded_url, =>
            @div
              class: "mdia-container"
              style: "background-image: url(#{tweet.entities.media[0].media_url_https})"
        @ul class: "actions", outlet: "actions", =>
          @li class: "action reply", click: "reply", =>
            @i class: "fa fa-reply"
          @li class: "action retweet", click: "retweet", =>
            @i class: "fa fa-retweet"
            @span
              class: "count"
              if tweet.retweet_count > 0 then tweet.retweet_count else ""
          @li class: "action favorite#{if tweet.favorited then " on" else ""}", click: "favorite", =>
            @i class: "fa fa-star"
            @span
              class: "count"
              if tweet.favorite_count > 0 then tweet.favorite_count else ""
          @li class: "action follow", click: "follow", =>
            @i class: "fa fa-user-plus"

  @formatCreatedAt: (createdAt) ->
    moment(new Date(createdAt)).twitterLong()

  @applyEntities: (text, entities) ->
    idx = 0
    result = ""

    # sortしてから？
    for name, entity of entities
      switch name
        when "urls"
          for {expanded_url, display_url, indices: [start, end]} in entity
            result += text[idx...start] + "<a href=\"#{expanded_url}\">#{display_url}</a>"
            idx = end

    result + text[idx..]

  constructor: (@tweet, @rest) ->
    @tweet.text = AtomTwitterTimelineItemView.applyEntities @tweet.text, @tweet.entities
    super @tweet
    @on "refresh-time", =>
      @time.text AtomTwitterTimelineItemView.formatCreatedAt @tweet.created_at

  attached: ->
    setTimeout(=> @removeClass 'tick', 0)

  reply: -> @notImplementedYet()
  retweet: -> @notImplementedYet()

  favorite: ->
    if @tweet.favorited
      @rest.destroyFavorite @tweet.id_str
      .then (@tweet) =>
        favorite = @actions.find(".favorite")
        favorite.removeClass("on")
        favorite.find(".count").text if tweet.favorite_count > 0 then tweet.favorite_count else ""
      .catch (err) => throw err
    else
      @rest.createFavorite @tweet.id_str
      .then (@tweet) =>
        favorite = @actions.find(".favorite")
        favorite.addClass("on")
        favorite.find(".count").text tweet.favorite_count
      .catch (err) => throw err

  follow: -> @notImplementedYet()

  notImplementedYet: ->
    atom.notifications.addInfo """
    This feature is not implemented yet.

    PR is welcome and if you can't wait for implementation of this feature,
    please send your pull request!

    https://github.com/p-baleine/atom-twitter
    """
