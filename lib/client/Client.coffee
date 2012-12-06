EventEmitter = require('../common/EventEmitter')

Protocol = require('./Protocol')
World = require('./World')

pulse.EventManager = EventEmitter

startTvT = (assetManager, joinData) ->
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
  socket = io.connect "#{window.location.protocol}//#{window.location.host}", reconnect : false

  # we connected
  socket.on 'connect', ->
    socket.once 'protocol', (serverVersion) =>
      # TODO we should kill ourselves better if this fails
      if serverVersion isnt Protocol.VERSION
        throw new TypeError("Protocol version mismatch (server: #{serverVersion}, client: #{Protocol.VERSION}).")

    # pass along joinData
    joinData.tag ?= ''

    # instantiate world
    window.tvt = world = new World name: 'World', socket: socket, joinData: joinData, assetManager: assetManager
    layer.addNode world

  # there was an error
  socket.on 'error', (err) ->
    # TODO handle errors better
    if world?
      layer.removeNode world
      world = null

    console.error err

  # we disconnected
  socket.on 'disconnect', ->
    # TODO handle disconnections better
    if world?
      layer.removeNode world
      world = null

    console.error 'disconnected from tvt server'

pulse.ready ->
  # hide all menus
  $('#menus').hide()
  $('#menus > div').hide()

  manifest =
    tank_blue   : 'img/textures/custom/tank_blue.png'
    tank_green  : 'img/textures/custom/tank_green.png'
    tank_hunter : 'img/textures/custom/tank_hunter.png'
    tank_purple : 'img/textures/custom/tank_purple.png'
    tank_rabbit : 'img/textures/custom/tank_rabbit.png'
    tank_red    : 'img/textures/custom/tank_red.png'
    tank_rogue  : 'img/textures/custom/tank_rogue.png'
    tank_white  : 'img/textures/custom/tank_white.png'
    grass       : 'img/textures/other/grass.png'

  assetManager = new pulse.AssetManager

  for name, filename of manifest
    assetManager.addAsset(new pulse.Texture(name: name, filename: filename))

  assetManager.events.on 'complete', ->
    # we want to get the menu started up

    # hide loading container
    $('.loadingContainer').hide()

    # now align it to the top - loading is centered
    $('#wrapper').addClass 'alignStart'

    # and unhide the menus
    $('#menus').show()
    $('#mainMenu').show()

    # setup event handlers on main menu
    $('#mainMenu li').click ->
      # hide all menus
      $('#menus > div').hide()

      # unhide specific one we want
      $("#{$(this).attr('data-to')}").show()

    $('#joinMenu form').submit ->
      # start the game
      $('#gameWindow').show()

      joinData = $(this).serializeJSON()

      startTvT(assetManager, joinData)

      # prevent default action
      return false
