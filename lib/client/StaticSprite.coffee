StaticWorldObject = require('../common/StaticWorldObject')
Sprite = require('./Sprite')

# StaticSprite, a sprite for visuals that are static in-world.
#
# @copyright BZFX
# @author Daniel Vicory
class StaticSprite extends Sprite
  constructor: (@world, worldModel, args) ->
    worldModel ?= StaticWorldObject

    # call parent constructor, we'll get access to our parent's members now
    super @world, worldModel, args

module.exports = StaticSprite
