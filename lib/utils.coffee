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
