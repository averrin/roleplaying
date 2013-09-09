mongoose = require 'mongoose'

#
# Hero Schema
#
Schema = mongoose.Schema

###
# Mongoose model schema
# Parameters for views generator
# @module schema
# @param [string] displayname
# @param [string] description
# @param [objectid] room
# @param [objectid] user
###

HeroSchema = new Schema
    room:
        type: Schema.Types.ObjectId
        ref: 'Room'
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
    inventory:
        type: [Schema.Types.ObjectId]
        ref: 'Slot'
    stats:
        type: [Schema.Types.ObjectId]
        ref: 'Stat'
#
# Schema statics
#
HeroSchema.statics =
  list: (cb) ->
    this.find().sort
      createdAt: -1
    .exec(cb)
    return

Hero = mongoose.model 'Hero', HeroSchema


ProtoStatSchema = new Schema
    room:
        type: Schema.Types.ObjectId
        ref: 'Root'
    title:
        type: String
    initial:
        type: Number


ProtoStat = mongoose.model 'ProtoStat', ProtoStatSchema


StatSchema = new Schema
    hero:
        type: Schema.Types.ObjectId
        ref: 'Hero'
    proto:
        type: Schema.Types.ObjectId
        ref: 'ProtoStat'
    current:
        type: Number
    max:
        type: Number


Stat = mongoose.model 'Stat', StatSchema