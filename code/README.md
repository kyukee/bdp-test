# This directory is about the code.

### Platform Technologies

This architecture uses Kafka, KSQL, MongoDB and Node.js (with express, kafka-node and socket.io)

### Platform components

Kafka nodes:

- 1 zookeeper
- 1 broker
- 1 schema-registry
- 1 kafka-connect
- 1 rest-proxy

KSQL nodes:

- 1 ksql server
- 1 ksql cli

MongoDB nodes:

- 1 config server
- 1 shard (2 node replica set)
- 1 router

Node.js:

- 1 server

### Analytics

Streaming analytics - ANALYTICS_1 - filters events by time of day. Only accepts events between 10:00 and 18:00.

Batch analytics - ANALYTICS_2 - uses the events already filtered by ANALYTICS_1 and computes the amount of visits to each room. Also, this is processed in windows of 1 day. This data can be used to show the popularity of each room, in a certain day.

### Platform structure

1. A python script (helper_scripts/insertIntoTopic.py) acts as a kafka producer. It takes a csv file, transforms it into json messages and sends them to a specific kafka topic and broker.

2. The messages are forwarded from the broker to ksql.

3. Using ksql stream analytics, the data inserted into the initial topic will automatically be processed by the ksql server and the result is sent to another topic (ANALYTICS_1).

4. The data from ANALYTICS_1 is fed into a MongoDB sink and stored in our MondoDB cluster.

5. Using the data from ANALYTICS_1, the ksql server produces more analytics (ANALYTICS_2).

6. The data from ANALYTICS_2 is forwarded to the Node.js server. The server keeps a list of the most recent data (how many times each room is used in a day).
When a new message is received by the server from a kafka topic, the server updates its data with the new values.

7. When a user connects to the Node.js endpoint, the server sends him the most recent room usage data.
