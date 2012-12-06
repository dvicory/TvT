CommonPlayer = require('../common/Player')

DynamicSprite = require('./DynamicSprite')
Shot = require('./Shot')

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

    @shots = []

    @world.socket.on 'remove player', @handleRemovePlayer
    @world.socket.on 'spawn player', @handleSpawnPlayer
    @world.socket.on 'update score', @handleScoreUpdate

  handleRemovePlayer: (removePlayerData) =>
    return unless removePlayerData.slot is @model.slot

    @world.socket.removeListener 'remove player', @handleRemovePlayer
    @world.socket.removeListener 'spawn player', @handleSpawnPlayer
    @world.socket.removeListener 'update score', @handleScoreUpdate

  handleSpawnPlayer: (spawnPlayerData) =>
    return unless spawnPlayerData.slot is @model.slot    

    @model.spawn(spawnPlayerData.position, spawnPlayerData.rotation)
    @visible = true

  handleScoreUpdate: (updateScoreData) =>
    return unless updateScoreData.slot is @model.slot

    @model.wins   = updateScoreData.wins
    @model.losses = updateScoreData.losses

  update: (elapsedMS) ->
    super elapsedMS

    # see if any of our shots ended
    i = @shots.length
    while (i--)
      if @shots[i].model.state is 'ended'
        @endShot(@shots[i])

  shoot: (slot, initialPosition, rotation) ->
    shotModel = @model.shoot(slot, initialPosition, rotation)

    shot = new Shot(@world, @, shotModel, initialPosition, rotation)

    @shots.push(shot)

    @world.worldLayer.addNode shot

    return shot

  endShot: (endedShot) ->
    i = 0
    for shot in @shots
      if shot is endedShot
        shot.end()

        @model.endShot(@shots[i].model)

        @shots[i] = null
        @shots.splice(i, 1)

        @world.worldLayer.removeNode(endedShot)

        break

      i++

  die: (killer, shot) ->
    # tell the model we've died
    @model.die(killer.model, shot.model)

    # give the killer a kill
    killer.model.kill(@model, shot.model)

    # end the killer's shot
    killer.endShot(shot)

    # we are no longer visible
    @visible = false

    # notify score in console
    text = $("<p><span class=\"#{killer.model.team}\">#{killer.model.callsign}</span> killed <span class=\"#{@model.team}\">#{@model.callsign}</span>.</p>")
    hud = $('#hud #console')

    hud.append(text)
    hud.scrollTop(hud[0].scrollHeight)

  @MessageUpdatePlayer: (player, includeVelocity, includeAngularVelocity) ->
    includeVelocity        ?= true
    includeAngularVelocity ?= true

    ret = {}

    ret.position = player.position
    ret.rotation = player.rotation

    ret.velocityFactor        = player.velocityFactor        if includeVelocity
    ret.angularVelocityFactor = player.angularVelocityFactor if includeAngularVelocity

    return ret

  @MessagePlayerDied: (killer, shot) ->
    killer   : killer.slot
    shotSlot : shot.slot

module.exports = Player
