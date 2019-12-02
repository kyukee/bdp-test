#!/bin/bash

echo ">>> starting bootstrap actions..."

echo ">>> config node initializing"
docker-compose exec config01 sh -c "mongo --port 27017 < /database_scripts/init-configserver.js"

echo ">>> shard01 node initializing"
docker-compose exec shard01a sh -c "mongo --port 27018 < /database_scripts/init-shard01.js"

echo ">>> waiting 10 secs"
sleep 10

echo ">>> adding shards via router"
docker-compose exec router sh -c "mongo --port 27017 < /database_scripts/init-router.js"

echo ">>> waiting 10 secs"
sleep 10

echo ">>> setup sample data model"
docker-compose exec router sh -c "mongo --port 27017 < /database_scripts/init-datamodel.js"

echo ">>> bootstrap finished!"
