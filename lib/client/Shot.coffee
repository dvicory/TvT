CommonShot = require('../common/Shot')
DynamicSprite = require('./DynamicSprite')

class Shot extends DynamicSprite
  constructor: (@world, @player, shotModel, args) ->
    args     ?= {}
    args.src ?= @world.assetManager.getAsset("#{@player.model.team.toLowerCase()}_bolt")

    super @world, shotModel, args

  end: ->
    @model.end()
    @visible = false

  update: (elapsedMS) ->
    super elapsedMS

    return if @model.state is 'ended'

    for mapObject in @world.mapObjects
      if mapObject.inCurrentBounds(@position.x, @position.y)
        # we're inside a map object, so we need to end
        @end()
        break

  @MessageNewShot: (shot) ->
    shotSlot : shot.slot
    position : shot.initialPosition
    rotation : shot.rotation

module.exports = Shot
