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
    type: Schema.Types.ObjectId
 
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