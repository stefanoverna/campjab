$ ->
  class RoomEventModel
    constructor: (attrs) ->
      console.log attrs
      @type = ko.observable(attrs.type)
      @body = ko.observable(attrs.body)
      @from = ko.observable(attrs.from)
      @room = ko.observable(attrs.room)
      @at = ko.observable(attrs.at)
      @id = ko.observable(attrs._id)
      @time = ko.computed(
        ->
          date = new Date(@at())
          "#{date.getHours()}:#{date.getMinutes()}"
        this)
      @timeAgo = ko.computed(
        -> $.timeago(@at()) if @at()?,
        this)

      if @type() == "available"
        @body "connected"
      if @type() == "unavailable"
        @body "disconnected"

  class RoomViewModel
    events: ko.observableArray([])

    loadEarlier: ->
      @retrieveHistory(@events()[0].id())

    constructor: ->
      socket = io.connect '/'
      socket.on 'event', (event) =>
        @events.push new RoomEventModel(event)

      @retrieveHistory()

    retrieveHistory: (since = null) ->
      url = "/events.json"
      url += "?since=#{since}" if since?

      $.getJSON url, (events) =>
        for event in events.reverse()
          @events.unshift new RoomEventModel(event)


  ko.applyBindings new RoomViewModel
