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


on_message = (socket, message_text)->
    socket.get "data", (err, data)->
        if data?
            Room.findOne name: data.room, (err, room)->
                if room?
                    console.log "Incoming message (%s): %s", data.username, message_text
                    allow_send = true
                    reply_type = "chat_message"
                    if message_text.indexOf("/roll ") == 0
                        d = message_text.slice(6).replace RegExp(" ", "g"), ""
                        try
                            result = dice.rollDie d
                        catch e
                            console.log e
                            result = NaN
                        if result >= 0
                            message_text = roll_template
                                d: d
                                result: result
                            reply_type = "event"
                        else
                            reply_type = "system_message"
                            message_text = "Wrong /roll format"
                            allow_send = false
                    else        
                        if message_text.indexOf("/me ") == 0
                            reply_type = "event"
                            message_text = message_text.slice(4)
                            
                    message =
                        text: message_text
                        username: data.username
                        room: data.room
                        timestamp: dateFormat(new Date(), df)
                    
                    if allow_send
                        User.findOne _id: room.master, (err, master)->
                            if master?
                                history = new History
                                    room: room._id
                                    user: data.user_id
                                    timestamp: new Date()
                                    event_type: reply_type
                                    text: message_text
                                console.log history
                                history.save (err)->
                                    if err?
                                        console.log err
                                    else
                                        if data.username == master.name
                                            message.username = "<span class='master'>"+data.username+'</span>'
                                        socket.broadcast.to(data.room).emit reply_type, message
                    message.username = "<span class='you'>You</span>"
                    socket.emit reply_type, message
                                
    
on_connect = (socket, data) ->
    User.findOne _id: data.user, (err, user)->
        if user?
            Room.findOne name: data.room, (err, room)->
                if room?
                    console.log "New user for %s. Username: %s", socket.id, user.name
                    console.log "Auth data: ", data
                    data.username = user.name
                    data.user_id = user._id
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
        if data?
            data.timestamp = dateFormat(new Date(), df)
            socket.broadcast.to(data.room).emit "player_leave", data


exports.init = (io)->
    sockets = io.sockets
    sockets.on "connection", (socket) ->
        console.log "Client Connected. ID: %s", socket.id
        socket.all = io.sockets
        socket.on "message", (message_text) -> on_message socket, message_text
        socket.on "connect", (data) -> on_connect socket, data
        socket.on "disconnect", -> on_disconnect socket
        
        socket.emit "plz_connect"
                    
