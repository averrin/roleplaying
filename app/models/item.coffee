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