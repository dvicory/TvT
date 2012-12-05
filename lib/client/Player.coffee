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

  @MessageUpdatePlayer: (player) ->
    position : player.position
    rotation : player.rotation

module.exports = Player
