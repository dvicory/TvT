glmatrix = require('../../vendor/gl-matrix/gl-matrix')
glmatrix.glMatrixArrayType = glmatrix.MatrixArray = glmatrix.setMatrixArrayType(Array)

StaticWorldObject = require('./StaticWorldObject')

class World
  @ParseMap = (map) ->
    position    = null
    size        = null
    rotation    = 0
    currentType = ''    # internal identifier to indicate which sprite to construct
    badObjects  = 0     # counts object blocks that failed to load
    mapObjects  = []

    # control flags
    inWorldBlock = no 
    inBlock      = no

    worldName = 'No Name' # default values for world data will be overidden if found in the file
    worldSize = 800

    # split on end of line
    # see http://stackoverflow.com/questions/5034781/js-regex-to-split-by-line#comment5633979_5035005
    lines = map.split(/\r\n|[\n\v\f\r\x85\u2028\u2029]/)

    for line in lines
      line = line.toLowerCase().trim()
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

          position = glmatrix.vec2.create [x, y]

        else if args[0] is 'size'
          continue unless args.length >= 3

          x = parseFloat(args[1])
          y = parseFloat(args[2])

          # we don't want any NaNs stuck in here
          continue if isNaN(x) or isNaN(y)

          size = glmatrix.vec2.create([x, y])
          glmatrix.vec2.scale(size, 2) # scale by 2, in bzw size is half width/height (from center to one edge) whereas the game uses the full width/height

        else if args[0] is 'rotation' or args[0] is 'rot'
          continue unless args.length >= 2

          rot = parseFloat(args[1])

          # we don't want a NaN stuck in here
          continue if isNaN(rot)

          rotation = rot * (Math.PI / 180) # make sure to convert degrees to radians

      if line is 'end'
        if position? and size?
          mapObjects.push(new StaticWorldObject(currentType.charAt(0).toUpperCase() + currentType.slice(1), position, size, rotation))
        else
          badObjects++

        # when finished with one block clear all variables
        inBlock  = no
        position = null
        size     = null
        rotation = 0

    return mapObjects

module.exports = World
