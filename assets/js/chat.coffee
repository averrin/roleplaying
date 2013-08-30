root = exports ? this

root.templates = 
    user_in_list: _.template "<li data-user='<%=user_id%>'><%=username%></li>"
    user_join: _.template "<article class='system_event'>
    <em><strong><%=username%></strong> join to our room</em>
    </article>"
    user_left: _.template "<article class='system_event'>
    <em><strong><%=username%></strong> left our room</em>
    </article>"
    chat_message: _.template "<article class='message'><small class='timestamp'>[<%=timestamp%>]</small>
    <strong><%=username%>:</strong> <%=text%>
    </article>"
    
    event: _.template "<article class='event'>
    <em><strong><%=username%></strong> <%=text%></em>
    </article>"
    
    master_event: _.template "<article class='master_event'>
    <em><%=text%></em>
    </article>"
    
    system_event: _.template "<article class='system_event'>
    <em><%=text%></em>
    </article>"

root.add_user_to_list = (user) ->
    $("#player_list").append root.templates["user_in_list"] user
    $("#chat_box").append root.templates["user_join"] user
    
root.remove_user_from_list = (user) ->
    $("#player_list").html ""
    $("#player_list li[data-user='"+user.user_id+"']").remove()
    $("#chat_box").append root.templates["user_left"] user
    
root.add_message = (msg) ->
    $("#chat_box").append root.templates["chat_message"] msg
    
root.add_event = (event) ->
    $("#chat_box").append root.templates["event"] event
    
root.add_system = (event) ->
    $("#chat_box").append root.templates["system_event"] event
    
root.request_history = ()->
    root.socket.emit "request_history",
        user: $("#user").data "user"
        room: $("#room").data "room" 
        
root.show_history = (history)->
    _.each history.reverse(), (e,i)->
        h = root.templates[e.event_type] e
        $("#chat_box").prepend h

$(document).ready ->

    root.socket = io.connect()
  
    root.socket.on "server_message", (data) ->
        console.log data
        
    root.socket.on "history", (data) ->
        console.log "Recieved history", data
        root.show_history data
        
    root.socket.on "connected", (data)->
        $(".loader").hide()
        $("#request_history").hide()
        $("#request_history").off()
        $("#chat_box").prepend "<a href='javascript://' id='request_history'>Request history</a>"
        $("#request_history").on "click", (ev)->
            root.request_history()
            $("#request_history").hide()
        $("#chat_input").attr("disabled", null)
        
    root.connect = ()->
        root.socket.emit "connect",
            user: $("#user").data "user"
            room: $("#room").data "room"
      
    root.socket.on "plz_connect", ->
        root.connect()
    
    root.socket.on "chat_message", (data)->
        console.log "New message", data
        root.add_message data
        
    root.socket.on "event", (data)->
        console.log "New event", data
        root.add_event data
        
    root.socket.on "system_message", (data)->
        console.log "New system event", data
        root.add_system data
        
    root.socket.on "new_player", (data)->
        console.log "New player", data
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
            
        
