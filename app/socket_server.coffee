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
            
            console.log "Incoming message (%s): %s", data.user.name, message_text
            
            if message.text.indexOf("/roll ") == 0
                message = roll_die message
            
            if message.text.indexOf("/me ") == 0
                message = player_event message
                
            if message.text.indexOf("/event ") == 0
                if data.user.name == room.master.name
                    message = master_event message

            if message.text.indexOf("/as ") == 0
                if data.user.name == room.master.name
                    message = master_as message
                    
            if message.text.indexOf("/help") == 0
                message = help message, data.user.name == room.master.name
            
            if message.text.indexOf("/kick ") == 0
                if data.user.name == room.master.name
                    player = message.text.split(" ").slice(1)[0]
                    message = kick message, player
                                    
            if data.user.name == room.master.name
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
    User.findOne _id: data.user, (err, user)->
        if user?
            Room.findOne name: data.room, (err, room)->
                if room?
                    console.log "New user for %s. Username: %s", socket.id, user.name
                    console.log "Auth data: ", data
                    data.user = user
                    data.room = room
                    socket.join(data.room.name)
                    if room.master.toHexString() == user._id.toHexString()
                        data.displayname = "<span class='master'>"+data.user.name+'</span>'
                    else
                        data.displayname = data.user.name
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
                            user_id: e.user._id
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
            
kick = (message, player)->
    message.event_type = "disconnect"
    message.text = player + " was kicked"
    message.username = player
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
            return

        Room.update
            _id: data.room._id
        ,
            $set:
                description: desc
        , (e, n)->
            socket.broadcast.emit "room_description", desc
    
on_update_layout = (socket, layout)->
    socket.get "data", (err, data)->
        unless data?
            return
            
        Hero.update user: data.user._id,
            $set:
                layout: layout
            , (e, n)->
                console.log e, n, "layout updated"
    

exports.init = (io)->
    sockets = io.sockets
    sockets.on "connection", (socket) ->
        console.log "Client Connected. ID: %s", socket.id
        socket.all = io.sockets
        socket.on "message", (message_text) -> on_message socket, message_text
        socket.on "request_history", -> on_get_history socket
        socket.on "connect", (data) -> on_connect socket, data
        socket.on "update_layout", (data) -> on_update_layout socket, data
        socket.on "room_description", (data) -> on_room_description socket, data
        socket.on "disconnect", -> on_disconnect socket
        
        socket.on "error", (err)-> on_error socket, err
        socket.emit "plz_connect"
                    
