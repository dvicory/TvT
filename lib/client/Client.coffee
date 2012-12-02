EventEmitter = require('../common/EventEmitter')

Protocol = require('./Protocol')
World = require('./World')

pulse.EventManager = EventEmitter

pulse.ready ->
  engine = new pulse.Engine
    gameWindow: 'gameWindow'
    size:
      width: $(window).width()
      height: $(window).height()

  scene = new pulse.Scene name: 'Main'
  layer = new pulse.Layer

  layer.anchor =
    x: 0
    y: 0

  scene.addLayer layer
  engine.scenes.addScene scene

  engine.scenes.activateScene scene

  # window resizing support
  $(window).resize ->
    engine.size =
      width: $(window).width()
      height: $(window).height()

    $('#gameWindow > div').width $(window).width()
    $('#gameWindow > div').height $(window).height()

    $('#gameWindow canvas').attr 'width', $(window).width()
    $('#gameWindow canvas').attr 'height', $(window).height()

    for own key, scene of engine.scenes.scenes
      scene._private.defaultSize =
        width: $(window).width()
        height: $(window).height()
      for own key, layer of scene.layers
        layer.size =
          width: $(window).width()
          height: $(window).height()

  count = 0
  engine.go 20

  # connect to server
  socket = io.connect "#{window.location.protocol}//#{window.location.host}"

  # there was an error
  socket.on 'error', (err) ->
    # TODO handle errors better
    if world?
      layer.removeNode world
      world = null

    console.error err

  # we connected
  socket.on 'connect', ->
    socket.once 'protocol', (serverVersion) =>
      # TODO we should kill ourselves better if this fails
      if serverVersion isnt Protocol.VERSION
        throw new TypeError("Protocol version mismatch (server: #{serverVersion}, client: #{Protocol.VERSION}).")

    # pass along joinData
    joinData =
      callsign: "random callsign #{Math.floor(Math.random() * 101)}"
      team: 'red'
      tag: 'some tag'

    # instantiate world
    world = new World name: 'World', socket: socket, joinData: joinData
    layer.addNode world

  # we disconnected
  socket.on 'disconnect', ->
    # TODO handle disconnections better
    if world?
      layer.removeNode world
      world = null

    return
