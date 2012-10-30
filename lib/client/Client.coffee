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

  count = 0
  engine.go 20