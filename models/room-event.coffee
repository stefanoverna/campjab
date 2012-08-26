mongoose = require 'mongoose'

schema = new mongoose.Schema
  room: String,
  type: String,
  from: String,
  body: String,
  at: Date

schema.statics.findByDate = (limit = 50, since = null, cb) ->
  if since
    @findById since, (err, event) =>
      @find().where('at').lt(event.get('at')).sort("-at").limit(limit).exec (err, results) ->
        cb results.reverse()
  else
      @find().sort("-at").limit(limit).exec (err, results) ->
        cb results.reverse()

mongoose.model 'RoomEvent', schema
