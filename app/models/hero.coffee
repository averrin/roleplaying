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