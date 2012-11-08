# Sprite, a root class of all visuals in TvT.
#
# @copyright BZFX
# @author Daniel Vicory
class Sprite extends pulse.Sprite
  constructor: (args) ->
    args ?= {}

    @world = args.world if args.world?

    # call parent constructor, we'll get access to our parent's members now
    super args

    @worldInfo =
      position:
        x: 0
        y: 0
      rotation: 0
      velocity:
        x: 0
        y: 0
      maxVelocity: 0
      velocityFactor: 0
      angularVelocity: 0
      maxAngularVelocity: 0
      angularVelocityFactor: 0

    # force sprite to be redrawn if window resizes
    # fixes bug of sprites not drawing unless moved after resize
    $(window).resize =>
      @updated = true

  update: (elapsedMS) ->
    if @worldInfo.angularVelocityFactor isnt 0 or @worldInfo.velocityFactor isnt 0
      @updateVelocity()

    if @worldInfo.angularVelocityFactor isnt 0
      @worldInfo.rotation += @worldInfo.angularVelocity * (elapsedMS / 1000)

      @rotation = @worldInfo.rotation * (180 / Math.PI)

    if @worldInfo.velocityFactor isnt 0
      @worldInfo.position.x += @worldInfo.velocity.x * (elapsedMS / 1000)
      @worldInfo.position.y += @worldInfo.velocity.y * (elapsedMS / 1000)

      @position = @worldInfo.position

    super elapsedMS

  draw: (ctx) ->
    # skip if we're not loaded
    if @texture.percentLoaded < 100 or @size.width is 0 or @size.height is 0
      return

    # Only redraw this canvas if the texture coords or texture changed.
    if @textureUpdated
      # Clear my canvas
      @_private.context.clearRect(0, 0, @canvas.width, @canvas.height)

      slice = @getCurrentFrame()

      # Draws the texture to this visual's canvas
      @_private.context.drawImage(slice, 0, 0, @size.width, @size.height)

      @textureUpdated = false

    if @canvas.width is 0 or @canvas.height is 0
      return

    ctx.save()

    # apply the alpha for this visual node
    ctx.globalAlpha = @alpha / 100

    @world.camera.transformView(ctx) if @world.camera?

    # apply the rotation if needed
    if @rotation isnt 0
      rotationX = @positionTopLeft.x + @size.width * Math.abs(@scale.x) / 2
      rotationY = @positionTopLeft.y + @size.height * Math.abs(@scale.y) / 2

      ctx.translate(rotationX, rotationY)
      ctx.rotate((Math.PI * (@rotation % 360)) / 180)
      ctx.translate(-rotationX, -rotationY)

    # apply the scale
    ctx.scale(@scale.x, @scale.y)

    px = @positionTopLeft.x / @scale.x
    py = @positionTopLeft.y / @scale.y

    if @shadowEnabled
      ctx.shadowOffsetX = @shadowOffsetX
      ctx.shadowOffsetY = @shadowOffsetY
      ctx.shadowBlur = @shadowBlur
      ctx.shadowColor = @shadowColor

    # draw the canvas
    ctx.drawImage(@canvas, px, py)

    ctx.restore()

    @updated = false

  updateVelocity: ->
    @worldInfo.velocity.x = Math.cos((@worldInfo.rotation + (Math.PI / 2))) * @worldInfo.velocityFactor * @worldInfo.maxVelocity
    @worldInfo.velocity.y = Math.sin((@worldInfo.rotation + (Math.PI / 2))) * @worldInfo.velocityFactor * @worldInfo.maxVelocity
    return

module.exports = Sprite