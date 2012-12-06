Player = require('./Player')

class LocalPlayer extends Player
  constructor: (@world, slot, team, callsign, tag, args) ->
    super @world, slot, team, callsign, tag, args

    @events.on 'keydown', @handleKeyDown
    @events.on 'keyup', @handleKeyUp

    @lastUpdate = Date.now()
    @lastUpdateDetails = {}

    @insideMapObject = false

  handleKeyDown: (e) =>
    lastVelocityFactor = @model.velocityFactor
    lastAngularVelocityFactor = @model.angularVelocityFactor

    if e.key is 'W' # move forwards
      @model.velocityFactor = 1
    if e.key is 'S' # move backwards
      @model.velocityFactor = -1
    if e.key is 'A' # rotate left
      @model.angularVelocityFactor = -1
    if e.key is 'D' # rotate right
      @model.angularVelocityFactor = 1

    # being inside a map object slows you down
    # TODO make this configurable
    if @insideMapObject
      @model.velocityFactor =  0.5        if e.key is 'W'
      @model.velocityFactor = -0.5        if e.key is 'S'
      @model.angularVelocityFactor = -0.5 if e.key is 'A'
      @model.angularVelocityFactor =  0.5 if e.key is 'D'

    # immediate send a player update since we began moving
    @sendPlayerUpdate(lastVelocityFactor isnt @model.velocityFactor, lastAngularVelocityFactor isnt @model.angularVelocityFactor)

    return

  handleKeyUp: (e) =>
    lastVelocityFactor = @model.velocityFactor
    lastAngularVelocityFactor = @model.angularVelocityFactor

    if e.key is 'W' or e.key is 'S' # stop going forwards or backwards 
      @model.velocityFactor = 0

    if e.key is 'A' or e.key is 'D' # stop rotating 
      @model.angularVelocityFactor = 0

    # immediately send an update since we stopped moving
    @sendPlayerUpdate(lastVelocityFactor isnt @model.velocityFactor, lastAngularVelocityFactor isnt @model.angularVelocityFactor)

    return

  update: (elapsedMS) ->
    super elapsedMS

    # being inside a map object slows you down
    # TODO make this configurable
    @insideMapObject = false
    for mapObject in @world.mapObjects
      if mapObject.inCurrentBounds(@position.x, @position.y)
        # we're inside a map object, so we can break out now
        @insideMapObject = true
        break

    # if we're inside one, we need to slow ourselves down accordingly
    if @insideMapObject
      @model.velocityFactor =  0.5        if @model.velocityFactor is  1
      @model.velocityFactor = -0.5        if @model.velocityFactor is -1
      @model.angularVelocityFactor = -0.5 if @model.angularVelocityFactor is -1
      @model.angularVelocityFactor =  0.5 if @model.angularVelocityFactor is  1
    # else if we're slowed down we should speed ourselves back up
    else
      @model.velocityFactor =  1        if @model.velocityFactor is  0.5
      @model.velocityFactor = -1        if @model.velocityFactor is -0.5
      @model.angularVelocityFactor = -1 if @model.angularVelocityFactor is -0.5
      @model.angularVelocityFactor =  1 if @model.angularVelocityFactor is  0.5

    lastVelocityFactor        = @lastUpdateDetails.velocityFactor
    lastAngularVelocityFactor = @lastUpdateDetails.angularVelocityFactor

    # has our velocity factors changed?
    if lastVelocityFactor isnt @model.velocityFactor
      sendVelocityFactor = true
    if lastAngularVelocityFactor isnt @model.angularVelocityFactor
      sendAngularVelocityFactor = true

    # if so, we should immediately send an update
    if sendVelocityFactor or sendAngularVelocityFactor
      @sendPlayerUpdate(sendVelocityFactor, sendAngularVelocityFactor)

    # we'll send an update no later than every 50ms
    if (@lastUpdate + 50) <= Date.now()
      @sendPlayerUpdate(true, true)

    @world.camera.lookAt(@position) if @world.camera?

  sendPlayerUpdate: (includeVelocity, includeAngularVelocity) ->
    @lastUpdateDetails = Player.MessageUpdatePlayer(@model, includeVelocity, includeAngularVelocity)
    @world.socket.emit 'update player', @lastUpdateDetails

    @lastUpdate = Date.now()

module.exports = LocalPlayer
