mongoose = require 'mongoose'
_ = require 'underscore'

User = mongoose.model 'User'

#
# List users
#
exports.main = (req, res) ->
  res.render 'room/main',
    boom: "boom"
  return


