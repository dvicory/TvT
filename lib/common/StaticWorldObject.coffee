glmatrix = require('../../vendor/gl-matrix/gl-matrix')
glmatrix.glMatrixArrayType = glmatrix.MatrixArray = glmatrix.setMatrixArrayType(Array)

WorldObject = require('./WorldObject')

class StaticWorldObject extends WorldObject
  constructor: (type, @position, @size, @rotation) ->
    type ?= 'StaticWorldObject'
    super type

    @position  = glmatrix.vec2.create() unless @position instanceof Array and @position.length is 2
    @size      = glmatrix.vec2.create() unless @size     instanceof Array and @size.length     is 2

    @rotation  = 0 unless typeof @rotation is 'number'

module.exports = StaticWorldObject
