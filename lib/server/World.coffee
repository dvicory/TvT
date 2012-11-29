fs = require('fs')

glmatrix = require('../../vendor/gl-matrix/gl-matrix')
glmatrix.glMatrixArrayType = glmatrix.MatrixArray = glmatrix.setMatrixArrayType(Array)

CommonWorld = require('../common/World')

Protocol = require('./Protocol')
Player = require('./Player')

class World
  constructor: (@server) ->
    throw new TypeError('server argument must be a TvT Server') unless @server instanceof require('./Server')

    @io = @server.io

    # object to store players
    @players = {}

    # pre-parse map

    # do an empty map if no world file
    @map = {}
    if fs.existsSync(@server.argv.world)
      @map = CommonWorld.ParseMap(fs.readFileSync(@server.argv.world, 'ascii'))

    @io.sockets.on 'connection', @handleNewConnection

    # setup update loop
    @lastUpdate = process.hrtime()

    updateWrapper = (callback, minElapsedMS) =>
      minElapsedMS ?= 0

      hrDiff = process.hrtime(@lastUpdate)

      # convert hrDiff to ms
      diff = (hrDiff[0] * 1000) + (hrDiff[1] / 1000000)

      # do update
      if diff >= minElapsedMS
        callback(diff)

        # update last update time
        @lastUpdate = process.hrtime()

    @_update = setInterval(updateWrapper, 25, @update, 10)

  update: (elapsedMS) =>
    for key, player of @players
      # one player update could take a long time... let's adjust our elapsedMS parameter to its update
      hrDiff = process.hrtime(@lastUpdate)

      # convert hrDiff to ms
      diff = (hrDiff[0] * 1000) + (hrDiff[1] / 1000000)

      player.update(diff)

    return

  end: ->
    clearInterval(@_update)

    @io.sockets.removeListener('connection', @handleNewConnection)

  handleNewConnection: (socket) =>
    # tell the client our protocol version
    socket.emit 'protocol', Protocol.VERSION

    self = @

    socket.once 'join', (joinData) ->
      # create the representative player object
      # TODO sanitize the incoming information, check for duplicate callsign, etc
      player = new Player self, socket, socket.id, joinData.team, joinData.callsign, joinData.tag

      # use the socket id to store our player by
      self.players[socket.id] = player

      # tell the player they've been joined
      # we can use this to "massage" the data they gave us and change it
      socket.emit 'self join', Player.MessageNewPlayer(player)

    socket.once 'get state', ->
      return unless self.players[socket.id]?

      # TODO: Give this new player state. Includes the map, variables, and all other players.

      # give the map to the player
      socket.emit 'map', self.map

      # tell everyone else about this new player
      socket.broadcast.emit 'new player', Player.MessageNewPlayer(self.players[socket.id])

      # immediate spawn this player at 0,0 with 0 rotation
      # TODO should be random, have a timer, respect state, etc
      self.players[socket.id].spawn([0,0], 0)

  handlePlayerJoin: (joinData) ->
    # create the representative player object
    # TODO sanitize the incoming information, check for duplicate callsign, etc
    player = new Player @, socket, socket.id, joinData.team, joinData.callsign, joinData.tag

    # use the socket id to store our player by
    @players[socket.id] = player

    # tell the player they've been joined
    # we can use this to "massage" the data they gave us and change it
    socket.emit 'self join', Player.MessageNewPlayer(player)

  handleStateRequest: (socket) ->
    # TODO: Give this new player state. Includes the map, variables, and all other players.

    # give the map to the player
    socket.emit 'map', @map

    # tell everyone else about this new player
    socket.broadcast.emit 'new player', Player.MessageNewPlayer(player)

module.exports = World