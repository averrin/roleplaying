root = exports ? this

root.user_list_template = _.template "<li data-user='<%=username%>'><%=username%></li>"
root.user_join_template = _.template "<li data-user='<%=username%>'><strong><%=username%></strong> join to our room</li>"
root.user_left_template = _.template "<li data-user='<%=username%>'><strong><%=username%></strong> left our room</li>"
root.new_message_template = _.template "<li data-user='<%=username%>'><strong><%=username%>:</strong> <%=text%></li>"

root.add_user_to_list = (username) ->
    $("#player_list").append root.user_list_template username:username
    $("#chat_box").append root.user_join_template username:username
    
root.remove_user_from_list = (username) ->
    $("#player_list").html ""
    $("#player_list li[data-user='"+username+"']").remove()
    $("#chat_box").append root.user_left_template username:username
    
root.add_message = (msg) ->
    $("#chat_box").append root.new_message_template msg

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
    
    root.socket.on "chat_message", (data)->
        console.log "New message", data
        root.add_message data
        
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
            
            
    $(".chat_send").on "click", (ev)->
        root.socket.emit "message", $(".chat_input").val()
        $(".chat_input").val('')
        
