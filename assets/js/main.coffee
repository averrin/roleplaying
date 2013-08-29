root = exports ? this

root.user_list_template = _.template "<li data-user='<%=username%>'><%=username%></li>"

root.add_user_to_list = (username) ->
    $("#player_list").append root.user_list_template username:username
    
root.remove_user_from_list = (username) ->
    $("#player_list").html ""
    $("#player_list li[data-user='"+username+"']").remove()

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
        root.add_user_to_list data.username
        
    root.socket.on "player_leave", (data)->
        console.log "Player", data, "left room"
        root.remove_user_from_list data
        
    root.socket.on "players", (data)->
        console.log "Players list", data
        _.each data, (e,i)->
            console.log e
            root.add_user_to_list e.username
        
