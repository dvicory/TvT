connect = require('connect')
http = require('http')

class Server
  constructor: (@directory, @port) ->
    @app = connect()
      .use(connect.static(@directory))
      .use(connect.directory(@directory))

    http.createServer(@app).listen(@port)

module.exports = Server