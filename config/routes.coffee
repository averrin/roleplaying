module.exports = (app, config, passport, auth) ->
  
  # Include controllers
  fs = require 'fs'
  controllers_path = config.root + '/app/controllers'
  fs.readdirSync(controllers_path).forEach (file) ->
    @[file.slice(0, -7)] = require "#{controllers_path}/#{file}"


  # User routes
  app.get '/login', users.login

  app.post '/login', passport.authenticate('local',
    failureRedirect: '/login'
    failureFlash: true),
    (req, res) ->
      res.redirect '/'
      return

  app.get '/logout', users.logout
  
  app.get '/users', auth.requiresLogin, users.index
  app.get '/users/new', users.new
  app.post '/users', users.create
  app.get '/users/:userId/edit', auth.requiresLogin, users.edit
  app.put '/users/:userId', auth.requiresLogin, users.update
  app.get '/users/:userId/destroy', auth.requiresLogin, users.destroy

  app.param 'userId', users.user

  # room routes
  app.get '/', rooms.index
  app.get '/rooms', auth.requiresLogin, rooms.manage
  app.get '/rooms/new', auth.requiresLogin, rooms.new
  app.get '/rooms/:roomName', auth.requiresLogin, rooms.main
  app.post '/rooms', auth.requiresLogin, rooms.create
  app.get '/rooms/:roomId/edit', auth.requiresLogin, rooms.edit
  app.put '/rooms/:roomId', auth.requiresLogin, rooms.update
  app.get '/rooms/:roomId/destroy', auth.requiresLogin, rooms.destroy

  app.param 'roomId', rooms.room
  app.param 'roomName', rooms.roomName


  # Play room
  #app.get '/rooms', auth.requiresLogin, rooms.index
  #app.get '/room/:roomId', auth.requiresLogin, rooms.main
  #
  #app.param 'roomId', rooms.room

  return
