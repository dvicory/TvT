#!/usr/bin/env node

var Server = require('../lib/server/Server')

var port = 3000;

if (typeof process.argv[2] !== 'undefined')
	port = process.argv[2];

server = new Server('dist', port);