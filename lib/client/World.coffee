Camera = require('./Camera')
LocalPlayer = require('./LocalPlayer')
RemotePlayer = require('./RemotePlayer')
Box = require('./Box')

class World extends pulse.Sprite
  constructor: (args) ->
    args ?= {}
    args.src = 'img/textures/other/grass.png'

    throw new TypeError('assetManager is a required key in args and must be a pulse.AssetManager assetManager') unless instanceof pulse.AssetManager
    throw new TypeError('socket is a required key in args and must be a socket.io socket') unless args.socket   instanceof io.SocketNamespace
    throw new TypeError('joinData is a required key in args and must be an object')        unless args.joinData instanceof Object

    @socket = args.socket
    @assetManager = args.assetManager

    # call parent constructor, we'll get access to Sprite's members now
    super args

    Object.defineProperty @, 'pixelsPerWorldUnit',
      writabale: false
      value: 10

    # create camera now
    @camera = new Camera

    # need something to hold all the players
    @players = {}

    # also need something for all the map objects
    @mapObjects = []

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

      @socket.once 'map', @handleMap

      # bind relevant events that world takes care of
      @socket.on 'new player', @handleNewPlayer
      @socket.on 'remove player', @handleRemovePlayer

      # we need to let client do its things before we can emit these events, thus the timeout callback
      @socket.emit 'join', args.joinData
      @socket.emit 'get state'

    setTimeout setupCallback, 0

  handleMap: (mapObjects) =>
    i = 0
    for mapObject in mapObjects
      sprite = new Box @, mapObject.position, mapObject.size, mapObject.rotation, { name: "Box #{i}" }

      @mapObjects.push sprite
      @worldLayer.addNode sprite
      i++

  handleNewPlayer: (newPlayerData) =>
    if @players[newPlayerData.slot]?
      console.error "can not add player: player with slot #{newPlayerData.slot} already exists"
      return

    @players[newPlayerData.slot] = new RemotePlayer @, newPlayerData.slot, newPlayerData.team, newPlayerData.callsign, newPlayerData.tag, { name: "Player: #{newPlayerData.slot}" }
    @worldLayer.addNode @players[newPlayerData.slot]

  handleRemovePlayer: (removePlayerData) =>
    if not @players[removePlayerData.slot]?
      console.error "can not remove player: player with slot #{newPlayerData.slot} does not exist"
      return

    @worldLayer.removeNode @players[removePlayerData.slot]
    @players[removePlayerData.slot] = null

  update: (elapsedMS) ->
    # TODO move this to setupCallback
    # most likely problem is the callback gets fired before the texture is loaded
    # asset loading beforehand will solve this
    if @texture.percentLoaded is 100 and !@offscreenBackground?
      @offscreenBackground = document.createElement('canvas')
      @setupOffscreenBackground()

      # resize and redraw offscreen canvas if window resizes
      $(window).resize @setupOffscreenBackground

    super elapsedMS

  draw: (ctx) ->
    # we obviously haven't finished loading the texture yet...
    if @texture.percentLoaded isnt 100 or @size.width is 0 or @size.height is 0
      return

    # we need the local player's position to see where to do the tile
    if @localPlayer?
      @position = @localPlayer.position

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
