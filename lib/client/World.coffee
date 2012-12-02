Camera = require('./Camera')
LocalPlayer = require('./LocalPlayer')

class World extends pulse.Sprite
  constructor: (args) ->
    args ?= {}
    args.src = 'img/textures/other/grass.png'

    throw new TypeError('socket is a required key in args and must be a socket.io socket') unless args.socket   instanceof io.SocketNamespace
    throw new TypeError('joinData is a required key in args and must be an object')        unless args.joinData instanceof Object

    @socket = args.socket

    # call parent constructor, we'll get access to Sprite's members now
    super args

    # create camera now
    @camera = new Camera

    # we need a setup callback because certain things aren't ready to use in the constructor
    setupCallback = =>
      @worldLayer = new pulse.Layer
      @worldLayer.anchor =
        x: 0
        y: 0

      @parent.parent.addLayer @worldLayer

      @socket.once 'self join', (joinData) =>
        # create the local player now
        # TODO technically we shouldn't be spawning now
        @localPlayer = new LocalPlayer @, joinData.slot, joinData.team, joinData.callsign, joinData.tag, { name: 'Local Player' }
        @worldLayer.addNode @localPlayer

      # we need to let client do its things before we can emit these events, thus the timeout callback
      # we'll also bind where needed
      @socket.emit 'join', args.joinData
      @socket.emit 'get state'

      @socket.on 'new player', (newPlayerData) ->
        console.log newPlayerData

      @socket.on 'remove player', (removePlayerData) ->
        console.log removePlayerData

      @socket.on 'update player', (updatePlayerData) ->
        console.log updatePlayerData

    setTimeout setupCallback, 0

  update: (elapsedMS) ->
    # TODO move this to setupCallback
    # most likely problem is the callback gets fired before the texture is loaded
    # asset loading beforehand will solve this
    if @texture.percentLoaded is 100 and !@offscreenBackground?
      @offscreenBackground = document.createElement('canvas')
      @setupOffscreenBackground()

      # resize and redraw offscreen canvas if window resizes
      $(window).resize @setupOffscreenBackground

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

  setupOffscreenBackground: =>
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
