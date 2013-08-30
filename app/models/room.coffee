mongoose = require 'mongoose'

#
# Room Schema
#
Schema = mongoose.Schema

###
# Mongoose model schema
# Parameters for views generator
# @module schema
# @param [string] name
# @param [objectid] master
###

RoomSchema = new Schema
  name:
    type: String
  master:
    { type: Schema.Types.ObjectId, ref: 'User' }
 
#
# Schema statics
#
RoomSchema.statics =
  list: (cb) ->
    this.find().sort
      createdAt: -1
    .exec(cb)
    return

Room = mongoose.model 'Room', RoomSchema

HistorySchema = new Schema
    room:
        {type: Schema.Types.ObjectId, ref: "room"}
    user:
        { type: Schema.Types.ObjectId, ref: 'User' }
    event_type:
        type: String
    timestamp:
        type: Date
    text:
        type: String
        
History = mongoose.model 'History', HistorySchema