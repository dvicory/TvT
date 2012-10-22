class Ball extends pulse.Sprite
  constructor: (args) ->
    args = {} unless args?
    
    args.src = 'http://withpulse.com/demos/ball-world/img/ball.png';
    
    @velocity =
      x: Math.random() * 300 - 150
      y: Math.random() * 300 - 150

    super args
  
  update: (elapsedMS) ->
    newX = @position.x + @velocity.x * (elapsedMS / 1000)
    newY = @position.y + @velocity.y * (elapsedMS / 1000)
    
    if (newX - (@size.width / 2)) <= 0
      newX = @size.width / 2
      @velocity.x *= -1
    
    if (newY - (@size.height/ 2)) <= 0
      newY = @size.height / 2
      @velocity.y *= -1
    
    if (newX + (@size.width / 2)) >= 600
      newX = 600 - @size.width / 2
      @velocity.x *= -1
    
    if (newY + (@size.width / 2)) >= 400
      newY = 400 - @size.height / 2
      @velocity.y *= -1
    
    @position.x = newX
    @position.y = newY
    
    super elapsedMS

pulse.ready ->
  engine = new pulse.Engine
    gameWindow: 'game-window'
    size:
      width: 600
      height: 400
   
  scene = new pulse.Scene
  layer = new pulse.Layer
   
  layer.anchor =
    x: 0
    y: 0

  scene.addLayer layer
  engine.scenes.addScene scene

  engine.scenes.activateScene scene
   
  ball = new Ball
  ball.position =
    x: 100
    y: 100
  layer.addNode ball
   
  # add 5 balls
  for i in [0..5]
    ball = new Ball
    ball.position =
      x: 100
      y: 100
    layer.addNode ball

  label = new pulse.CanvasLabel
    text: 'Click to add more balls'
    fontSize: 12
   
  label.position =
    x: 100
    y: 20
   
  layer.addNode label
  
  layer.events.bind 'mousedown', (args) ->
    ball = new Ball
    ball.position =
      x: args.position.x
      y: args.position.y
    layer.addNode ball

  count = 0
  engine.go 20