## To run the demo:

Go to the code folder and run the following:

- docker-compose up -d
- ./run.sh (wait a bit for the containers to be ready before running this script, cpu usage will be high)

The run.sh script will configure the entire environment, and inject some data into kafka.

There are two kafka topics which will have analytics data. One will write to mongodb and the other will provide an internet endpoint.

To read data from mongo:
- ./read-data-from-mongo.sh

To see the data in the endpoint:
- open http://localhost:3000/
