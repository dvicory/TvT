CommonPlayer = require('../common/Player')
DynamicSprite = require('./DynamicSprite')

class Player extends DynamicSprite
  constructor: (@world, slot, team, callsign, tag, args) ->
    args     ?= {}
    args.src ?= @world.assetManager.getAsset("tank_#{team.toLowerCase()}")

    super @world, CommonPlayer, args

    @model.slot = slot
    @model.team = team
    @model.callsign = callsign
    @model.tag = tag

    @model.size = [9.72, 12]

    @world.socket.on 'update score', @handleScoreUpdate

  handleScoreUpdate: (updateScoreData) =>
    @model.wins   = updateScoreData.wins
    @model.losses = updateScoreData.losses

  @MessageUpdatePlayer: (player) ->
    position : player.position
    rotation : player.rotation

module.exports = Player
