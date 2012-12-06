CommonPlayer = require('../common/Player')

class Player extends CommonPlayer
  constructor: (@world, @socket, slot, team, callsign, tag) ->
    throw new TypeError('world must be an instance of a world')             unless @world  instanceof require('./World')
    throw new TypeError('socket must be an instance of a socket.io socket') unless @socket instanceof require('socket.io').Socket

    super slot, team, callsign, tag

    @socket.on 'update player', @handlePlayerUpdate
    @socket.on 'player died', @handlePlayerDied
    @socket.on 'new shot', @handleNewShot

  update: (elapsedMS) ->
    super elapsedMS

  spawn: (position, rotation) ->
    random = (m, n) ->
      Math.floor(Math.random() * (n-m+1)) + m

    position ?= [
      random(-@world.mapSize / 2, @world.mapSize / 2)
      random(-@world.mapSize / 2, @world.mapSize / 2)
    ]

    super position, rotation

    # tell our client that they're spawning
    @socket.emit 'spawn player', Player.MessageSpawnPlayer(@)

    # tell everyone else that we spawned
    @socket.broadcast.emit 'spawn player', Player.MessageSpawnPlayer(@)

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

  handlePlayerDied: (playerDiedData) =>
    if typeof playerDiedData.killer isnt 'string'
      console.error "received malformed player died, bogus #{playerDiedData.killer} killer", playerDiedData
      return

    if typeof playerDiedData.shotSlot isnt 'number'
      console.error "received malformed player died, bogus #{playerDiedData.shotSlot} shot slot", playerDiedData
      return

    killer = @world.players[playerDiedData.killer]

    # update models
    @die()
    killer.kill()

    # broadcast player death to everyone else
    @socket.broadcast.emit 'player died', Player.MessagePlayerDied(@, playerDiedData)

    # update scores of both killer and killee
    @socket.emit 'update score', Player.MessageUpdateScore(@)
    @socket.broadcast.emit 'update score', Player.MessageUpdateScore(@)

    @socket.emit 'update score', Player.MessageUpdateScore(killer)
    @socket.broadcast.emit 'update score', Player.MessageUpdateScore(killer)

    # spawn player
    @spawn(null, 0)

  handleNewShot: (newShotData) =>
    if not newShotData.position instanceof Array or newShotData.position.length isnt 2
      console.error 'received malformed new shot, bogus position vector', newShotData
      return

    if typeof newShotData.rotation isnt 'number'
      console.error "received malformed new shot, bogus #{newShotData.rotation} rotation", newShotData
      return

    # broadcast new shot to everyone else
    @socket.broadcast.emit 'new shot', Player.MessageNewShot(@, newShotData)

  @MessageNewPlayer: (player) ->
    slot     : player.slot
    callsign : player.callsign
    team     : player.team
    tag      : player.tag

  @MessageRemovePlayer: (player) ->
    slot : player.slot

  @MessagePlayerDied: (player, killer) ->
    slot     : player.slot
    killer   : killer.killer
    shotSlot : killer.shotSlot

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

  @MessageNewShot: (player, shot) ->
    slot     : player.slot
    shotSlot : shot.slot
    position : shot.initialPosition
    rotation : shot.rotation

  @MessageUpdateScore: (player) ->
    slot   : player.slot
    wins   : player.wins
    losses : player.losses

module.exports = Player
