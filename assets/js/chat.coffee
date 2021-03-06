root = exports ? this

root.templates = {}

root.add_user_to_list = (user) ->
    $("#player_list").append root.templates["user_in_list"] user
    $("#chat_box").append root.templates["user_join"] user
    
root.remove_user_from_list = (user) ->
    $("#player_list").html ""
    $("#player_list li[data-user='"+user.user_id+"']").remove()
    $("#chat_box").append root.templates["user_left"] user
    
root.add_to_chat = (msg) ->
    chat = $("#chat_box")
    chat.append root.templates[msg.event_type] msg
    chat.animate scrollTop: chat.prop("scrollHeight"), 500
    
root.request_history = ()->
    root.socket.emit "request_history",
        user: $("#user").data "user"
        room: $("#room").data "room"
        
root.show_history = (history)->
    chat = $("#chat_box")
    _.each history.reverse(), (e,i)->
        h = root.templates[e.event_type] e
        $("#chat_box").prepend h
    chat.animate scrollTop: chat.prop("scrollHeight"), 500
        
        
root.update_player_list = (players)->
    $("#player_list").html ""
    _.each players, (e,i)->
        root.add_user_to_list e
        
root.connect = ()->
    root.socket.emit "connect",
        user: $("#user").data "user"
        room: $("#room").data "room"
        hero: $("#hero").data "hero"
        
root.disconnect = (data)->
    unless data?
        return
    if data.username == $("#user").data("username")
        console.log "You were kicked"
        window.location = '/'
    else
        data.event_type = "player_leave"
        root.remove_user_from_list data
        
        
root.room_description = (desc)->
    $("#room_description").html desc


root.routes =
    plz_connect: root.connect
    chat_message: root.add_to_chat
    pm: root.add_to_chat
    event: root.add_to_chat
    master_event: root.add_to_chat
    system_message: root.add_to_chat
    new_player: root.add_user_to_list
    player_leave: root.remove_user_from_list
    players: root.update_player_list
    disconnect: root.disconnect
    room_description: root.room_description
    
    
root.layout_change = (ev, ui)->
    layout =
        chat_widget: gridster.serialize($("#chat_widget"))[0]
        list_widget: gridster.serialize($("#list_widget"))[0]
        status_widget: gridster.serialize($("#status_widget"))[0]
        hero_widget: gridster.serialize($("#hero_widget"))[0]
        master_widget: gridster.serialize($("#master_widget"))[0]
    root.socket.emit "update_layout", layout

$(document).ready ->
    
    
    $(".gridster ul.widgets").gridster
        widget_margins: [4, 4]
        widget_base_dimensions: [160, 160]
        widget_selector: "li.widget"
        draggable:
            stop: (ev, ui) ->
                root.layout_change ev, ui
    root.gridster = $(".gridster ul").gridster().data('gridster')
    root.gridster.disable()
    $(".widget_header").on "mouseover", () -> gridster.enable()
    $(".widget_header").on "mouseout", () -> gridster.disable()
    

    root.socket = io.connect('http://averr.in:3300')

    CKEDITOR.on 'instanceReady', ()->
        if 'room_description' in CKEDITOR.instances
            CKEDITOR.instances['room_description'].on 'change', ()->
                root.socket.emit "room_description", CKEDITOR.instances['room_description'].getData()
        CKEDITOR.instances['notes'].on 'change', ()->
            root.socket.emit "notes", CKEDITOR.instances['notes'].getData()
        CKEDITOR.instances['hero_description'].on 'change', ()->
            root.socket.emit "hero_description", CKEDITOR.instances['hero_description'].getData()

  
    root.socket.on "server_message", (data) ->
        console.log data
        
    root.socket.on "history", (data) ->
        console.log "Recieved history", data
        root.show_history data
        
    root.socket.on "connected", (data)->
        _.each _.keys(data.templates), (e,i)->
            t = data.templates[e]
            t = Function "obj", t.slice(15, t.length-2)
            root.templates[e] = t
        $(".loader").hide()
        $(".widgets").show()
        $("#player_list").html ""
        $("#request_history").off()
        $("#request_history").on "click", (ev)->
            root.request_history()
            $("#request_history").hide()
        $("#chat_input").attr("disabled", null)
        $("#chat_input").focus()
        _.each CKEDITOR.instances, (e, i) ->
            $(e.element.$).attr "contenteditable", "true"
            e.readOnly = false
        
      
    _.each _.keys(root.routes), (e,i)->
        root.socket.on e, (data)->
            root.routes[e] data
            
            
    $("#chat_form").on "submit", (ev)->
        ev.preventDefault()
        if $("#chat_input").val() != ''
            root.socket.emit "message", $("#chat_input").val()
            $("#chat_input").val('')
            
    window.onunload = (e)->
        root.socket.emit "quit"
            
 
