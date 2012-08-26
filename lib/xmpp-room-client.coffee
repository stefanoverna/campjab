util = require 'util'
http = require 'http'
junction = require 'junction'
junctionPing = require 'junction-ping'
junctionDelay = require 'junction-delay'
EventEmitter = require('events').EventEmitter


class XmppRoomClient extends EventEmitter
  constructor: (@host, @user, @password, @room, @nick) ->
    @client = junction()
    @configureClient()

  configureClient: ->
    @client.use junctionPing()
    @client.use junctionDelay()

    @client.use junction.presenceParser()
    @client.use junction.presence (handler) =>
      for event in ['available', 'unavailable', 'err']
        do (event) => handler.on event, (stanza) => @onPresence(event, stanza)

    @client.use junction.messageParser()
    @client.use junction.message (handler) =>
      for event in ['chat', 'groupchat', 'headline', 'normal', 'err']
        do (event) => handler.on event, (stanza) => @onMessage(event, stanza)

    if env('production')
      @client.use junction.errorHandler()
    else
      # @client.use junction.dump()
      @client.use junction.errorHandler({ showStack: true, dumpExceptions: true })

    @client.use junction.serviceUnavailable()

  connectionOptions: ->
    type: 'client'
    jid: @user
    password: @password
    host: @host

  run: ->
    console.dir @connectionOptions()
    @connection = @client.connect(@connectionOptions())
    @connection.on 'online', => @joinRoom()
    @connection.on 'error', (msg) => console.log msg
    this

  onPresence: (type, stanza) ->
    from = stanza.from.split("/")[1]

    if !stanza.originallySentAt and (type == 'available' or type == 'unavailable')
      @emit type, { room: @room, type: type, at: new Date, from: from }

  onMessage: (type, stanza) ->
    from = stanza.from.split("/")[1]

    if stanza.body and !stanza.originallySentAt
      @emit 'message', { room: @room, type: type, at: new Date, from: from, body: stanza.body }

  joinRoom: ->
    @connection.send new junction.elements.Presence("#{@room}/#{@nick}")

module.exports = (host, user, password, room, nick) ->
  new XmppRoomClient(host, user, password, room, nick)
