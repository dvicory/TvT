CommonPlayer = require('../common/Player')
DynamicSprite = require('./DynamicSprite')

class LocalPlayer extends DynamicSprite
  constructor: (@world, args) ->
    args ?= {}

    args.src = 'img/textures/custom/tank_rogue.png'

    super @world, CommonPlayer, args

    @model.size = [124, 153]
    @model.maxVelocity = 150
    @model.maxAngularVelocity = Math.PI / 4

    @events.on 'keydown', @handleKeyDown
    @events.on 'keyup', @handleKeyUp

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
    @world.camera.lookAt(@position) if @world.camera?

module.exports = LocalPlayer
