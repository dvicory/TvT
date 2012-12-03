CommonPlayer = require('../common/Player')
DynamicSprite = require('./DynamicSprite')

class LocalPlayer extends DynamicSprite
  constructor: (@world, slot, team, callsign, tag, args) ->
    args ?= {}

    args.src = "img/textures/custom/tank_#{team.toLowerCase()}.png"

    super @world, CommonPlayer, args

    @model.slot = slot
    @model.team = team
    @model.callsign = callsign
    @model.tag = tag

    @model.size = [9.72, 12]
    @model.maxVelocity = 25
    @model.maxAngularVelocity = Math.PI / 2

    @events.on 'keydown', @handleKeyDown
    @events.on 'keyup', @handleKeyUp

    @lastUpdate = Date.now()

  handleKeyDown: (e) =>
    if e.key is 'W' # move forwards
      @model.velocityFactor = -1
    if e.key is 'S' # move backwards
      @model.velocityFactor = 1
    if e.key is 'A' # rotate left
      @model.angularVelocityFactor = -1
    if e.key is 'D' # rotate right
      @model.angularVelocityFactor = 1

    if @model.velocityFactor isnt 0
      @model.updateVelocity()

    if @model.angularVelocityFactor isnt 0
      @model.angularVelocity = @model.angularVelocityFactor * @model.maxAngularVelocity

    return

  handleKeyUp: (e) =>
    if e.key is 'W' or e.key is 'S' # stop going forwards or backwards 
      @model.velocityFactor = 0

    if e.key is 'A' or e.key is 'D' # stop rotating 
      @model.angularVelocityFactor = 0

    return

  update: (elapsedMS) ->
    super elapsedMS

    # send an update message every 20ms
    if (Date.now() + 20) > @lastUpdate
      @world.socket.emit 'update player', LocalPlayer.MessageUpdatePlayer(@model)

      @lastUpdate = Date.now()

    @world.camera.lookAt(@position) if @world.camera?

  @MessageUpdatePlayer: (player) ->
    position : player.position
    rotation : player.rotation

module.exports = LocalPlayer
