class Player extends pulse.Sprite
  constructor: (args) ->
    args ?= {}
    
    args.src = 'img/textures/tank_rogue.png';
    
    super args

    @worldInfo =
      position:
        x: 0
        y: 0
      rotation: 0
      velocity:
        x: 0
        y: 0
      velocityFactor: 0
      angularVelocity: 0
      angularVelocityFactor: 0

    @size =
      width: 124
      height: 153

    @maxVelocity = 100

    @maxAngularVelocity = Math.PI / 8

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
      @worldInfo.velocity =
        x: Math.cos((@worldInfo.rotation + (Math.PI / 2)))
        y: Math.sin((@worldInfo.rotation + (Math.PI / 2)))

      @worldInfo.velocity.x *= @worldInfo.velocityFactor
      @worldInfo.velocity.y *= @worldInfo.velocityFactor

      @worldInfo.velocity.x *= @maxVelocity
      @worldInfo.velocity.y *= @maxVelocity

    if @worldInfo.angularVelocityFactor isnt 0
      @worldInfo.angularVelocity = @maxAngularVelocity
      @worldInfo.angularVelocity *= @worldInfo.angularVelocityFactor

    return

  handleKeyUp: (e) =>
    if e.key is 'W' or e.key is 'S' # stop going forwards or backwards 
      @worldInfo.velocity.x = 0
      @worldInfo.velocity.y = 0
      @worldInfo.velocityFactor = 0

    if e.key is 'A' or e.key is 'D' # stop rotating 
      @worldInfo.angularVelocity = 0
      @worldInfo.angularVelocityFactor = 0

    return

  update: (elapsedMS) ->
    if @worldInfo.velocityFactor isnt 0
      @worldInfo.velocity =
        x: Math.cos((@worldInfo.rotation + (Math.PI / 2)))
        y: Math.sin((@worldInfo.rotation + (Math.PI / 2)))

      @worldInfo.velocity.x *= @worldInfo.velocityFactor
      @worldInfo.velocity.y *= @worldInfo.velocityFactor

      @worldInfo.velocity.x *= @maxVelocity
      @worldInfo.velocity.y *= @maxVelocity

      @worldInfo.position.x += @worldInfo.velocity.x * (elapsedMS / 1000)
      @worldInfo.position.y += @worldInfo.velocity.y * (elapsedMS / 1000)

      @position = @worldInfo.position

    if @worldInfo.angularVelocityFactor isnt 0
      @worldInfo.rotation += @worldInfo.angularVelocity * (elapsedMS / 1000)

      @rotation = @worldInfo.rotation * (180 / Math.PI)
    
    super elapsedMS

module.exports = Player