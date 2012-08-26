nconf = require('nconf')

nconf.file(file: 'config/config.json')
nconf.defaults
  server:
    host: '0.0.0.0'
    port: 8000
  mongodb:
    host: '0.0.0.0'
    port: 27017
  env: process.env.NODE_ENV or 'development'

global.env = (env) ->
  if (env)
    env == nconf.get('env')
  else
    nconf.get('env')

process.env.NODE_ENV = env()
global.config = nconf
