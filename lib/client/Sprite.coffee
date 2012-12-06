WorldObject = require('../common/WorldObject')

# Sprite, the root class of all visuals in TvT.
#
# @copyright BZFX
# @author Daniel Vicory
class Sprite extends pulse.Sprite
  constructor: (@world, worldModel, args) ->
    throw TypeError('world is a required argument of sprite') unless @world instanceof require('./World')

    # call parent constructor, we'll get access to our parent's members now
    super args

    worldModel ?= WorldObject

    # support allowing model constructors or pre-constructed models
    if typeof worldModel is 'function'
      @model = new worldModel
    else if typeof worldModel is 'object'
      @model = worldModel

    Object.defineProperty @, 'position',
      get: ->
        x: ((@model.position[0] * @world.pixelsPerWorldUnit + (@model.position[0] > 0 ? 0.5 : -0.5)) << 0)
        y: ((@model.position[1] * @world.pixelsPerWorldUnit + (@model.position[1] > 0 ? 0.5 : -0.5)) << 0)

    Object.defineProperty @, 'size',
      get: ->
        width:  ((@model.size[0] * @world.pixelsPerWorldUnit + (@model.size[0] > 0 ? 0.5 : -0.5)) << 0)
        height: ((@model.size[1] * @world.pixelsPerWorldUnit + (@model.size[1] > 0 ? 0.5 : -0.5)) << 0)

    Object.defineProperty @, 'rotation',
      get: ->
        @model.rotation * (180 / Math.PI)

    # force sprite to be redrawn if window resizes
    # fixes bug of sprites not drawing unless moved after resize
    $(window).resize =>
      @updated = true

  draw: (ctx) ->
    if @world.camera?
      super ctx, @world.camera.transformView
    else
      super ctx

module.exports = Sprite
