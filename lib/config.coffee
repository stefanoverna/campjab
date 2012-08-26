nconf = require('nconf')

nconf.defaults
  server:
    host: '0.0.0.0'
    port: process.env.PORT or 8000
    basic_auth:
      user: process.env.BASIC_AUTH_USER
      password: process.env.BASIC_AUTH_PASS
  mongodb:
    uri: process.env.MONGOLAB_URI
  env: process.env.NODE_ENV or 'development'
  oembed:
    embedly_key: process.env.OEMBEDLY_KEY
  xmpp:
    user: process.env.XMPP_USER
    password: process.env.XMPP_PASS
    host: process.env.XMPP_HOST
    room: process.env.XMPP_ROOM
    nick: process.env.XMPP_NICK

global.env = (env) ->
  if (env)
    env == nconf.get('env')
  else
    nconf.get('env')

process.env.NODE_ENV = env()
global.config = nconf
