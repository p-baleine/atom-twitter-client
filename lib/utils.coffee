HTTP_PATTERN = /http:\/\/[\w/:%#\$&\?\(\)~\.=\+\-]+/
HTTPS_PATTERN = /https:\/\/[\w/:%#\$&\?\(\)~\.=\+\-]+/

module.exports =
  tweetCount: (text, configuration) ->
    configuration ?= short_url_length: 22, short_url_length_https: 23
    {short_url_length, short_url_length_https} = configuration
    count = text
    .replace HTTP_PATTERN, ("x" for i in [1..short_url_length]).join("")
    .replace HTTPS_PATTERN, ("x" for i in [1..short_url_length_https]).join("")
    .length

    {
      remaining: 140 - count
      isOver: count > 140
    }

  notImplementedYet: ->
    atom.notifications.addInfo """
    This feature is not implemented yet.

    PR is welcome and if you can't wait for implementation of this feature,
    please send your pull request!

    https://github.com/p-baleine/atom-twitter
    """
