EventEmitter = require('../common/EventEmitter')
Player = require('./Player')

pulse.EventManager = EventEmitter

pulse.ready ->
  engine = new pulse.Engine
    gameWindow: 'gameWindow'
    size:
      width: $(window).width()
      height: $(window).height()

  scene = new pulse.Scene
  layer = new pulse.Layer

  layer.anchor =
    x: 0
    y: 0

  scene.addLayer layer
  engine.scenes.addScene scene

  engine.scenes.activateScene scene

  # spawn local player
  localPlayer = new Player
  layer.addNode localPlayer

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