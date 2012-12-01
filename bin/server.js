#!/usr/bin/env node

var optimist = require('optimist')
  .usage('Usage: ' + process.argv[1] + ' -p [port]')
  .options({
    port : {
      alias : 'p',
      default : 3000
    },
    world : {
      alias : 'w',
      demand : true
    }
  })
;

var Server = require('../lib/server/Server');

var server = new Server(optimist.argv, __dirname + '/../dist');