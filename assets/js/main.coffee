root = exports ? this
root.is_logged = false
$(document).ready ->
    root.socket = io.connect()
  
    root.socket.on "server_message", (data) ->
        console.log data
        
    root.socket.on "connected", (data)->
        console.log "connected"
        $(".loader").hide()
        
    root.connect = ()->
        root.socket.emit "connect",
            username: $(".navbar-text").text().split("|")[0].split(", ")[1].replace(/^\s+|\s+$/g, '')
            room: "Main"
        
    root.connect()
        
    root.socket.on "new_player", (data)->
        console.log "New player", data.username
        
    root.socket.on "player_leave", (data)->
        console.log "Player", data, "left room"
        
    root.socket.on "players", (data)->
        console.log "Players list", data
        
