require './lib/config'
require './models'

mongoose = require 'mongoose'

xmppClient = require './lib/xmpp-room-client'
server = require './lib/server'

global.db = mongoose.createConnection(
  config.get('mongodb:host'),
  config.get('mongodb:db'),
  config.get('mongodb:port')
)

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
        roomEvent.save()
        server.pushEvent(roomEvent)
