Player = require('./Player')
Shot = require('./Shot')

class LocalPlayer extends Player
  constructor: (@world, slot, team, callsign, tag, args) ->
    super @world, slot, team, callsign, tag, args

    @events.on 'keydown', @handleKeyDown
    @events.on 'keyup', @handleKeyUp

    @maxShots = 5
    @lastUpdate = Date.now()
    @lastUpdateDetails = {}

    @insideMapObject = false

    @model.on 'killed', @updateScore
    @model.on 'died', @updateScore

  updateScore: =>
    $('#hud #playerScore').text("#{@model.callsign}: #{@model.score}")

  handleKeyDown: (e) =>
    return unless @model.state is 'alive'

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
    if ['W', 'A', 'S', 'D'].indexOf(e.key) isnt -1
      @sendPlayerUpdate(lastVelocityFactor isnt @model.velocityFactor, lastAngularVelocityFactor isnt @model.angularVelocityFactor)

    # player pressed enter, let's shoot
    if e.keyCode is 13
      @shoot() unless @insideMapObject

    return

  handleKeyUp: (e) =>
    return unless @model.state is 'alive'

    lastVelocityFactor = @model.velocityFactor
    lastAngularVelocityFactor = @model.angularVelocityFactor

    if e.key is 'W' or e.key is 'S' # stop going forwards or backwards 
      @model.velocityFactor = 0

    if e.key is 'A' or e.key is 'D' # stop rotating 
      @model.angularVelocityFactor = 0

    # immediately send an update since we stopped moving
    if ['W', 'A', 'S', 'D'].indexOf(e.key) isnt -1
      @sendPlayerUpdate(lastVelocityFactor isnt @model.velocityFactor, lastAngularVelocityFactor isnt @model.angularVelocityFactor)

    return

  shoot: ->
    return if @shots.length >= @maxShots

    shot = super

    @world.socket.emit 'new shot', Shot.MessageNewShot(shot.model)

  die: (killer, shot) ->
    super killer, shot

    @world.socket.emit 'player died', Player.MessagePlayerDied(killer.model, shot.model)

  update: (elapsedMS) ->
    super elapsedMS

    # being inside a map object slows you down
    # TODO make this configurable
    if @model.state is 'alive'
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

      # see if anyone hit us
      for slot, player of @world.players
        continue if @model.team is player.model.team

        hit = false

        for shot in player.shots
          if @inCurrentBounds(shot.position.x, shot.position.y)
            @die(shot.player, shot)
            hit = true
            break

        break if hit

    @world.camera.lookAt(@position) if @world.camera?

  sendPlayerUpdate: (includeVelocity, includeAngularVelocity) ->
    @lastUpdateDetails = Player.MessageUpdatePlayer(@model, includeVelocity, includeAngularVelocity)
    @world.socket.emit 'update player', @lastUpdateDetails

    @lastUpdate = Date.now()

module.exports = LocalPlayer
