Mongoose = require 'mongoose'
linkMeta = require '../lib/link-meta'
Async = require 'async'

schema = new Mongoose.Schema
  room: String,
  type: String,
  from: String,
  body: String,
  meta: Mongoose.Schema.Types.Mixed,
  at: Date

schema.statics.isDuplicateEvent = (attrs, cb) ->
  if attrs.type == 'available' or attrs.type = 'unavailable'
    @find().where('from').equals(attrs.from).sort("-at").limit(1).exec (err, results) ->
      if err or results.length == 0
        cb(no)
      else
        result = results[0]
        cb(result.get('type') == attrs.type)
  else
    cb(no)

schema.statics.findByDate = (limit = 50, since = null, cb) ->
  if since
    @findById since, (err, event) =>
      @find().where('at').lt(event.get('at')).sort("-at").limit(limit).exec (err, results) ->
        cb results.reverse()
  else
      @find().sort("-at").limit(limit).exec (err, results) ->
        cb results.reverse()

schema.pre 'save', true, (next, done) ->
  next()

  event = this
  body = event.get('body')
  jobs = []

  for match in linkMeta.findLinks(body)
    console.log "Rilevato #{match}"
    do (match) ->
      jobs.push (done) -> linkMeta.fetch match, (err, result) ->
        if err then done(err) else done(null, link: match, meta: result)

  if jobs.length > 0
    Async.parallel jobs, (err, results) ->
      event.set 'meta', results
      done()
  else
    done()

Mongoose.model 'RoomEvent', schema
