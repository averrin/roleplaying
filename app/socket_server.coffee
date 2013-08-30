_ = require("underscore")
dateFormat = require('dateformat')
mongoose = require 'mongoose'

User = mongoose.model 'User'
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
    message.text = message_text.slice(4)
    return message


on_message = (socket, message_text)->
    socket.get "data", (err, data)->
        unless data?
            console.log "Cant fetch data from socket"
            return
        
        Room.findOne(name: data.room).populate("master").exec (err, room)->
            unless room?
                console.log "Wrong room"
                return
                
            message =
                text: message_text
                username: data.username
                room: data.room
                timestamp: dateFormat(new Date(), df)
                allow_send: true
                event_type: "chat_message"
            
            console.log "Incoming message (%s): %s", data.username, message_text
            
            if message.text.indexOf("/roll ") == 0
                message = roll_die message
            
            if message_text.indexOf("/me ") == 0
                message = player_event message
            
            
                
            socket.emit message.event_type, 
                text: message.text
                username: "<span class='you'>You</span>"
                room: message.room
                timestamp: message.timestamp
            
            unless message.allow_send
                return
            
            history = new History
                room: room._id
                user: data.user_id
                timestamp: new Date()
                event_type: message.event_type
                text: message.text
            console.log history
            history.save (err)->
                if err?
                    console.log err
                else
                    if data.username == room.master.name
                        message.username = "<span class='master'>"+data.username+'</span>'
                    socket.broadcast.to(data.room).emit message.event_type, message
                                
                    
                                
    
on_connect = (socket, data) ->
    User.findOne _id: data.user, (err, user)->
        if user?
            Room.findOne name: data.room, (err, room)->
                if room?
                    console.log "New user for %s. Username: %s", socket.id, user.name
                    console.log "Auth data: ", data
                    data.username = user.name
                    data.user_id = user._id
                    data.room_id = room._id
                    socket.join(data.room)
                    socket.set "data", data
                    data.timestamp = dateFormat(new Date(), df)
                    if room.master.toHexString() == user._id.toHexString()
                        data.username = "<span class='master'>"+data.username+'</span>'
                    socket.broadcast.to(data.room).emit "new_player", data
                    socket.emit "connected", data
                    pl = _.pluck _.pluck(socket.all.clients(data.room), 'store'), 'data'
                    #players = []
                    #_.each pl[0], (e,i)->
                        #if room.master == user._id
                        
                    socket.emit "players", pl[0]
        
on_disconnect = (socket)->
    console.log "Client Disconnected. ID: %s", socket.id
    socket.get "data", (err, data)->
        unless data?
            return
        
        data.timestamp = dateFormat(new Date(), df)
        socket.broadcast.to(data.room).emit "player_leave", data
            
            
on_get_history = (socket)->
    socket.get "data", (err, data)->
        unless data?
            return
        history_list = []
        History.find(room: data.room_id).populate("user").exec (err, history)->
            unless history
                return
            _.each history, (e, i)->
                history_list.push
                    timestamp: dateFormat(e.timestamp, df)
                    event_type: e.event_type
                    username: e.user.name
                    text: e.text
            socket.emit "history", history_list


exports.init = (io)->
    sockets = io.sockets
    sockets.on "connection", (socket) ->
        console.log "Client Connected. ID: %s", socket.id
        socket.all = io.sockets
        socket.on "message", (message_text) -> on_message socket, message_text
        socket.on "request_history", -> on_get_history socket
        socket.on "connect", (data) -> on_connect socket, data
        socket.on "disconnect", -> on_disconnect socket
        
        socket.emit "plz_connect"
                    
