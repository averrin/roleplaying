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
    required: true,
    unique: true
  master:
    type: Schema.Types.ObjectId
    ref: 'User'
  description:
    type: String
 
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
        type: Schema.Types.ObjectId
        ref: "room"
    user:
        type: Schema.Types.ObjectId
        ref: 'User'
    event_type:
        type: String
    timestamp:
        type: Date
    displayname:
        type: String
    text:
        type: String
        
History = mongoose.model 'History', HistorySchema


HeroSchema = new Schema
    room:
        type: Schema.Types.ObjectId
        ref: "room"
    user:
        type: Schema.Types.ObjectId
        ref: 'User'
    displayname:
        type: String
    description:
        type: String
    notes:
        type: String
    layout: Schema.Types.Mixed
    settings: Schema.Types.Mixed

Hero = mongoose.model 'Hero', HeroSchema