_ = require("underscore")
dateFormat = require('dateformat')
mongoose = require 'mongoose'
u = require('util')
f = u.format

User = mongoose.model 'User'
Hero = mongoose.model 'Hero'
Room = mongoose.model 'Room'
History = mongoose.model 'History'

df = "mmmm dS, HH:MM"
df = "HH:MM:ss"

exports.on_get_history = (socket)->
    socket.get "data", (err, data)->
        unless data?
            return
        history_list = []
        History.find(room: data.room._id).populate("user").exec (err, history)->
            unless history
                return
            _.each history, (e, i)->
                history_list.push
                    timestamp: dateFormat(e.timestamp, df)
                    event_type: e.event_type
                    username: e.displayname
                    text: e.text
            socket.emit "history", history_list

exports.on_error = (socket)->
    console.log err
    
exports.on_room_description = (socket, desc)->
    socket.get "data", (err, data)->
        unless data?
            return false

        Room.update
            _id: data.room._id
        ,
            $set:
                description: desc
        , (e, n)->
            socket.broadcast.to(data.room.name).emit "room_history", desc
            
exports.on_notes = (socket, notes)->
    socket.get "data", (err, data)->
        unless data?
            return false

        Hero.update
            user: data.user._id
        ,
            $set:
                notes: notes
        , (e, n)->
            return true

exports.on_hero_description = (socket, desc)->
    socket.get "data", (err, data)->
        unless data?
            return false

        Hero.update
            user: data.user._id
        ,
            $set:
                description: desc
        , (e, n)->
            return true
    
exports.on_update_layout = (socket, layout)->
    socket.get "data", (err, data)->
        unless data?
            return false
            
        Hero.update user: data.user._id,
            $set:
                layout: layout
            , (e, n)->
                return true