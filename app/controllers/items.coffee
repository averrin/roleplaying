mongoose = require 'mongoose'
_ = require 'underscore'

Item = mongoose.model 'Item'

#
# New item form
#
exports.new = (req, res) ->
  res.render 'items/new',
    item: new Item({})
  return

#
# Create new item
#
exports.create = (req, res) ->
  item = new Item req.body
  item.save (err) ->
    if err
      res.render 'items/new',
        errors: err.errors
        item: item
    res.redirect '/items'
    return
  return

exports.show = (req, res) ->
  undefined

#
# Item edit form
#
exports.edit = (req, res) ->
  item = req.item
  res.render 'items/edit',
    item:item
  return

#
# Update item
#
exports.update = (req, res) ->
  item = req.item
  
  item = _.extend item, req.body
  item.save (err) ->
    if err
      res.render 'items/edit',
        item:item
        errors: err.errors
    else
      req.flash 'notice', item.title + ' was successfully updated.'
      res.redirect '/items'
    return
  return

#
# Delete item
#
exports.destroy = (req, res) ->
  item = req.item
  item.remove (err) ->
    req.flash 'notice', item.title + ' was successfully deleted.'
    res.redirect '/items'

#
# Manage items
#
exports.manage = (req, res) ->
  Item.list (err, items_list) ->
    res.render 'items/manage',
      all_items: items_list
      message: req.flash 'notice'
    return

#
# Items index
#
exports.index = (req, res) ->
  Item.list (err, items_list) ->
    res.render 'items/index',
      all_items: items_list
  return

#
# Find item by ID
#
exports.item = (req, res, next, id) ->
  Item.findById(id).exec (err, item) ->
    return next err if err
    return next new Error 'Failed to load item' if not item
      
    req.item = item
    next()
    return
  return
