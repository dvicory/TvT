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
      [@map, @mapSize] = CommonWorld.ParseMap(fs.readFileSync(@server.argv.world, 'ascii'))

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
    if @players[socket.id]?
      console.error "can not add player: player with slot #{socket.id} already exists"
      socket.disconnect 'can not add you: you already exist on the server'
      return

    socket.once 'disconnect', (reason) =>
      if not @players[socket.id]?
        console.error "can not remove player: player with slot #{socket.id} does not exist"
        socket.emit 'error', 'can not remove you, you do not exist on the server'
        socket.disconnect()
        return

      # tell everyone this player has disconnected
      socket.broadcast.emit 'remove player', Player.MessageRemovePlayer(@players[socket.id])

      # now remove
      socket.removeAllListeners()
      @players[socket.id] = null
      delete @players[socket.id]

    socket.once 'join', (joinData) =>
      # TODO sanitize the incoming information, check for duplicate callsign, etc

      teams = ['red', 'green', 'purple', 'blue']

      # if random team, choose one
      if joinData.team is 'random'
        joinData.team = teams[Math.floor(Math.random() * teams.length)]

      # got an invalid team
      if teams.indexOf(joinData.team) is -1
        socket.removeAllListeners()

        console.error "player #{socket.id} tried to join invalid team #{joinData.team}"
        socket.emit 'error', "you tried to join with invalid team #{joinData.team}"
        socket.disconnect()

        return

      # check for duplicate callsign
      for player in @players
        if joinData.callsign is player.callsign
          socket.removeAllListeners()

          console.error "player #{socket.id} tried to join with callsign #{joinData.callsign} which matches player #{player.slot}"
          socket.emit 'error', 'you tried to join with the same callsign as someone else'
          socket.disconnect()

          return

      # create the representative player object
      player = new Player @, socket, socket.id, joinData.team, joinData.callsign, joinData.tag

      # use the socket id to store our player by
      @players[socket.id] = player

      # tell the player they've been joined
      # we can use this to "massage" the data they gave us and change it
      socket.emit 'self join', Player.MessageNewPlayer(player)

      # tell everyone else about this new player
      socket.broadcast.emit 'new player', Player.MessageNewPlayer(@players[socket.id])

      # immediate spawn this player at 0,0 with 0 rotation
      # TODO should be random, have a timer, respect state, etc
      player.spawn([0,0], 0)

    socket.once 'get state', =>
      return unless @players[socket.id]?

      # TODO: Give this new player state. Includes the map, variables, and all other players.

      # give the map to the player
      socket.emit 'map', @map, @mapSize

      # tell this new player about all existing players
      for slot, player of @players
        # doesn't make sense to tell them about themselves
        continue if slot is socket.id

        socket.emit 'new player', Player.MessageNewPlayer(player)
        socket.emit 'update player', Player.MessageUpdatePlayer(player)

    # now start it all off, tell the client our protocol version
    socket.emit 'protocol', Protocol.VERSION

module.exports = World
