# Sprite, a root class of all visuals in TvT.
#
# @copyright BZFX
# @author Daniel Vicory
class Sprite extends pulse.Sprite
  worldInfo:
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

  constructor: (args) ->
    args ?= {}

    # call parent constructor, we'll get access to our parent's members now
    super args

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

  updateVelocity: ->
    @worldInfo.velocity.x = Math.cos((@worldInfo.rotation + (Math.PI / 2))) * @worldInfo.velocityFactor * @worldInfo.maxVelocity
    @worldInfo.velocity.y = Math.sin((@worldInfo.rotation + (Math.PI / 2))) * @worldInfo.velocityFactor * @worldInfo.maxVelocity
    return

module.exports = Sprite