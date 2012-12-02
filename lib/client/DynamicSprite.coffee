DynamicWorldObject = require('../common/DynamicWorldObject')
StaticSprite = require('./StaticSprite')

# DynamicSprite, a sprite for visuals that move in-world.
#
# @copyright BZFX
# @author Daniel Vicory
class DynamicSprite extends StaticSprite
  constructor: (@world, worldModel, args) ->
    worldModel ?= DynamicWorldObject

    # call parent constructor, we'll get access to our parent's members now
    super @world, worldModel, args

  update: (elapsedMS) ->
    @model.update elapsedMS
    super elapsedMS

module.exports = DynamicSprite
