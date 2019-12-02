#!/bin/bash

echo ">>> setting up the database"
./helper_scripts/bootstrap_mdb.sh

echo ">>> creating kafka source topic"
docker-compose exec broker kafka-topics --create --zookeeper zookeeper:2181 \
--replication-factor 1 --partitions 1 --topic client_1_in

echo ">>> configuring analytics streams"
./helper_scripts/ksql-configure-streams.sh

echo ">>> setting up the sink connector from kafka topic to mongo"
curl -X PUT http://localhost:8083/connectors/sink-mongodb-apps/config -H "Content-Type: application/json" -d ' {
      "connector.class":"com.mongodb.kafka.connect.MongoSinkConnector",
      "tasks.max":"1",
      "topics":"CLIENT_1_ANALYTICS_1",
      "connection.uri":"mongodb://router:27017/blogpost?w=1&journal=true",
      "database":"indoor_location",
      "collection":"house_1",
      "key.converter":"org.apache.kafka.connect.json.JsonConverter",
      "key.converter.schemas.enable":false,
      "value.converter":"org.apache.kafka.connect.json.JsonConverter",
      "value.converter.schemas.enable":false
}'

printf "\n"

echo ">>> inserting dataset into the database"
python3 helper_scripts/insertIntoTopic.py ../data/Indoor_Location_Detection_Dataset.csv client_1_in

printf "\n### CLIENT_1_ANALYTICS_1 data is accessible on mongodb. Use ./read-data-from-mongo.sh to read it\n"

printf "\n### CLIENT_1_ANALYTICS_2 data is visible on the endpoint: http://localhost:3000/\n"