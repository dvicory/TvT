class Projection
  constructor: (@min, @max) ->
    throw new TypeError('projection requires min') unless typeof @min is 'number'
    throw new TypeError('projection requires max') unless typeof @max is 'number'

  overlaps: (otherProjection) ->
    !(@min > otherProjection.max or otherProjection.min > @max)

  getOverlap: (otherProjection) ->
    Math.min(otherProjection.max - @min, @max - otherProjection.min)

  lowerOf: (otherProjection) ->
    if (otherProjection.max - @min) < (@max - otherProjection.min)
      return true;

    return false;

  higherOf: (otherProjection) ->
    !@lowerOf(otherProjection)

  contains: (otherProjection) ->
    otherProjection.min > @min && otherProjection.max < @max

module.exports = Projection