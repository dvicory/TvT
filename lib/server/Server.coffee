http = require('http')
connect = require('connect')
io = require('socket.io')

glmatrix = require('../../vendor/gl-matrix/gl-matrix')
# Force Array type - rather not deal with endianness for typed arrays
glmatrix.glMatrixArrayType = glmatrix.MatrixArray = glmatrix.setMatrixArrayType(Array)

World = require('./World')

class Server
  constructor: (@argv, @directory) ->
    # TODO check arguments

    # configure connect app
    @app = connect()
      .use(connect.static(@directory))
      .use(connect.directory(@directory))

    # start http server
    @server = http.createServer(@app)
    @server.listen(@argv.port)

    # start taking socket.io connections
    @io = io.listen(@server)

    # force the transport types
    @io.configure =>
      @io.set 'transports', ['websocket', 'flashsocket']

      @io.set 'close timeout', 25
      @io.set 'heartbeat timeout', 25
      @io.set 'heartbeat interval', 10

    # create the world
    @world = new World(@)

module.exports = Server
