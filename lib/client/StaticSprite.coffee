StaticWorldObject = require('../common/StaticWorldObject')

# StaticSprite, a root class of all visuals in TvT.
#
# @copyright BZFX
# @author Daniel Vicory
class StaticSprite extends pulse.Sprite
  constructor: (@world, args) ->
    throw TypeError('world is a required argument of sprite') unless @world instanceof require('./World')

    # call parent constructor, we'll get access to our parent's members now
    super args

    @model = new StaticWorldObject

    # force sprite to be redrawn if window resizes
    # fixes bug of sprites not drawing unless moved after resize
    $(window).resize =>
      @updated = true

  update: (elapsedMS) ->
    @model.update elapsedMS

    @position =
      x: @model.position[0]
      y: @model.position[1]

    @size =
      width: @model.size[0]
      height: @model.size[1]

    @rotation = @model.rotation * (180 / Math.PI)

    super elapsedMS

  draw: (ctx) ->
    if @world.camera?
      super ctx, @world.camera.transformView
    else
      super ctx

module.exports = StaticSprite
