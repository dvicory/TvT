Camera = require('./Camera')
DynamicSprite = require('./DynamicSprite')
LocalPlayer = require('./LocalPlayer')

class World extends DynamicSprite
  constructor: (args) ->
    args ?= {}
    args.src = 'img/textures/other/grass.png';

    # call parent constructor, we'll get access to Sprite's members now
    super args

    @camera = new Camera

  update: (elapsedMS) ->
    # make worldLayer, which includes world elements
    # the layer world is in is a special layer
    if @parent? and !@worldLayer?
      @worldLayer = new pulse.Layer
      @worldLayer.anchor =
        x: 0
        y: 0

      @parent.parent.addLayer @worldLayer

      # create the local player
      @localPlayer = new LocalPlayer name: 'Local Player', world: @
      @worldLayer.addNode @localPlayer

    # setup offscreenBackground canvas if we haven't already
    # offscreenBackground is initially null
    if @texture.percentLoaded is 100 and !@offscreenBackground?
      @offscreenBackground = document.createElement('canvas')
      @setupOffscreenBackground()

      # resize and redraw offscreen canvas if window resizes
      $(window).resize => @setupOffscreenBackground()

    # we need the local player's position to see where to do the tile
    if @localPlayer?
      @position = @localPlayer.position

    super elapsedMS

  draw: (ctx) ->
    # we obviously haven't finished loading the texture yet...
    if @texture.percentLoaded isnt 100 or @size.width is 0 or @size.height is 0
      return

    # to draw the grass texture, we use an offscreen canvas
    # make sure it exists...
    if @offscreenBackground?
      # this is so the background moves with the tank
      startX = Math.round(@position.x) % @texture.width()
      startY = Math.round(@position.y) % @texture.height()

      # can't draw if the starting positions are negative, so wrap around
      if startX < 0
        startX += @texture.width()
      if startY < 0
        startY += @texture.height()

      width  = @parent.size.width
      height = @parent.size.height

      # draw to our context from offscreen canvas
      ctx.drawImage(@offscreenBackground, startX, startY, width, height, 0, 0, width, height)

  setupOffscreenBackground: ->
    width  = @parent.size.width
    height = @parent.size.height

    @offscreenBackground.width  = Math.ceil(((width  + @texture.width())   / @texture.width())) * @texture.width()
    @offscreenBackground.height = Math.ceil(((height + @texture.height()) / @texture.height())) * @texture.height()

    ctx = @offscreenBackground.getContext '2d'

    # create pattern and set it as the fill
    bgPattern = ctx.createPattern @getCurrentFrame(), 'repeat'
    ctx.fillStyle = bgPattern

    # fill whole offscreen background with repeating pattern
    ctx.fillRect 0, 0, @offscreenBackground.width, @offscreenBackground.height

module.exports = World