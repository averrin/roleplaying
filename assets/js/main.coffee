root = exports ? this

root.user_list_template = _.template "<li data-user='<%=username%>'><%=username%></li>"
root.user_join_template = _.template "<article class='event' data-user='<%=username%>'><small class='timestamp'>[<%=timestamp%>]</small>
    <strong><%=username%></strong> join to our room
    </article>"
root.user_left_template = _.template "<article class='event' data-user='<%=username%>'><small class='timestamp'>[<%=timestamp%>]</small>
    <strong><%=username%></strong> left our room
    </article>"
root.new_message_template = _.template "<article class='message' data-user='<%=username%>'><small class='timestamp'>[<%=timestamp%>]</small>
    <strong><%=username%>:</strong> <%=text%>
    </article>"
    
root.new_event_template = _.template "<article class='message' data-user='<%=username%>'>
    <em><strong><%=username%></strong> <%=text%></em>
    </article>"

root.add_user_to_list = (user) ->
    $("#player_list").append root.user_list_template user
    $("#chat_box").append root.user_join_template user
    
root.remove_user_from_list = (user) ->
    $("#player_list").html ""
    $("#player_list li[data-user='"+username+"']").remove()
    $("#chat_box").append root.user_left_template user
    
root.add_message = (msg) ->
    $("#chat_box").append root.new_message_template msg
    
root.add_event = (event) ->
    $("#chat_box").append root.new_event_template event

$(document).ready ->

    root.socket = io.connect()
  
    root.socket.on "server_message", (data) ->
        console.log data
        
    root.socket.on "connected", (data)->
        $(".loader").hide()
        $("#chat_input").attr("disabled", null)
        
    root.connect = ()->
        root.socket.emit "connect",
            username: $(".username").data "username"
            room: "Main"
      
    root.socket.on "plz_connect", ->
        root.connect()
    
    root.socket.on "chat_message", (data)->
        console.log "New message", data
        root.add_message data
        
    root.socket.on "event", (data)->
        console.log "New event", data
        root.add_event data
        
    root.socket.on "new_player", (data)->
        console.log "New player", data.username
        root.add_user_to_list data
        
    root.socket.on "player_leave", (data)->
        console.log "Player", data, "left room"
        root.remove_user_from_list data
        
    root.socket.on "players", (data)->
        console.log "Players list", data
        _.each data, (e,i)->
            console.log e
            root.add_user_to_list e
            
            
    $("#chat_form").on "submit", (ev)->
        ev.preventDefault()
        if $("#chat_input").val() != ''
            root.socket.emit "message", $("#chat_input").val()
            $("#chat_input").val('')
        
