StaticSprite = require('./StaticSprite')

class Box extends StaticSprite
  constructor: (@world, position, size, rotation, args) ->
    args ?= {}

    # 1x1 black gif
    args.src = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAAAAACH5BAAAAAAALAAAAAABAAEAAAICTAEAOw=='

    # call parent constructor, we'll get access to our parent's members now
    super @world, null, args

    # we'll need the pixel conversions
    @model.position = position
    @model.size = size
    @model.rotation = rotation

    canvas = document.createElement('canvas')

    canvas.width = @size.width
    canvas.height = @size.height

    ctx = canvas.getContext('2d')

    ctx.fillStyle = 'rgba(0, 0, 0, 0.6)'
    ctx.strokeStyle = '#000'
    ctx.lineWidth = 10

    ctx.fillRect(0, 0, @size.width, @size.height)
    ctx.strokeRect(0, 0, @size.width, @size.height)

    @texture = new pulse.Texture filename: canvas.toDataURL()

module.exports = Box
