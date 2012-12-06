glmatrix = require('../../vendor/gl-matrix/gl-matrix')
glmatrix.glMatrixArrayType = glmatrix.MatrixArray = glmatrix.setMatrixArrayType(Array)

DynamicWorldObject = require('./DynamicWorldObject')

class Shot extends DynamicWorldObject
  constructor: (@slot, @player, initialPosition, rotation) ->
    super 'Shot'

    Object.defineProperty @, 'state',
      enumerable: false
      writable: true
      value: 'active'

    # get initial position
    @initialPosition = [
      (@player.size[1] / 2) * Math.cos(@player.rotation - Math.PI / 2)
      (@player.size[1] / 2) * Math.sin(@player.rotation - Math.PI / 2)
    ]

    glmatrix.vec2.add(@player.position, @initialPosition, @initialPosition)

    @initialPosition ?= initialPosition

    # and rotation
    @rotation = @player.rotation
    @rotation ?= rotation

    # setup
    @position = glmatrix.vec2.create(@initialPosition)
    @size = [3,3]

    # set maximum range to 100 units
    @shotRange = 100

    # set maximum shot velocity to 50, and make it go forward
    @maxVelocity = 50
    @velocityFactor = 1

  update: (elapsedMS) ->
    return if @state is 'ended'

    super elapsedMS

    if glmatrix.vec2.dist(@initialPosition, @position) >= @shotRange
      @state = 'ended'

  end: ->
    # we are no longer moving
    @velocityFactor = 0

    # and we are ended
    @state = 'ended'

module.exports = Shot
