_ = require("underscore")
dateFormat = require('dateformat')

df = "[mmmm dS, HH:MM]"
df = "[HH:MM:ss]"

exports.init = (io)->
    rooms = {}
    io.sockets.on "connection", (socket) ->
        console.log "Client Connected"
        socket.emit "server_message",
            status: "connected"
    
        socket.on "message", (msg) ->
            socket.get "data", (err, data)->
                if data?
                    message =
                        text: msg
                        username: data.username
                        room: data.room
                        timestamp: dateFormat(new Date(), df)
                    io.sockets.in(data.room).emit "chat_message", message
            
        socket.on "connect", (data) ->
            console.log data
            socket.join(data.room)
            socket.set "data", data
            data.timestamp = dateFormat(new Date(), df)
            socket.broadcast.to(data.room).emit "new_player", data
            socket.emit "connected", data
            pl = _.pluck _.pluck(io.sockets.clients(data.room), 'store'), 'data'
            socket.emit "players", pl[0]
    
        socket.on "disconnect", ->
            console.log "Client Disconnected."
            socket.get "data", (err, data)->
                if data?
                    data.timestamp = dateFormat(new Date(), df)
                    socket.broadcast.to(data.room).emit "player_leave", data
                    
