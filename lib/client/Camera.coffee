class Camera
  constructor: ->
    Object.defineProperty @, 'origin',
      get: ->
        x: $(window).width() / 2
        y: $(window).height() / 2

    Object.defineProperty @, 'position',
      get: ->
        @_position
      set: (val) ->
        @_position = @validatePosition(val)
    
    Object.defineProperty @, 'panPosition',
      get: ->
        @_panPosition
      set: (val) ->
        @_panPosition = @validatePosition(val)

    Object.defineProperty @, 'cameraPosition',
      get: ->
        x: @position.x + @panPosition.x
        y: @position.y + @panPosition.y

    Object.defineProperty @, 'zoom',
      get: ->
        @_zoom
      set: (val) ->
        @_zoom = @validateZoom(val)

        @_position = @validatePosition(@_position)
        @_panPosition = @validatePosition(@_panPosition)

    Object.defineProperty @, 'limits',
      get: ->
        @_limits
      set: (val) ->
        @_limits = val

        @_zoom = @validateZoom(@_zoom)
        @_position = @validatePosition(@_position)
        @_panPosition = @validatePosition(@_panPosition)

    @_zoom = 1
    @_position =
      x: 0
      y: 0
    @_panPosition =
      x: 0
      y: 0

  move: (displacement) ->
    pos = @position

    pos.x += displacement.x
    pos.y += displacement.y

    @position = pos

  pan: (displacement) ->
    pPos = @panPosition

    @panPosition.x += displacement.x
    @panPosition.y += displacement.y

    @panPosition = pPos

  lookAt: (position) ->
    pos =
      x: position.x + @panPosition.x - @origin.x
      y: position.y + @panPosition.y - @origin.y

    @position = pos

  transformView: (ctx) =>
    ctx.translate -@cameraPosition.x, -@cameraPosition.y

  validateZoom: (zoom) ->
    if limits?
      minZoomX = $(window).width() / @limits.x
      minZoomY = $(window).height() / @limits.y
      return Math.max(zoom, Math.max(minZoomX, minZoomY))

    return zoom

  validatePosition: (pos) ->
    pos

module.exports = Camera