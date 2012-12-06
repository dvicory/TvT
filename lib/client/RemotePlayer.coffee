Player = require('./Player')

class RemotePlayer extends Player
  constructor: (@world, slot, team, callsign, tag, args) ->
    super @world, slot, team, callsign, tag, args

    @world.socket.on 'update player', @handleUpdatePlayer
    @world.socket.on 'player died', @handlePlayerDied
    @world.socket.on 'new shot', @handleNewShot

  handleUpdatePlayer: (updatePlayerData) =>
    return unless updatePlayerData.slot is @model.slot

    for key, val of updatePlayerData
      @model[key] = val if @model[key]?

  handleRemovePlayer: (removePlayerData) =>
    super removePlayerData

    return unless removePlayerData.slot is @model.slot

    @world.socket.removeListener 'update player', @handleUpdatePlayer
    @world.socket.removeListener 'remove player', @handleRemovePlayer

  handlePlayerDied: (playerDiedData) =>
    return unless playerDiedData.slot is @model.slot

    # is the killer the local player or someone else?
    if @world.localPlayer.model.slot is playerDiedData.killer
      killer = @world.localPlayer
    else
      killer = @world.players[playerDiedData.killer]

    # get the killer's shot
    shot = killer.shots[playerDiedData.shotSlot]

    @die(killer, shot)

  handleNewShot: (newShotData) =>
    return unless newShotData.slot is @model.slot
    return if @shots.indexOf(newShotData.slot) isnt -1

    @shoot(newShotData.shotSlot, newShotData.position, newShotData.rotation)

module.exports = RemotePlayer
