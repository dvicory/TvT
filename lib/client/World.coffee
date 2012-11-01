Sprite = require('./Sprite')
Player = require('./Player')

class World extends Sprite
  constructor: (args) ->
    args ?= {}
    args.src = 'img/textures/grass.png';
    
    super args

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
      @localPlayer = new Player
      @worldLayer.addNode @localPlayer

    # for later...
    if @localPlayer?
      @position = @localPlayer.position
      @rotation = @localPlayer.rotation

    super elapsedMS

  draw: (ctx) ->
    if !@grassPattern?
      @grassPattern = ctx.createPattern @getCurrentFrame(), 'repeat'

    if @grassPattern?
      ctx.clearRect 0, 0, $(window).width(), $(window).height()

      ctx.fillStyle = @grassPattern
      ctx.fillRect 0, 0, $(window).width() * 2, $(window).height() * 2

module.exports = World

ParseMapFile = (sr) ->
  position = null
  size = null
  rotation = 0
  currentType = "" # internal identifier to indicate which texture to construct
  badObjects = 0 # counts object blocks that failed to load
  inWorldBlock = no # control flags
  inBlock = no
  worldName = "No Name" # default values for world data will be overidden if found in the file
  worldSize = 800
  line = ""
  while (line = sr.ReadLine()) isnt null
    line = line.toLowerCase().trim()
    if line.lastIndexOf("world", 0) is 0
      inWorldBlock = yes
      inBlock = no
    if line.StartsWith("box", StringComparison.InvariantCultureIgnoreCase) or line.StartsWith("pyramid", StringComparison.InvariantCultureIgnoreCase)
      inWorldBlock = no
      inBlock = yes
      currentType = line.Split(' ')[0]
    if inWorldBlock
      worldName = line.Trim().Substring(4).Trim() if line.StartsWith("name", StringComparison.InvariantCultureIgnoreCase)
      worldSize = Convert.ToSingle(line.Trim().Substring(4).Trim()) if line.StartsWith("size", StringComparison.InvariantCultureIgnoreCase)
    if inBlock
      if line.StartsWith("position", StringComparison.InvariantCultureIgnoreCase) or line.StartsWith("pos", StringComparison.InvariantCultureIgnoreCase)
        List<String> rawArgs = line.Trim().Substring(9).Split(' ').ToList()
        rawArgs.ForEach(v => coords.Add(Convert.ToSingle(v)))
        position = new Vector2(coords[0], coords[1]) if coords.Count is 2 or ((coords.Count is 3) and (Math.Abs(coords[2]) <= Single.Epsilon)) # only load objects with at least x, y and a zero z-position
      else if line.StartsWith("size", StringComparison.InvariantCultureIgnoreCase)
        List<String> rawArgs = line.Trim().Substring(5).Split(' ').ToList()
        rawArgs.ForEach(v => coords.Add(Convert.ToSingle(v)))
        size = new Vector2(coords[0], coords[1])if coords.Count >= 2 # only load objects with at least x and y size
      else if line.StartsWith("rotation", StringComparison.InvariantCultureIgnoreCase) or line.StartsWith("rot", StringComparison.InvariantCultureIgnoreCase)
        coords = line.Trim().Substring(9).Split(' ')
        rotation = Convert.ToSingle(coords[0].Trim())
    if line.Equals("end")
      if position.HasValue and size.HasValue
        tiled.Add(new Box(this, boxTexture, position.Value, size.Value * 2, MathHelper.ToRadians(rotation))) if currentType.Equals("box")
        stretched.Add(new Pyramid(this, pyramidTexture, position.Value, size.Value * 2, MathHelper.ToRadians(rotation))) if currentType.Equals("pyramid")
      else
        badObjects++
      inBlock = no # when finished with one block clear all variables
      position = null
      size = null
      rotation = 0
  mapObjects.Add("tiled", tiled)
  mapObjects.Add("stretched", stretched)
  return mapObjects
