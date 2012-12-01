glmatrix = require('../../vendor/gl-matrix/gl-matrix')
glmatrix.glMatrixArrayType = glmatrix.MatrixArray = glmatrix.setMatrixArrayType(Array)

Projection = require('./Projection')
Rectangle = require('./Rectangle')

class RotatedRectangle extends Rectangle
  constructor: (@position, @size, @rotation) ->
    super @position, @size

    @rotation ?= 0

    # Rectangle's origin property. We assume the center of the Rectangle will
    # be the point that we will be rotating around and we use that for the origin.
    Object.defineProperty @, 'origin',
      writable: false
      value: [@width / 2, @height / 2]

    Object.defineProperty @, 'upperLeft',
      get: ->
        upperLeft = glmatrix.vec2.create(@left, @top)
        origin = @origin
        @rotatePoint(upperLeft, glmatrix.vec2.add(origin, upperLeft), @rotation)

    Object.defineProperty @, 'upperRight',
      get: ->
        upperRight = glmatrix.vec2.create(@right, @top)
        origin = [-@origin[0], @origin[1]]
        @rotatePoint(upperRight, glmatrix.vec2.add(origin, upperRight), @rotation)

    Object.defineProperty @, 'lowerLeft',
      get: ->
        lowerLeft = glmatrix.vec2.create(@left, @bottom)
        origin = [@origin[0], -@origin[1]]
        @rotatePoint(lowerLeft, glmatrix.vec2.add(origin, lowerLeft), @rotation)

    Object.defineProperty @, 'lowerRight',
      get: ->
        lowerRight = glmatrix.vec2.create(@right, @bottom)
        origin = [-@origin[0], -@origin[1]]
        @rotatePoint(lowerRight, glmatrix.vec2.add(origin, lowerRight), @rotation)

    Object.defineProperty @, 'vertices',
      get: ->
        [@upperLeft, @upperRight, @lowerLeft, @lowerRight]

  intersects: (rectangle) ->
    # Calculate the axes we will use to determine if a collision has occurred
    # Since the objects are rectangles, we only have to generate 4 axes (2 for
    # each rectangle) since we know the other 2 on a rectangle are parallel.
    axes = [
      glmatrix.vec2.subtract(@upperRight, @upperLeft)
      glmatrix.vec2.subtract(@upperRight, @lowerRight)
      glmatrix.vec2.subtract(rectangle.upperLeft, rectangle.lowerLeft)
      glmatrix.vec2.subtract(rectangle.upperLeft, rectangle.upperRight)
    ]

    # Cycle through all of the axes we need to check. If a collision does not occur
    # on ALL of the axes, then a collision is NOT occurring. We can then exit out 
    # immediately and notify the calling function that no collision was detected. If
    # a collision DOES occur on ALL of the axes, then there is a collision occurring
    # between the rotated rectangles. We know this to be true by the Seperating Axis Theorem.
    
    # In addition, overlap is tracked so that the smallest overlap can be returned to the caller.
    bestOverlap = Number.MAX_VALUE
    bestCollisionProjection = glmatrix.vec2.create()

    for axis in axes
      # required for accurate projections
      glmatrix.vec2.normalize(axis)

      if not o = @isAxisCollision(rectangle, axis)
        # if there is no axis collision, we can guarantee they do not overlap
        return false

      # do we have the smallest overlap yet?
      if o < bestOverlap
        bestOverlap = o
        bestCollisionProjection = axis

    # it is now guaranteed that the rectangles intersect for us to have gotten this far
    overlap = bestOverlap
    collisionProjection = bestCollisionProjection

    # now we want to make sure the collision projection vector points from the other rectangle to us
    centerToCenter = glmatrix.vec2.create()
    centerToCenter[0] = (rectangle.x + rectangle.origin[0]) - (@x + @origin[0])
    centerToCenter[1] = (rectangle.y + rectangle.origin[1]) - (@y + @origin[1])

    if glmatrix.vec2.dot(collisionProjection, centerToCenter) > 0
      glmatrix.vec2.negate(collisionProjection)

    return [overlap, collisionProjection]

  isAxisCollision: (rectangle, axis) ->
    # project both rectangles onto the axis
    curProj   = @project(axis)
    otherProj = rectangle.project(axis)

    # do the projections overlap?
    if curProj.getOverlap(otherProj) < 0
      return false

    # get the overlap
    overlap = curProj.getOverlap(otherProj)

    # check for containment
    if curProj.contains(otherProj) or otherProj.contains(curProj)
      # get the overlap plus the distance from the minimum end points
      mins = Math.abs(curProj.min - otherProj.min)
      maxs = Math.abs(curProj.max - otherProj.max)

      # NOTE: depending on which is smaller you may need to negate the separating axis
      if mins < maxs
        overlap += mins
      else
        overlap += maxs

    # and return the overlap for an axis collision
    return overlap

  project: (axis) ->
    vertices = @vertices

    min = glmatrix.vec2.dot(axis, vertices.shift())
    max = min

    for vertex in vertices
      p = glmatrix.vec2.dot(axis, vertex)

      if p < min
        min = p
      else if p > max
        max = p

    return new Projection(min, max)

  rotatePoint: (point, origin, rotation) ->
    # see http://stackoverflow.com/questions/620745/c-rotating-a-vector-around-a-certain-point/705474#705474
    # x = ((x - x_origin) * cos(angle)) - ((y_origin - y) * sin(angle)) + x_origin
    # y = ((y_origin - y) * cos(angle)) - ((x - x_origin) * sin(angle)) + y_origin
    # TODO glmatrix 2.0-dev may allow native transformations on vec2
    point[0] = ((point[0] - origin[0]) * Math.cos(rotation)) - ((origin[1] - point[1]) * Math.sin(rotation)) + origin[0]
    point[1] = ((origin[1] - point[1]) * Math.cos(rotation)) - ((point[0] - origin[0]) * Math.sin(rotation)) + origin[1]

    return point

module.exports = RotatedRectangle
