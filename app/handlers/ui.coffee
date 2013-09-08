_ = require("underscore")
dateFormat = require('dateformat')
mongoose = require 'mongoose'
u = require('util')
f = u.format

User = mongoose.model 'User'
Hero = mongoose.model 'Hero'
Room = mongoose.model 'Room'
History = mongoose.model 'History'

df = "mmmm dS, HH:MM"
df = "HH:MM:ss"


exports.get_templates = (data)->
    uin = '<li class="dropdown" data-user="<%=user_id%>">
              <a id="user_<%=user_id%>" role="button" data-toggle="dropdown" href="#"><%=username%></b></a>
              <ul id="menu_<%user_id%>" class="dropdown-menu pull-right" role="menu" aria-labelledby="user_<%=user_id%>">
                <li role="presentation"><a role="menuitem" tabindex="-1" href="http://twitter.com/fat">Action</a></li>'
    if data.is_master
        uin += '<li role="presentation"><a role="menuitem" tabindex="-1" href="http://twitter.com/fat">Another action</a></li>
                <li role="presentation"><a role="menuitem" tabindex="-1" href="http://twitter.com/fat">Something else here</a></li>
                <li role="presentation" class="divider"></li>
                <li role="presentation"><a role="menuitem" tabindex="-1" href="http://twitter.com/fat">Separated link</a></li>'
    uin += '</ul>
            </li>'
    templates =
        user_in_list: _.template(uin).source
        user_join: _.template("<article class='system_event'>
        <em><strong><%=username%></strong> join to our room</em>
        </article>").source
        user_left: _.template("<article class='system_event'>
        <em><strong><%=username%></strong> left our room</em>
        </article>").source
        chat_message: _.template("<article class='message'><small class='timestamp'>[<%=timestamp%>]</small>
        <strong><%=username%>:</strong> <%=text%>
        </article>").source
        
        pm: _.template("<article class='pm'><small class='timestamp'>[<%=timestamp%>]</small>
        <strong><%=username%> only for you:</strong><br><em><%=text%></em>
        </article>").source
        
        event: _.template("<article class='event'>
        <em><strong><%=username%></strong> <%=text%></em>
        </article>").source
        
        master_event: _.template("<article class='master_event'>
        <em><%=text%></em>
        </article>").source
        
        system_message: _.template("<article class='system_event'>
        <em><%=text%></em>
        </article>").source
    return templates

exports.on_get_history = (socket)->
    socket.get "data", (err, data)->
        unless data?
            return
        history_list = []
        History.find(room: data.room._id).populate("user").exec (err, history)->
            unless history
                return
            _.each history, (e, i)->
                history_list.push
                    timestamp: dateFormat(e.timestamp, df)
                    event_type: e.event_type
                    username: e.displayname
                    text: e.text
            socket.emit "history", history_list

exports.on_error = (socket)->
    console.log err
    
exports.on_room_description = (socket, desc)->
    socket.get "data", (err, data)->
        unless data?
            return false

        Room.update
            _id: data.room._id
        ,
            $set:
                description: desc
        , (e, n)->
            socket.broadcast.to(data.room.name).emit "room_history", desc
            
exports.on_notes = (socket, notes)->
    socket.get "data", (err, data)->
        unless data?
            return false

        Hero.update
            user: data.user._id
        ,
            $set:
                notes: notes
        , (e, n)->
            return true

exports.on_hero_description = (socket, desc)->
    socket.get "data", (err, data)->
        unless data?
            return false

        Hero.update
            user: data.user._id
        ,
            $set:
                description: desc
        , (e, n)->
            return true
    
exports.on_update_layout = (socket, layout)->
    socket.get "data", (err, data)->
        unless data?
            return false
            
        Hero.update user: data.user._id,
            $set:
                layout: layout
            , (e, n)->
                return true