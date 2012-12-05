CommonPlayer = require('../common/Player')
DynamicSprite = require('./DynamicSprite')

class Player extends DynamicSprite
  constructor: (@world, slot, team, callsign, tag, args) ->
    args     ?= {}
    args.src ?= @world.assetManager.getAsset("tank_#{team.toLowerCase()}")

    super @world, CommonPlayer, args

    @model.size = [9.72, 12]
    @model.maxVelocity = 25
    @model.maxAngularVelocity = Math.PI / 2

    @model.slot = slot
    @model.team = team
    @model.callsign = callsign
    @model.tag = tag

    @world.socket.on 'update score', @handleScoreUpdate

  handleScoreUpdate: (updateScoreData) =>
    @model.wins   = updateScoreData.wins
    @model.losses = updateScoreData.losses

  @MessageUpdatePlayer: (player, includeVelocity, includeAngularVelocity) ->
    includeVelocity        ?= true
    includeAngularVelocity ?= true

    ret = {}

    ret.position = player.position
    ret.rotation = player.rotation

    ret.velocityFactor        = player.velocityFactor        if includeVelocity
    ret.angularVelocityFactor = player.angularVelocityFactor if includeAngularVelocity

    return ret

module.exports = Player
