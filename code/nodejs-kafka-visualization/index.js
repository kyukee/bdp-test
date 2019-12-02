// Setup kafka consumer
var kafka = require('kafka-node');
var Consumer = kafka.Consumer,
    // The client specifies the ip of the Kafka producer and uses
    client = new kafka.KafkaClient({kafkaHost: 'broker:29092'});
    // The consumer object specifies the client and topic(s) it subscribes to
    consumer = new Consumer(
        client, [
          { topic: 'CLIENT_1_ANALYTICS_2', partitions: 1, offset: 0 }
        ], {
          autoCommit: true,
          fromOffset: true
        });


// Setup basic express server
var app = require('express')();
var path = require('path');
var server = require('http').createServer(app);
var io = require ('socket.io') (server);
var port = process.env.PORT || 3000;

server.listen(port, () => {
  console.log('Server listening at port %d', port);
});


// Routing
app.get('/', function (req, res) {
  res.sendFile(__dirname + '/public/index.html');
});


// map (actually an object) with rooms as keys and room visits as values
var room_popularity = {};


// when we get a websocket connection, return current room popularity data
io.on('connection', (socket) => {
  console.log('new connection, socket.id: ' + socket.id);
  console.log(room_popularity);
  socket.emit('kafka update', room_popularity);
});


// Update popularity data on new kafka message
consumer.on('message', function (message) {

    var data = JSON.parse(message.value);
    console.log(data);

    room_popularity[data.ROOM] = data.VISITS;
});
