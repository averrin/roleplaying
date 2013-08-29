mongoose = require 'mongoose'
_ = require 'underscore'

Room = mongoose.model 'Room'
User = mongoose.model 'User'


exports.main = (req, res) ->
    room = req.room
    res.render 'chat/main',
        room: room
    return

#
# New room form
#
exports.new = (req, res) ->
  res.render 'rooms/new',
    room: new Room({})
  return

#
# Create new room
#
exports.create = (req, res) ->
    console.log "REQ: ", req.body
    new_room = req.body
    User.findOne name: new_room.master, (err, user)->
        if user?
            new_room.master = user
            room = new Room new_room
            room.save (err) ->
                if err
                  res.render 'rooms/new',
                    errors: err.errors
                    room: room
                res.redirect '/rooms'
            return
    return

exports.show = (req, res) ->
  undefined

#
# Room edit form
#
exports.edit = (req, res) ->
  room = req.room
  res.render 'rooms/edit',
    room:room
  return

#
# Update room
#
exports.update = (req, res) ->
  room = req.room
  
  room = _.extend room, req.body
  room.save (err) ->
    if err
      res.render 'rooms/edit',
        room:room
        errors: err.errors
    else
      req.flash 'notice', room.title + ' was successfully updated.'
      res.redirect '/rooms'
    return
  return

#
# Delete room
#
exports.destroy = (req, res) ->
  room = req.room
  room.remove (err) ->
    req.flash 'notice', room.title + ' was successfully deleted.'
    res.redirect '/rooms'

#
# Manage rooms
#
exports.manage = (req, res) ->
  Room.list (err, rooms_list) ->
    console.log rooms_list
    res.render 'rooms/manage',
      all_rooms: rooms_list
      message: req.flash 'notice'
    return

#
# Rooms index
#
exports.index = (req, res) ->
  Room.list (err, rooms_list) ->
    console.log rooms_list
    res.render 'rooms/index',
      all_rooms: rooms_list
  return

#
# Find room by ID
#
exports.room = (req, res, next, id) ->
  Room.findById(id).exec (err, room) ->
    return next err if err
    return next new Error 'Failed to load room' if not room
      
    req.room = room
    next()
    return
  return
  
exports.roomName = (req, res, next, id) ->
  Room.findOne(name: id).exec (err, room) ->
    return next err if err
    return next new Error 'Failed to load room' if not room
      
    req.room = room
    next()
    return
  return