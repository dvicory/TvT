glmatrix = require('../../vendor/gl-matrix/gl-matrix')
glmatrix.glMatrixArrayType = glmatrix.MatrixArray = glmatrix.setMatrixArrayType(Array)

StaticWorldObject = require('./StaticWorldObject')

class DynamicWorldObject extends StaticWorldObject
  constructor: (type, @position, @size, @rotation, @velocity, @maxVelocity, @angularVelocity, @maxAngularVelocity) ->
    type ?= 'DynamicWorldObject'
    super type

    @velocity        = glmatrix.vec2.create() unless @velocity instanceof Array and @velocity.length is 2
    @maxVelocity    ?= 0
    @velocityFactor  = 0

    @angularVelocity       ?= 0
    @maxAngularVelocity    ?= 0
    @angularVelocityFactor  = 0

  move: (velocityFactor) ->
    @velocityFactor = velocityFactor

  rotate: (angularVelocityFactor) ->
    @angularVelocityFactor = angularVelocityFactor

  update: (elapsedMS) ->
    # update rotation?
    if @angularVelocityFactor isnt 0
      @angularVelocity = @maxAngularVelocity * @angularVelocityFactor
      @rotation += @angularVelocity * (elapsedMS / 1000)

      # wrap the rotation between -pi and pi
      if @rotation > Math.PI
        @rotation = @rotation - 2 * Math.PI
      if @rotation < -Math.PI
        @rotation = 2 * Math.PI + @rotation

      @emit 'update.rotation', @

    # if a velocity is still being applied, be sure to update its components (in case of changing rotation)
    if @angularVelocityFactor isnt 0 or @velocityFactor isnt 0
      @updateVelocity()

    # update position?
    if @velocityFactor isnt 0
      @position[0] += @velocity[0] * (elapsedMS / 1000)
      @position[1] += @velocity[1] * (elapsedMS / 1000)

      @emit 'update.position', @

  updateVelocity: ->
    @velocity[0] = Math.cos((@rotation - (Math.PI / 2))) * @velocityFactor * @maxVelocity
    @velocity[1] = Math.sin((@rotation - (Math.PI / 2))) * @velocityFactor * @maxVelocity
    @emit 'update.velocity', @
    return

module.exports = DynamicWorldObject
