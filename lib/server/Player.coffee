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
    if not updateData.position instanceof Array or updateData.position.length isnt 2
      console.error 'received malformed player update, bogus position vector', updateData
      return

    checkNumbers = ['rotation', 'velocityFactor', 'angularVelocityFactor']

    for number in checkNumbers
      # make sure we have it available first, but rotation is always required
      if number isnt 'rotation' and not updateData[number]?
        continue

      if typeof updateData[number] isnt 'number'
        console.error "received malformed player update, bogus #{number} number", updateData
        return

    validUpdates = ['position', 'rotation', 'velocityFactor', 'angularVelocityFactor']

    for key, val of updateData
      @[key] = val if validUpdates.indexOf(key) isnt -1

    # broadcast player update to everyone else
    @socket.volatile.broadcast.emit 'update player', Player.MessageUpdatePlayer(@, updateData.velocityFactor?, updateData.angularVelocityFactor?)

  @MessageNewPlayer: (player) ->
    slot     : player.slot
    callsign : player.callsign
    team     : player.team
    tag      : player.tag

  @MessageRemovePlayer: (player) ->
    slot : player.slot

  @MessageUpdatePlayer: (player, includeVelocity, includeAngularVelocity) ->
    includeVelocity        ?= true
    includeAngularVelocity ?= true

    ret = {}

    ret.slot     = player.slot
    ret.position = player.position
    ret.rotation = player.rotation

    ret.velocityFactor        = player.velocityFactor        if includeVelocity
    ret.angularVelocityFactor = player.angularVelocityFactor if includeAngularVelocity

    return ret

  @MessageSpawnPlayer: (player) ->
    slot     : player.slot
    position : player.position
    rotation : player.rotation

  @MessageUpdateScore: (player) ->
    slot   : player.slot
    wins   : player.wins
    losses : player.losses

module.exports = Player
