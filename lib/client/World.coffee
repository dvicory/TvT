#World class that extends Spite

Sprite = require('./Sprite')
Player = require('./Player')

class World extends Sprite
  constructor: (args) ->
    args ?= {}
    args.src = 'img/textures/other/grass.png';
    
    # call parent constructor, we'll get access to Sprite's members now
    super args

  update: (elapsedMS) ->
    # make worldLayer, which includes world elements
    # the layer world is in is a special layer
    if @parent? and !@worldLayer?         #@Parents from pulse.Node
      @worldLayer = new pulse.Layer
      @worldLayer.anchor =
        x: 0
        y: 0

      @parent.parent.addLayer @worldLayer

      # spawn the local player
      @localPlayer = new Player
      @worldLayer.addNode @localPlayer

    # setup offscreen background canvas if we haven't already
    if @texture.percentLoaded is 100 and !@offscreenBackground? #this.offscreensBackground initially null 1st time around.
      @offscreenBackground = document.createElement('canvas')   #document.createElement() from javascript library
      @setupOffscreenBackground()  #method down below

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

ParseMapFile = (sr) ->
  position    = null
  size        = null
  rotation    = 0
  currentType = ""   # internal identifier to indicate which texture to construct
  badObjects  = 0    # counts object blocks that failed to load

  #Control frags
  inWorldBlock = no 
  inBlock      = no

  worldName   = "No Name" # default values for world data will be overidden if found in the file
  worldSize   = 800


  line = ""  #string?


  lines = sr.split('\n')

  for line in lines    #while loops replaced
    #console.log(line)
    line = line.toLowerCase().trim()         

    if line.lastIndexOf("world", 0) is 0
      inWorldBlock = yes
      inBlock      = no

    if line.lastIndexOf("box", 0) is 0 or line.lastIndexOf("pyramid", 0) is 0
      inWorldBlock = no
      inBlock      = yes
      currentType  = line.split(' ',0)

    if inWorldBlock
      if line.lastIndexOf("name", 0) is 0
        worldName = line.trim().slice(4).trim() 
      if line.lastIndexOf("size", 0) is 0
        worldSize = parseFloat((line.trim().slice(4).trim())  #Note: lower case "s" on substring
        #Convert.toSingle() -> parseFloat(()
    
    if inBlock
      if line.lastIndexOf("position", 0) is 0 or line.lastIndexOf("pos", 0) is 0
        #stringArray = new Array(9)
        rawArgs = line.trim().slice(9).split(' ')
        rawArgs.ForEach(v => coords.Add(parseFloat((v)))

        # only load objects with at least x, y and a zero z-position
        if coords.Count is 2 or ((coords.Count is 3) and (Math.abs(coords[2]) <= Single.Epsilon)) 
        position = new Vector2(coords[0], coords[1]) 
      
      else if line.lastIndexOf("size", 0) is 0
        #stringArray = new Array(5)
        rawArgs = line.trim().slice(5).split(' ')
        #rawArgs = new Array(5)
        #rawArgs = line.trim().substring(5).split(' ').ToList()
        rawArgs.ForEach(v => coords.Add(parseFloat((v)))

        # only load objects with at least x and y size
        if coords.Count >= 2
          size = new Vector2(coords[0], coords[1]) 

      else if line.lastIndexOf("rotation", 0) is 0 or line.lastIndexOf("rot", 0) is 0
        coords = line.trim().slice(9).split(' ')
        rotation = parseFloat((coords[0].trim())
    
    if line is "end"
      if position.HasValue and size.HasValue
        tiled.Add(new Box(this, boxTexture, position.Value, size.Value * 2, MathHelper.ToRadians(rotation))) if currentType.Equals("box")
        stretched.Add(new Pyramid(this, pyramidTexture, position.Value, size.Value * 2, MathHelper.ToRadians(rotation))) if currentType.Equals("pyramid")
      else
        badObjects++

      # when finished with one block clear all variables
      inBlock  = no 
      position = null
      size     = null
      rotation = 0


  mapObjects.Add("tiled", tiled)
  mapObjects.Add("stretched", stretched)
  return mapObjects
