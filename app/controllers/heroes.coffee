mongoose = require 'mongoose'
_ = require 'underscore'

Hero = mongoose.model 'Hero'
User = mongoose.model 'User'
Room = mongoose.model 'Room'

#
# New Hero form
#
exports.new = (req, res) ->
  res.render 'heroes/new',
    hero: new Hero({})
  return

#
# Create new Hero
#
exports.create = (req, res) ->
  hero = new Hero req.body
  hero.layout =
    chat_widget:
        col: 1
        row: 2
        size_x: 4
        size_y: 4
    list_widget:
        col: 5
        row: 1
        size_x: 2
        size_y: 2
    notes_widget:
        col: 5
        row: 3
        size_x: 2
        size_y: 2
    hero_widget:
        col: 7
        row: 1
        size_x: 2
        size_y: 2
    status_widget:
        col: 1
        row: 1
        size_x: 4
        size_y: 1
    inventory_widget:
        col: 7
        row: 3
        size_x: 2
        size_y: 2
    master_widget:
        col: 11
        row: 3
        size_x: 2
        size_y: 2
  hero.save (err) ->
    if err
      res.render 'heroes/new',
        errors: err.errors
        hero: hero
    Room.findById(hero.room).exec (err, room)->
        res.redirect '/rooms/' + room.name
    return
  return

exports.show = (req, res) ->
  undefined

#
# Hero edit form
#
exports.edit = (req, res) ->
  hero = req.hero
  console.log hero
  res.render 'heroes/edit',
    hero:hero
  return

#
# Update Hero
#
exports.update = (req, res) ->
  hero = req.hero
  hero = _.extend hero, req.body
  hero.save (err) ->
    if err
      res.render 'heroes/edit',
        hero:hero
        errors: err.errors
    else
      req.flash 'notice', hero.title + ' was successfully updated.'
      res.redirect '/heroes'
    return
  return

#
# Delete Hero
#
exports.destroy = (req, res) ->
  hero = req.hero
  hero.remove (err) ->
    req.flash 'notice', hero.title + ' was successfully deleted.'
    res.redirect '/heroes'

#
# Manage heroes
#
exports.manage = (req, res) ->
  console.log req.user
  Room.find(master: req.user._id).exec (err, my_rooms)->
      my_rooms = my_rooms.map (r)->
        return r._id
      Hero.find().or({room: {$in: my_rooms}}, {user: req.user._id})
        .populate("user room")
        .exec (err, heroes_list) ->
            res.render 'heroes/manage',
              all_heroes: heroes_list
              message: req.flash 'notice'
            return

#
# heroes index
#
exports.index = (req, res) ->
  Hero.list (err, heroes_list) ->
    res.render 'heroes/index',
      all_heroes: heroes_list
  return

#
# Find Hero by ID
#
exports.hero = (req, res, next, id) ->
  Hero.findById(id).exec (err, hero) ->
    return next err if err
    return next new Error 'Failed to load Hero' if not hero
      
    req.hero = hero
    next()
    return
  return
