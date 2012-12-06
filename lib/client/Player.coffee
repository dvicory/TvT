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

    @world.socket.on 'update score', @handleScoreUpdate

  handleScoreUpdate: (updateScoreData) =>
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
        @model.endShot(@shots[i].model)

        @shots[i] = null
        @shots.splice(i, 1)

        @world.worldLayer.removeNode(endedShot)

        break

      i++

  @MessageUpdatePlayer: (player, includeVelocity, includeAngularVelocity) ->
    includeVelocity        ?= true
    includeAngularVelocity ?= true

    ret = {}

    ret.position = player.position
    ret.rotation = player.rotation

    ret.velocityFactor        = player.velocityFactor        if includeVelocity
    ret.angularVelocityFactor = player.angularVelocityFactor if includeAngularVelocity

    return ret

  @MessageNewShot: (shot) ->
    shotSlot : shot.slot
    position : shot.initialPosition
    rotation : shot.rotation

module.exports = Player
