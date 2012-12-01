class Rectangle
  constructor: (@position, @size) ->
    throw new TypeError('rectangle requires position') unless @position instanceof Array and @position.length is 2
    throw new TypeError('rectangle requires size')     unless @size     instanceof Array and @size.length     is 2

    Object.defineProperty @, 'x',
      writable: true
      value: @position[0]
    
    Object.defineProperty @, 'y',
      writable: true
      value: @position[1]

    Object.defineProperty @, 'width',
      writable: true
      value: @size[0]

    Object.defineProperty @, 'height',
      writable: true
      value: @size[1]

    Object.defineProperty @, 'top',
      get: ->
        @y

    Object.defineProperty @, 'bottom',
      get: ->
        @y + @height

    Object.defineProperty @, 'left',
      get: ->
        @x

    Object.defineProperty @, 'right',
      get: ->
        @x + @width

module.exports = Rectangle
