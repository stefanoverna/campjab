util = require 'util'
http = require 'http'
express = require 'express'
io = require 'socket.io'
path = require 'path'

class Server
  constructor: ->
    @app = express()
    @configure()
    @routes()

  configure: ->
    @app.configure =>
      @app.use express.responseTime()
      @app.use require('connect-assets')()
      @app.use express.static(path.join __dirname, '../public')

      if env('production')
        @app.use express.logger()
      else
        @app.use express.logger('dev')

  routes: ->
    auth = if auth_user = config.get('server:basic_auth:user')
      express.basicAuth auth_user, config.get('server:basic_auth:password')
    else
      (req, res, next) -> next()

    @app.get '/', auth, (req, res) ->
      res.render "index.jade"

    @app.get '/events.json', auth, (req, res) ->
      db.model('RoomEvent').findByDate req.query['limit'] || 50, req.query['since'], (events) ->
        console.dir events
        res.writeHead 200, 'Content-Type': 'application/json'
        res.end JSON.stringify (event.toObject() for event in events)

  pushEvent: (event) ->
    @io.sockets.emit 'event', event.toObject()

  run: ->
    @server = http.createServer(@app)

    @server.listen config.get('server:port'), config.get('server:host'), =>
      util.log util.format "[%s] http://%s:%d/", env(), @server.address().address, @server.address().port

    @io = io.listen(@server)
    @io.configure =>
      @io.set "transports", ["xhr-polling"]
      @io.set "polling duration", 10

    this

module.exports = -> new Server()
