CommonPlayer = require('../common/Player')

class Player extends CommonPlayer
  constructor: (@world, @socket, slot, team, callsign, tag) ->
    throw new TypeError('world must be an instance of a world')             unless @world  instanceof require('./World')
    throw new TypeError('socket must be an instance of a socket.io socket') unless @socket instanceof require('socket.io').Socket

    super slot, team, callsign, tag

    @socket.on 'update player', @handlePlayerUpdate

  update: (elapsedMS) ->
    super elapsedMS

  spawn: (position, rotation) ->
    super position, rotation

    # tell our client that they're spawning
    @socket.emit 'self spawn', Player.MessageSpawnPlayer(@)

    # tell everyone else that we spawned
    @socket.broadcast.emit 'spawn', Player.MessageSpawnPlayer(@)

  die: (killerData) =>
    throw new Error('not yet implemented')

  kill: (killee) ->
    throw new Error('not yet implemented')

  handlePlayerUpdate: (updateData) =>
    if not updateData.position instanceof Array or updateData.position.length isnt 2 or not updateData.rotation?
      throw new TypeError("received malformed player update: #{updateData}")

    @position = updateData.position
    @rotation = updateData.rotation

    # broadcast player update to everyone else
    @socket.broadcast.emit 'update player', @MessageUpdatePlayer(@)

  @MessageNewPlayer: (player) ->
    slot     : player.slot
    callsign : player.callsign
    team     : player.team
    tag      : player.tag

  @MessageRemovePlayer: (player) ->
    slot : player.slot

  @MessageUpdatePlayer: (player) ->
    slot     : player.slot
    position : player.position
    rotation : player.rotation

  @MessageSpawnPlayer: (player) ->
    slot     : player.slot
    position : player.position
    rotation : player.rotation

  @MessageUpdateScore: (player) ->
    slot   : player.slot
    wins   : player.wins
    losses : player.losses

module.exports = Player