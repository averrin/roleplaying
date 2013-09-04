mongoose = require 'mongoose'
User = mongoose.model("User")

#
# Global template helpers
#
module.exports = (app) ->
  
  #
  # Template function for Markdown rendering
  #
  marked = require 'marked'
  app.locals.marked = marked
  
  #
  # Named date parsing functions
  #
  moment = require 'moment'
  
  app.locals.dateShortMon = (date) ->
    return moment(date).format 'MMM DD'
    
  app.locals.is_admin = true
  #app.locals.is_admin = (req, res) ->
    #User.findById(req.user._id).exec (err, user) ->
      #user.admin
      
    