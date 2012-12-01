DynamicWorldObject = require('../common/DynamicWorldObject')
StaticSprite = require('./StaticSprite')

# DynamicSprite, a sprite for visuals that move in-world.
#
# @copyright BZFX
# @author Daniel Vicory
class DynamicSprite extends StaticSprite
  constructor: (@world, args) ->
    # call parent constructor, we'll get access to our parent's members now
    super @world, args

    # TODO remove repeating ourselves (also similar in StaticSprite)
    @model = new DynamicWorldObject

    return

module.exports = DynamicSprite
