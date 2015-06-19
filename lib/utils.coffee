module.exports =
  getCurrentUserId: ->
    parseInt atom.config.get("atom-twitter.accessToken").split('-')[0], 10
