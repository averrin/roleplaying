_ = require("underscore")
dateFormat = require('dateformat')
mongoose = require 'mongoose'
u = require('util')
f = u.format

User = mongoose.model 'User'
Hero = mongoose.model 'Hero'
Room = mongoose.model 'Room'
History = mongoose.model 'History'

dice = require('./dice')
console.log "Roll 2d5+8 = %d", dice.rollDie "2d5+8"

df = "mmmm dS, HH:MM"
df = "HH:MM:ss"        

fs = require 'fs'
root = require('path').normalize(__dirname + '/..')
handlers_path = root + '/app/handlers'
fs.readdirSync(handlers_path).forEach (file) ->
    @[file.slice(0, -7)] = require "#{handlers_path}/#{file}"
                    
                                
    
on_connect = (socket, data) ->
    now = dateFormat(new Date(), df)
    Hero.findOne(_id: data.hero).populate("user").exec (err, hero)->
        unless hero?
            return
        unless hero.user._id.toHexString() == data.user
            return
            
        if "/" + hero.displayname in _.keys(socket.all.manager.rooms)
            kick socket, {}, hero.displayname
            
        user = hero.user
            
        Room.findOne name: data.room, (err, room)->
            unless room?
                return
                
            console.log "New user for %s. Username: %s, Hero: %s", socket.id, user.name, hero.displayname
            console.log "Auth data: ", u.inspect data
            data.user = user
            data.room = room
            data.hero = hero
            data.is_master = room.master.toHexString() == user._id.toHexString()
            socket.join(room.name)
            socket.join(hero.displayname)
            if data.is_master
                data.displayname = f "<span class='master'>%s</span>", hero.displayname
            else
                data.displayname = hero.displayname
            socket.broadcast.to(data.room.name).emit "new_player",
                timestamp: now
                username: data.displayname
                user_id: user._id
                room: room.name
            socket.set "data", data
            socket.emit "connected",
                timestamp: now
            pl = _.pluck _.pluck(socket.all.clients(data.room.name), 'store'), 'data'
            players = []
            _.each pl[0], (e,i)->
                players.push
                    user_id: e.hero._id
                    username: e.displayname
                    
            socket.emit "players", players
            
            if room.online.indexOf(user._id) == -1
                room.online.push user._id
                room.save (err)->
                    console.log err, "user online", room
        
on_disconnect = (socket)->
    console.log "Client Disconnected. ID: %s", socket.id
    socket.get "data", (err, data)->
        unless data?
            return
        
        timestamp = dateFormat(new Date(), df)
        socket.broadcast.to(data.room.name).emit "player_leave",
            timestamp: timestamp
            username: data.displayname
        
        Room.findById(data.room._id).exec (err, room)->
            room.online.remove data.user._id
            room.save (err)->
                console.log err, "user disconnect"
            
kick = (socket, message, player)->
    if "/" + player in _.keys(socket.all.manager.rooms)
        message.event_type = "disconnect"
        message.text = player + " was kicked"
        message.username = player
        
        sockets = socket.all.manager.rooms["/" + player]
        _.each sockets, (e,i)->
            socket.all.socket(e).emit message.event_type, message
            socket.all.socket(e).disconnect()
        
    else
        message.event_type = "system_message"
        message.text = "Wrong player to kick"
        message.allow_send = false
    message.out_of_history = true
    cb message
    

exports.init = (io)->
    sockets = io.sockets
    sockets.on "connection", (socket) ->
        console.log "Client Connected. ID: %s", socket.id
        socket.all = io.sockets
        socket.io = io
        
        socket.on "*", (event)->
            data = event.args[0]
            switch event.name
                when "message"
                    messages.on_message socket, data
                when "request_history"
                    ui.on_get_history socket
                when "connect"
                    on_connect socket, data
                when "update_layout"
                    ui.on_update_layout socket, data
                when "room_description"
                    ui.on_room_description socket, data
                when "hero_description"
                    ui.on_hero_description socket, data
                when "notes"
                    ui.on_notes socket, data
                when "disconnect"
                    on_disconnect socket
                when "quit"
                    on_disconnect socket
                when "error"
                    ui.on_error socket, err
                    
        socket.emit "plz_connect"
                    
