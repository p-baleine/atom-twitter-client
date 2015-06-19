class AuthorizationRequired extends Error
  constructor: ->
    @message = """
    Authorization Required.

    Please set your twitter application consumer key,
    consumer secret, access token and access token secret in
    setting.
    """

exports.AuthorizationRequired = AuthorizationRequired
