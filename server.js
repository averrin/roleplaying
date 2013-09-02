/**
 * Otagai.js
 * Based on https://github.com/olafurnielsen/form5-node-express-mongoose-coffeescript
 */

var app = require('express')(),
    http = require('http'),
    fs = require('fs'),
    passport = require('passport'),
    mongoose = require('mongoose'),
    coffee = require('coffee-script'),
    server = http.createServer(app),
    io = require("socket.io"),
    socketioWildcard = require( 'socket.io-wildcard' ),
    io = socketioWildcard(io).listen(server);

var env = process.env.NODE_ENV || 'development',
    config = require('./config/environment')[env],
    auth = require('./config/middlewares/authorization')
    
// Bootstrap database
console.log('Connecting to database at ' + config.db)
mongoose.connect(config.db)

// Bootstrap models
var models_path = __dirname + '/app/models'
fs.readdirSync(models_path).forEach(function (file) {
  require(models_path+'/'+file)
});

// bootstrap passport config
require('./config/passport')(passport, config)

//var app = express()
// express settings
require('./config/express')(app, config, passport)

// Bootstrap routes
require('./config/routes')(app, config, passport, auth)

// Helper funtions
require('./app/helpers/general')(app)

io.configure(function(){
    io.enable('browser client minification');  // send minified client
	io.enable('browser client etag');          // apply etag caching logic based on version number
	io.enable('browser client gzip');          // gzip the file
	io.set('log level', 1);                    // reduce logging
	io.set('transports', [                     // enable all transports (optional if you want flashsocket)
	    'websocket'
	  , 'flashsocket'
	  , 'htmlfile'
	  , 'xhr-polling'
	  , 'jsonp-polling'
	]);
})

var ss = require('./app/socket_server')
ss.init(io);


// Start the app by listening on <port>
var host = process.argv[2] || '0.0.0.0';
var port = process.argv[3] || process.env.PORT || 3300
server.listen(port, host, function(){
  console.log("\u001b[36mApp running on port " + port + "\u001b[0m")
});
