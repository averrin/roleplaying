_ = require("underscore")
dateFormat = require('dateformat')
mongoose = require 'mongoose'
u = require('util')
f = u.format

User = mongoose.model 'User'
Hero = mongoose.model 'Hero'
Room = mongoose.model 'Room'
History = mongoose.model 'History'

dice = require('../dice')

df = "mmmm dS, HH:MM"
df = "HH:MM:ss"

roll_template = _.template "roll dice <%=d%> = <strong><%=result%></strong>"

roll_die = (message, gm, cb)->
    d = message.text.slice(6).replace RegExp(" ", "g"), ""
    try
        result = dice.rollDie d
    catch e
        result = NaN
    if result >= 0
        message.text = roll_template
            d: d
            result: result
        message.event_type = "event"
        message.allow_send = !gm
        if gm
            message.text += ' (as master)'
    else
        message.event_type = "system_message"
        message.text = "Wrong /roll format"
        message.allow_send = false
        
    cb message
    
    
player_event = (message, cb)->
    message.event_type = "event"
    message.text = message.text.slice(4)
    cb message


master_event = (message, cb)->
    message.event_type = "master_event"
    message.text = message.text.slice(7)
    cb message

master_as = (message, cb)->
    words = message.text.split ' '
    message.username = f "<span class='npc'>%s</span>", words[1]
    message.text = words.slice(2).join " "
    cb message

help = (message, is_master, cb)->
    message.event_type = "system_message"
    message.text = "<strong>Command list:</strong><ul>"
    message.text += "<li><strong>/me</strong> blah-blah &mdash; you do blah-blah as event</li>"
    message.text += "<li><strong>/roll</strong> XdY+Z &mdash; you roll dice (shortcut: /r)</li>"
    message.text += "<li><strong>/stats</strong> Hero &mdash; get Hero description</li>"
    message.text += "<li><strong>/pm</strong> Hero &mdash; private message to Hero (shortcut: /w)</li>"
    if is_master
        message.text += "<li><strong>/gmroll</strong> XdY+Z &mdash; you roll dice. But result visible only for you</li>"
        message.text += "<li><strong>/event</strong> blah-blah &mdash; show blah-blah as global event</li>"
        message.text += "<li><strong>/as</strong> Name blah-blah &mdash; say blah-blah as Name</li>"
        message.text += "<li><strong>/kick</strong> Player &mdash; kick player from room</li>"
    message.text += "</ul>"
    message.allow_send = false
    cb message
    
show_stats = (message, player, cb)->
    message.allow_send = false
    console.log "stats for", player
    Hero.find("displayname":player).populate(
        path:"room"
        match:
            "name": message.room
        ).exec (err, hero)->
        #console.log err, hero
        unless hero[0]?
            message.event_type = "system_message"
            message.text = "Wrong hero name"
        else
            message.event_type = "master_event"
            message.text = f "<strong>%s description:</strong><br>%s", player, hero[0].description
    
        cb message
        
pm = (message, player, socket, cb)->
    message.allow_send = false
    words = message.text.split ' '
    message.event_type = 'pm'
    message.text = words.slice(2).join " "
    sockets = socket.all.manager.rooms["/" + player]
    _.each sockets, (e,i)->
        socket.all.socket(e).emit message.event_type, message
    message.text = f '<em>Only to %s:</em><br>%s', player, message.text
    message.event_type = 'chat_message'
    cb message

exports.on_message = (socket, message_text)->
    socket.get "data", (err, data)->
        unless data?
            console.log "Cant fetch data from socket"
            return
        
        Room.findOne(_id: data.room._id).populate("master").exec (err, room)->
            unless room?
                console.log "Wrong room"
                return
                
            message =
                text: message_text
                username: data.displayname
                room: data.room.name
                timestamp: dateFormat(new Date(), df)
                allow_send: true
                out_of_history: false
                event_type: "chat_message"
            
            console.log "Incoming message (%s): %s", data.hero.displayname, message_text
            
            re = new RegExp("^\/(\\S+)")
            cmd = re.exec(message.text)
            console.log cmd
            if cmd?
                switch cmd[1]
                    when 'roll', 'r'
                        roll_die message, false, (msg)->
                            send_message socket, msg
                    when 'gmroll', 'gr'
                        if data.is_master
                            roll_die message, true, (msg)->
                                send_message socket, msg
                    when 'me'
                        player_event message, (msg)->
                            send_message socket, msg
                    when 'event'
                        if data.is_master
                            master_event message, (msg)->
                                send_message socket, msg
                    when 'as'
                        if data.is_master
                            master_as message, (msg)->
                                send_message socket, msg 
                    when 'help', 'h'
                        help message, data.is_master, (msg)->
                            send_message socket, msg
                    when 'kick'
                        if data.is_master
                            player = message.text.split(" ").slice(1)[0]
                            kick socket, message, player, (msg)->
                                send_message socket, msg
                    when 'stats'
                        player = message.text.split(" ").slice(1)[0]
                        show_stats message, player, (msg)->
                            send_message socket, msg
                    when 'pm', 'w'
                        player = message.text.split(" ").slice(1)[0]
                        pm message, player, socket, (msg)->
                            send_message socket, msg
            else            
                send_message socket, message
                        
send_message = (socket, message)->
    #console.log "send message", message
    socket.get "data", (err, data)->                        
        if data.is_master
            displayname = message.username
        else
            displayname = "<span class='you'>You</span>"
        socket.emit message.event_type,
            text: message.text
            username: displayname
            room: message.room
            timestamp: message.timestamp
            event_type: message.event_type
        
        unless message.allow_send
            return
        
        if message.out_of_history
            socket.broadcast.to(data.room.name).emit message.event_type, message
        else            
            history = new History
                room: data.room._id
                user: data.user._id
                timestamp: new Date()
                event_type: message.event_type
                text: message.text
                displayname: message.username

            history.save (err)->
                if err?
                    console.log err
                else
                    socket.broadcast.to(data.room.name).emit message.event_type, message
