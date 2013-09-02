_ = require("underscore")
dateFormat = require('dateformat')
mongoose = require 'mongoose'

User = mongoose.model 'User'
Hero = mongoose.model 'Hero'
Room = mongoose.model 'Room'
History = mongoose.model 'History'

dice = require('./dice')
console.log "Roll 2d5+8 = %d", dice.rollDie "2d5+8"

df = "mmmm dS, HH:MM"
df = "HH:MM:ss"

roll_template = _.template "roll dice <%=d%> = <strong><%=result%></strong>"

roll_die = (message)->
    d = message.text.slice(6).replace RegExp(" ", "g"), ""
    try
        result = dice.rollDie d
    catch e
        result = NaN
    if result >= 0
        message.text = roll_template
            d: d
            result: result
        message.event_type = "event"
    else
        message.event_type = "system_message"
        message.text = "Wrong /roll format"
        message.allow_send = false
        
    return message
    
    
player_event = (message)->
    message.event_type = "event"
    message.text = message.text.slice(4)
    return message


master_event = (message)->
    message.event_type = "master_event"
    message.text = message.text.slice(7)
    return message

master_as = (message)->
    words = message.text.split ' '
    message.username = "<span class='npc'>" + words[1] + "</span>"
    message.text = words.slice(2).join " "
    return message

help = (message, is_master)->
    message.event_type = "system_message"
    message.text = "<strong>Command list:</strong><ul>"+
        "<li><strong>/me</strong> blah-blah &mdash; you do blah-blah as event</li>"+
        "<li><strong>/roll</strong> XdY+Z &mdash; you roll dice</li>"
    if is_master
        message.text += "<li><strong>/event</strong> blah-blah &mdash; show blah-blah as global event</li>"
        message.text += "<li><strong>/as</strong> Name blah-blah &mdash; say blah-blah as Name</li>"
        message.text += "<li><strong>/kick</strong> Player &mdash; kick player from room</li>"
    message.text += "</ul>"
    message.allow_send = false
    return message

on_message = (socket, message_text)->
    socket.get "data", (err, data)->
        unless data?
            console.log "Cant fetch data from socket"
            return
        
        Room.findOne(_id: data.room._id).populate("master").exec (err, room)->
            unless room?
                console.log "Wrong room"
                return
                
            message =
                text: message_text
                username: data.displayname
                room: data.room.name
                timestamp: dateFormat(new Date(), df)
                allow_send: true
                event_type: "chat_message"
            
            console.log "Incoming message (%s): %s", data.hero.displayname, message_text
            
            re = new RegExp("^/([^ ]*)")
            cmd = re.exec(message.text)
            if cmd?
                switch cmd[1]
                    when 'roll'
                        message = roll_die message
                    when 'me'
                        message = player_event message
                    when 'event'
                        if data.is_master
                            message = master_event message
                    when 'as'
                        if data.is_master
                            message = master_as message      
                    when 'help'
                        message = help message, data.is_master               
                    when 'kick'
                        if data.is_master
                            player = message.text.split(" ").slice(1)[0]
                            message = kick socket, message, player
                                    
            if data.is_master
                displayname = message.username
            else
                displayname = "<span class='you'>You</span>"
            socket.emit message.event_type,
                text: message.text
                username: displayname
                room: message.room
                timestamp: message.timestamp
                event_type: message.event_type
            
            unless message.allow_send
                return
            
            history = new History
                room: room._id
                user: data.user._id
                timestamp: new Date()
                event_type: message.event_type
                text: message.text
                displayname: message.username
            console.log history
            history.save (err)->
                if err?
                    console.log err
                else
                    socket.broadcast.to(data.room.name).emit message.event_type, message
                                
                    
                                
    
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
            console.log "Auth data: ", data
            data.user = user
            data.room = room
            data.hero = hero
            data.is_master = room.master.toHexString() == user._id.toHexString()
            socket.join(room.name)
            socket.join(hero.displayname)
            if data.is_master
                data.displayname = "<span class='master'>"+hero.displayname+'</span>'
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
        
on_disconnect = (socket)->
    console.log "Client Disconnected. ID: %s", socket.id
    socket.get "data", (err, data)->
        unless data?
            return
        
        timestamp = dateFormat(new Date(), df)
        socket.broadcast.to(data.room.name).emit "player_leave",
            timestamp: timestamp
            username: data.displayname
            
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
    
    return message
    
on_get_history = (socket)->
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

on_error = (socket)->
    console.log err
    
on_room_description = (socket, desc)->
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
            
on_notes = (socket, notes)->
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

on_hero_description = (socket, desc)->
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
    
on_update_layout = (socket, layout)->
    socket.get "data", (err, data)->
        unless data?
            return false
            
        Hero.update user: data.user._id,
            $set:
                layout: layout
            , (e, n)->
                return true
    

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
                    on_message socket, data
                when "request_history"
                    on_get_history socket
                when "connect"
                    on_connect socket, data
                when "update_layout"
                    on_update_layout socket, data
                when "room_description"
                    on_room_description socket, data
                when "hero_description"
                    on_hero_description socket, data
                when "notes"
                    on_notes socket, data
                when "disconnect"
                    on_disconnect socket
                when "error"
                    on_error socket, err
                    
        socket.emit "plz_connect"
                    
