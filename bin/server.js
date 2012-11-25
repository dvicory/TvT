#!/usr/bin/env node

var optimist = require('optimist')
  .usage('Usage: ' + process.argv[1] + ' -p [port]')
  .options('p', {
    alias: 'port',
    default: 3000
  })
;

var Server = require('../lib/server/Server');

var server = new Server(optimist.argv, __dirname + '/../dist');