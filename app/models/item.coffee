mongoose = require 'mongoose'

#
# Item Schema
#
Schema = mongoose.Schema

###
# Mongoose model schema
# Parameters for views generator
# @param [String] title
# @param [Number] uses
# @param [Boolean] consumable
###

ItemSchema = new Schema
  title:
    type: String
  uses:
    type: Number
  consumable:
    type: Boolean
  description:
    type: String
  room:
    type: Schema.Types.ObjectId
    ref: 'Room'
    
 
#
# Schema statics
#
ItemSchema.statics =
  list: (cb) ->
    this.find().sort
      createdAt: -1
    .exec(cb)
    return

Item = mongoose.model 'Item', ItemSchema

SlotSchema = new Schema
  uses:
    type: Number
  item:
    type: Schema.Types.ObjectId
    ref: 'Item'
    
 
#
# Schema statics
#
SlotSchema.statics =
  list: (cb) ->
    this.find().sort
      createdAt: -1
    .exec(cb)
    return

Slot = mongoose.model 'Slot', SlotSchema