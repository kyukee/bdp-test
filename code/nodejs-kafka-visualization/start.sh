#!/usr/bin/env bash
echo "Waiting until the topic is created"
until kafkacat -b broker:29092 -L | grep CLIENT_1_ANALYTICS_2
do
  sleep 1
done
echo "Topic has been created. Running npm start."
npm start
