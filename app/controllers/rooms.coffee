mongoose = require 'mongoose'
_ = require 'underscore'

Room = mongoose.model 'Room'
User = mongoose.model 'User'
Hero = mongoose.model 'Hero'


exports.main = (req, res) ->
    room = req.room
    is_master = room.master.equals req.user._id
    Hero.findOne user: req.user._id, (err, hero)->
        unless hero
            hero = new Hero
                user: req.user._id
                room: req.room._id
                displayname: req.user.name
                layout:
                    chat_widget:
                        col: 1
                        row: 2
                        size_x: 4
                        size_y: 4
                    list_widget:
                        col: 5
                        row: 1
                        size_x: 2
                        size_y: 2
                    notes_widget:
                        col: 5
                        row: 3
                        size_x: 2
                        size_y: 2
                    status_widget:
                        col: 1
                        row: 1
                        size_x: 4
                        size_y: 1
                
            hero.save (err)->
                console.log err, "Hero saved"
        res.render 'chat/main',
            room: room
            is_master: is_master
            hero: hero
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
    new_room = req.body
    new_room.master = req.user._id
    room = new Room new_room
    room.save (err) ->
        if err
          res.render 'rooms/new',
            errors: err.errors
            room: room
        res.redirect '/rooms'
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
  room_list = Room.find()
  room_list.populate("master").exec (err, rooms_list) ->
    res.render 'rooms/manage',
      all_rooms: rooms_list
      message: req.flash 'notice'
    return

#
# Rooms index
#
exports.index = (req, res) ->
  room_list = Room.find()
  room_list.populate("master").exec (err, rooms_list) ->
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
