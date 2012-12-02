CommonPlayer = require('../common/Player')
StaticSprite = require('./StaticSprite')

class RemotePlayer extends StaticSprite
  constructor: (@world, slot, team, callsign, tag, args) ->
    args ?= {}

    args.src = "img/textures/custom/tank_#{team.toLowerCase()}.png"

    super @world, CommonPlayer, args

    @model.slot = slot
    @model.team = team
    @model.callsign = callsign
    @model.tag = tag

    @model.size = [124, 153]

    @world.socket.on 'update player', @handleUpdatePlayer
    @world.socket.on 'remove player', @handleRemovePlayer

  handleUpdatePlayer: (updatePlayerData) =>
    return unless updatePlayerData.slot is @model.slot

    @model.position = updatePlayerData.position
    @model.rotation = updatePlayerData.rotation

  handleRemovePlayer: (removePlayerData) =>
    return unless removePlayerData.slot is @model.slot

    @world.socket.removeListener 'update player', @handleUpdatePlayer
    @world.socket.removeListener 'remove player', @handleRemovePlayer

  @MessageUpdatePlayer: (player) ->
    position : player.position
    rotation : player.rotation

module.exports = RemotePlayer
