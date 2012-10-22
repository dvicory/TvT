'use strict'

http = require('http')

handler = (req, res) ->
  res.writeHead(200)
  res.end('Hello World!')

app = http.createServer(handler).listen(3333)