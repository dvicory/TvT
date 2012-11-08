Camera = require('./Camera')
Sprite = require('./Sprite')
Player = require('./Player')

class World extends Sprite
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

      # spawn the local player
      @localPlayer = new Player name: 'Local Player', world: @
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

ParseMapFile = (map) ->
  position    = null
  size        = null
  rotation    = 0
  currentType = ''    # internal identifier to indicate which sprite to construct
  badObjects  = 0     # counts object blocks that failed to load

  # control flags
  inWorldBlock = no 
  inBlock      = no

  worldName = 'No Name' # default values for world data will be overidden if found in the file
  worldSize = 800

  lines = map.split('\n')

  for line in lines
    line = line.toLowerCase()
    args = line.split(/(?: )+/)

    if args.length is 0
      continue

    if args[0] is 'world'
      inWorldBlock = yes
      inBlock      = no

    if args[0] is 'box' or args[0] is 'pyramid'
      inWorldBlock = no
      inBlock      = yes
      currentType  = line

    if inWorldBlock
      if args[0] is 'name'
        worldName = args[1] if args.length >= 2
      else if args[0] is 'size'
        worldSize = parseFloat(args[1]) if args.length >= 2

    if inBlock
      if args[0] is 'position' or args[0] is 'pos'
        # this is so we only accept it if the z-value is missing or is 0
        continue unless args.length >= 3 and (parseFloat(args[3]) is 0 or isNaN(parseFloat(args[3])))

        x = parseFloat(args[1])
        y = parseFloat(args[2])

        # we don't want any NaNs stuck in here
        continue if isNaN(x) or isNaN(y)

        position =
          x: x
          y: y

      else if args[0] is 'size'
        continue unless args.length >= 3

        x = parseFloat(args[1])
        y = parseFloat(args[2])

        # we don't want any NaNs stuck in here
        continue if isNaN(x) or isNaN(y)

        size =
          x: x
          y: y

      else if args[0] is 'rotation' or args[0] is 'rot'
        continue unless args.length >= 2

        rot = parseFloat(args[1])

        # we don't want a NaN stuck in here
        continue if isNaN(rot)

        rotation = rot

    if line is 'end'
      if position? and size?
        # TODO fix this
        tiled.Add(new Box(this, boxTexture, position.Value, size.Value * 2, MathHelper.ToRadians(rotation))) if currentType.Equals('box')
        stretched.Add(new Pyramid(this, pyramidTexture, position.Value, size.Value * 2, MathHelper.ToRadians(rotation))) if currentType.Equals('pyramid')
      else
        badObjects++

    # when finished with one block clear all variables
    inBlock  = no
    position = null
    size     = null
    rotation = 0

  # TODO fix this
  mapObjects.Add('stretched', tiled)
  mapObjects.Add("stretched", stretched)
  return mapObjects