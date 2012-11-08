Sprite = require('./Sprite')

class Player extends Sprite
  constructor: (args) ->
    args ?= {}
    
    args.src = 'img/textures/custom/tank_rogue.png';
    
    super args

    @size =
      width: 124
      height: 153

    @worldInfo.maxVelocity = 150

    @worldInfo.maxAngularVelocity = Math.PI / 4

    @events.bind 'keydown', @handleKeyDown
    @events.bind 'keyup', @handleKeyUp
  
  handleKeyDown: (e) =>
    if e.key is 'W' # move forwards
      @worldInfo.velocityFactor = -1
    if e.key is 'S' # move backwards
      @worldInfo.velocityFactor = 1
    if e.key is 'A' # rotate left
      @worldInfo.angularVelocityFactor = -1
    if e.key is 'D' # rotate right
      @worldInfo.angularVelocityFactor = 1

    if @worldInfo.velocityFactor isnt 0
      @updateVelocity()

    if @worldInfo.angularVelocityFactor isnt 0
      @worldInfo.angularVelocity = @worldInfo.angularVelocityFactor * @worldInfo.maxAngularVelocity

    return

  handleKeyUp: (e) =>
    if e.key is 'W' or e.key is 'S' # stop going forwards or backwards 
      @worldInfo.velocityFactor = 0

    if e.key is 'A' or e.key is 'D' # stop rotating 
      @worldInfo.angularVelocityFactor = 0

    return

  update: (elapsedMS) ->
    super elapsedMS
    @world.camera.lookAt(@position) if @world.camera?

module.exports = Player