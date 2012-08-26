$ ->
  class RoomEventModel
    urlRegexp: /((http[s]?|ftp):\/)?\/?([^:\/\s]+)((\/\w+)*\/)([\w\-\.]+[^#?\s]+)(.*)?(#[\w\-]+)?/
    constructor: (attrs) ->
      @type = ko.observable(attrs.type)
      @body = ko.observable(attrs.body)
      @from = ko.observable(attrs.from)
      @room = ko.observable(attrs.room)
      @at = ko.observable(attrs.at)
      @meta = ko.observable(attrs.meta)
      @id = ko.observable(attrs._id)
      @time = ko.computed(
        -> moment(new Date(@at())).format("HH:mm")
        this)

      if @type() == "available"
        @body "connected"
      if @type() == "unavailable"
        @body "disconnected"

      @inlineImages()

    inlineImages: ->
      body = @body()
      for meta in @meta() || []
        link = meta.link
        meta = meta.meta
        if meta.image
          body = body.replace(link, "<img src='#{link}'/>")
        else if meta.oembed
          body = body.replace(link, "<div class='oembed'>#{meta.oembed.html}</div>" || "<img src='#{meta.oembed.thumbnail_url}'/>")
        else
          body = body.replace(link, "<a href='#{link}' target='_blank'>#{link}</a>")

      @body body

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
