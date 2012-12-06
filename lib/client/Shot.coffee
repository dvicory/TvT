CommonShot = require('../common/Shot')
DynamicSprite = require('./DynamicSprite')

class Shot extends DynamicSprite
  constructor: (@world, @player, shotModel, args) ->
    args     ?= {}
    args.src ?= @world.assetManager.getAsset("#{@player.model.team.toLowerCase()}_bolt")

    super @world, shotModel, args

  update: (elapsedMS) ->
    super elapsedMS

    for mapObject in @world.mapObjects
      if mapObject.inCurrentBounds(@position.x, @position.y)
        # we're inside a map object, so we need to end
        @model.state = 'ended'
        @visible = false
        break

module.exports = Shot
