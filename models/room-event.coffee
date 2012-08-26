mongoose = require 'mongoose'
linkMeta = require '../lib/link-meta'
async = require 'async'

schema = new mongoose.Schema
  room: String,
  type: String,
  from: String,
  body: String,
  meta: mongoose.Schema.Types.Mixed,
  at: Date

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
    async.parallel jobs, (err, results) ->
      event.set 'meta', results
      done()
  else
    done()

mongoose.model 'RoomEvent', schema
