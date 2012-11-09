connect = require('connect')
http = require('http')

app = connect()
  .use(connect.static('dist'))
  .use(connect.directory('dist'))
  .use((req, res) ->
    res.end('Hello from Connect!\n))

http:createServer(app).listen(3000);
