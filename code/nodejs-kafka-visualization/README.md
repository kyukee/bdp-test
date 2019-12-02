This is a nodejs project that provides an endpoint, accessible from a browser, that alçows the user to visualize the data in a kafka topic.

The topic that is being used for this implementation in particular is CLIENT_1_ANALYTICS_2, which is the topic that shows the rooms in the dataset, ordered by popularity.

Also, it is worth remembering that the dataset is based on events where we get the time, date and person, as they enter a room in a house.

Cobbled together with code samples from:

* [socket.io](https://github.com/socketio/socket.io) for websocket communication between Kafka client and web browser.
* [kafka-node](https://www.npmjs.com/package/kafka-node) for a Node.js client for Apache Kafka 0.9 and later.