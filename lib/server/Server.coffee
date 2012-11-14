http = require('http')
connect = require('connect')
io = require('socket.io')

class Server
  constructor: (@directory, @port) ->
    # configure connect app
    @app = connect()
      .use(connect.static(@directory))
      .use(connect.directory(@directory))

    # start http server
    @server = http.createServer(@app)
    @server.listen(@port)

    # start taking socket.io connections
    io.listen(@server)

module.exports = Server