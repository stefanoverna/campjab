require './lib/config'
require './models'
Mongoose = require 'mongoose'
HttpClient = require 'scoped-http-client'

xmppClient = require './lib/xmpp-room-client'
server = require './lib/server'

global.db = Mongoose.createConnection config.get('mongodb:uri')

db.on 'error', console.error.bind(console, 'connection error:')
db.once 'open', ->
  server = server().run()
  RoomEvent = db.model('RoomEvent')

  room = xmppClient(
    config.get('xmpp:host'),
    config.get('xmpp:user'),
    config.get('xmpp:password'),
    config.get('xmpp:room'),
    config.get('xmpp:nick')
  ).run()

  for event in ['message', 'available', 'unavailable']
    do (event) ->
      room.on event, (eventDetails) ->
        console.dir eventDetails
        roomEvent = new RoomEvent(eventDetails)
        roomEvent.save ->
          server.pushEvent(roomEvent)

  if url = config.get('server:url')
    url += '/' unless /\/$/.test url
    setInterval =>
      HttpClient.create("#{url}ping").post() (err, res, body) =>
        console.log 'ping!'
    , 1200000
