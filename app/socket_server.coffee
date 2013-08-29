_ = require("underscore")
dateFormat = require('dateformat')

df = "[mmmm dS, HH:MM]"
df = "[HH:MM:ss]"


on_message = (socket, message_text)->
    socket.get "data", (err, data)->
        if data?
            message =
                text: message_text
                username: data.username
                room: data.room
                timestamp: dateFormat(new Date(), df)
            socket.all.in(data.room).emit "chat_message", message
    
on_connect = (socket, data) ->
    console.log "New user for %s. Username: %s", socket.id, data.username
    console.log data
    socket.join(data.room)
    socket.set "data", data
    data.timestamp = dateFormat(new Date(), df)
    socket.broadcast.to(data.room).emit "new_player", data
    socket.emit "connected", data
    pl = _.pluck _.pluck(socket.all.clients(data.room), 'store'), 'data'
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
                    
