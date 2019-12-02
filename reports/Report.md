# Report for Assignment 3

## Part 1 - Design for streaming analytics

### 1.

The selected dataset is the Indoor Location Detection, chosen from the datasets provided for this assignment. It contains 4 different fields:

- part_id: The user ID, which should be a 4-digit number

- ts_date: The recording date, which follows the “YYYYMMDD” format, e.g. 14 September 2017, is formatted as 20170914

- ts_time: The recording time, which follows the “hh:mm:ss” format

- room: The room which the person entered on the specific date and time (It is assumed that the person remained in the room till the next recording of the same day).

The streaming analytics which will be applied will be a filter that only takes events that happened in a certain interval of time, such as during work hours.

For the batch analytics, the result of the streaming analytic will be used as input. The batch interval will be 1 day. We will calculate which room is the most used in that day, for that period of time.

### 2.

In this case, the streaming processing shouldn't use a key but the batch processing should.
Since we will calculate values regarding every different room, it makes sense to separate the inputs according to the room field.

In terms of delivery guarantees provided, it should be at-least-one. We don't want at-most-once so we don't run the risk of losing data, but we also don't need exactly-once, because this introduces coordination and complicated transactional systems that slow things down. It is acceptable to have duplicate messages if there are timestamps in them, since it is possible to remove the duplicates using timestamps.

### 3.

In terms of event time, ingestion time and processing time, we shouldn't need to be concerned about any of these for this scenario.
The event time is almost instantaneous since it's just a sensor activating when someone enters a room.
The ingestion time can be looked over since the only delay consists of ETL operations like transforming a csv file into json.
And we won't be using a window for the streaming analytics, so that isn't something to worry about.

In terms of windows, as previously said, the streaming analytics will not have a window, but the batch analytics will.
For the streaming, we want to have a separate dataset with events that happened only during a certain time period. It is more useful if we have this data for every day instead of just a window. This information can be used later for more processing.
In regards to the batch processing, a window will be used since if we want to have data about how much a room is used, it only makes sense if we look at the data over a certain period of time.

### 4.

An important metric is the latency (the amount of time it takes for the data to be processed) and another metric is the throughput, which is the amount of data that can be processed at the same time, in a certain period of time (usually in a second).
We want to maximize throughput and minimize latency.
Another aspect worth considering is data reliability. Ideally, the amount of missing or duplicated records should be zero.
In this dataset in particular, we should worry more about throughput, since in the worst case scenario there are many sensors in a house, many people constantly activating them and also many different houses with sensors installed. The amount of events being received can grow very quickly.
The lower the latency, the sooner the client can know when someone moves into a room. For this application, we could have a latency of seconds or even a few minutes, since knowing when someone enters a room is not something very critical like a banking system.

### 5.

##### Here are the components:

- customer data sources: Kafka producer sending json messages
- mysimbdp message broker: Kafka
- mysimbdp streaming computing service: KSQL
- customer streaming analytics app: Node.js server
- mysimbdp-coredms: mongodb

##### The architecture is as follows:

The customer creates a Kafka producer to insert messages into a Kafka topic. This can be done with a script or some other way.

Then, when the KSQL server receives the messages from the Kafka broker, it processes the required analytics. The analytics results are then sent back to other Kafka topics.

MongoDB will be a consumer for the Kafka topic which corresponds to the streaming analytics data, and then store the processed data it receives.

The Node.js server will be a consumer to the batch analytic Kafka topic and provide this data to the client, accessible through an internet endpoint.

##### The reasons for these components:

The Kafka producer, Kafka cluster and MongoDB cluster are all being reused from previous assignments.

The task of producing messages, sending them to Kafka and storing them in MongoDB was already implemented. The aspect that is missing is the analytics part.

The reason why I used these 3 components, besides the fact that I could reuse previous work, is that they also fit the criteria perfectly.

For the message broker, what we need is to be able to do is the streaming analytics and then sending the results back to the client, all of this in near-real time. Kafka is a scalable, fault-tolerant, publish-subscribe messaging system that enables developers to build globally distributed applications and powers web-scale Internet companies such as LinkedIn, Twitter, AirBnB, Netflix, and many others. Kafka is well known for providing excellent performance at any scale, strong data durability, and low-latency queries.

In the case of the database, MongoDB was used because it is a very simple and easy to use technology that fulfills the requirement of supporting multi-tenancy.

When thinking about the streaming analytics, there are two main options: KSQL and Kafka Streams. These technologies are appealing because they are integrated closely within the Kafka ecosystem. And KSQL seems to be the better option.

With KSQL, you can write real-time streaming applications by using a SQL-like query language. It is built on top of Kafka Streams, which is a robust stream processing framework that is part of Kafka.
KSQL gives you a higher level of abstraction for implementing real-time streaming on Kafka topics. KSQL automates much of the complex programming that’s required for real-time operations on streams of data, so that one line of KSQL can do the work of a dozen lines of Java and Kafka Streams.

Finally, there's the app used for visualizing the customer analytics. In this case, Node.js is a standard for large-scale apps. Node.js thrives in building real-time applications, Internet of Things, and microservices. Another appealing apect is that there are node packages which already implement Kafka consumers and producers. Using already existing libraries makes development easier and faster, besides also being more reliable, since developing software always has the risk of creating things with bugs.

As a final note, this is something that applies to all the chosen components, I generally like to use technologies which have good documentation and many learning resources available.

### Part 2 - Implementation of streaming analytics


### 1.

Let's recall the data structure of our data. There are 4 fields: part_id, ts_date, ts_time and room. See part 1, question 1 for more details.

**How the data format changes throughout it's journey, step by step:**

In the initial csv file:

`1084,20180315,18:02:36,hall`

After it's converted to json, what the kafka producer script sends to the client_1_in kafka topic:

`{'records': [{'value': {'part_id': '1101', 'ts_date': '20180718', 'ts_time': '18:17:37', 'room': 'yard'}}]}`

How different Kafka topics store it:

- client_1_in (where the data enters kafka)

`{"part_id":"1085","ts_date":"20180315","ts_time":"18:19:44","room":"livingroom"}`

- CLIENT_1_ANALYTICS_1 (result of streaming analytics)

`{"PART_ID":"1086","TS_DATE":"20180212","TS_TIME":"14:43:56","ROOM":"livingroom"}`

- CLIENT_1_ANALYTICS_2 (resuly of batch analytics)

`{"ROOM":"kitchen","VISITS":77}`

**Some notes about the data formats**

Since the analytics streaming implemented in this project is basically just a filter, the data format before and after the streaming analytics processing is essentially the same, but with the slight difference of the fields now being in upper case.

These snippets were taken from actual data, they're from the output of commands used to get data from a kafka topic.

**Serialization/Deserialization**

Every Kafka Streams application must provide SerDes (Serializer/Deserializer) for the data types of record keys and record values, but since KSQL is being used, all of the processing is done automatically and is not visible to the developer. The user just writes queries similar to SQL queries to describe what operations he wants done and then the processing happens hidden from the developer. KSQL is a high level abstraction of Kafka Streams.

KSQL uses the stream details to automatically use the correct Serializer.

Here is the definition of the stream analytics on KSQL:

```
CREATE STREAM client_1_ksql_in (part_id VARCHAR, \
                               ts_date VARCHAR, \
                               ts_time VARCHAR, \
                               room VARCHAR) \
WITH (KAFKA_TOPIC='client_1_in', \
VALUE_FORMAT='JSON');
```

As you can see, all of the fields are strings so KSQL will see this stream's definition and use the default string Serializer/Deserializer in the background.

### 2.

Here is the exact code used to process the streaming analytics:

```
CREATE STREAM client_1_analytics_1 AS \
    SELECT * \
    FROM CLIENT_1_KSQL_IN \
    WHERE ts_time between '10:00' and '18:00';
```

Remember that we are using KSQL so our processing is done through high level sql-like queries.

What this query does is simply filter all the records to find which ones are in a certain time-frame.

Let's go step by step through the instructions:

Line 1 - The created stream will be called client_1_analytics_1 (it will actually end up as CLIENT_1_ANALYTICS_1)

Line 2 - the end result has all the same fields as the original records.

Line 3 - The source for this processing is the CLIENT_1_KSQL_IN topic. (this is the topic where the data first enters Kafka)

Line 4 - We only send to the new topic the records whose ts_time field is between the hours of the day 10:00 and 18:00.

### 3.

To see the operation of the streaming processing we will use the following command during execution:

`time docker-compose exec zookeeper kafka-console-consumer --bootstrap-server broker:29092 --topic CLIENT_1_ANALYTICS_1 --from-beginning --max-messages 500 > ../logs/performance_500_records_N_producer.log
`

What this command does is see how much time does it take for the streaming analytics to produce 500 messages. In the log name, N signifies the number of Kafka producers inserting data at the same time. All of the output of each command can be found in the logs directory.

For the multiple Kafka producers, what was done was a simple change to the python producer script (at helper_scripts/insertIntoTopic.py) that forks the process at the beggining of the script.

The data I obtained was the following:

| Number of Kafka producers | Time for analytics processing of 500 messages      |
| ----- | ---------- |
|   1   | 1.47s user 0.36s system 19% cpu 9.350 total |
|   2   | 1.55s user 0.40s system 16% cpu 11.574 total |
|   3   | 1.62s user 0.41s system 16% cpu 12.624 total |
|   4   | 1.55s user 0.46s system 12% cpu 16.404 total |
|   5   | 1.47s user 0.47s system 9% cpu 19.442 total |

The difference in environments was the amount of Kafka producers.

In terms of performance observations:

- The amount of time to execute the same task increases linearly

- The cpu on the test machine was at full load all the time during all the tests. It is safe to assume that the only reason there was a slowdown every time the amount of producers increased was because of a lack of physical resources.

- Under ideal conditions Kafka would be able to handle millions of messages

### 4.

This platform is actually very resilient against errors. All of the fields in a record are stored as strings so it's not possible to send a value in a wrong format because everything will be seen as a string. Additional fields do not matter. Missing fields also do not cause an error but the problem is that if for example a record does not have a time field and an analytic filters records by that same time field, then it will simply not do anything with that record. Even sending fields with random names does not do anything. They will simply be uploaded with those random fields and since they have no relevant fields for any analytics processing, they will simply be ignored.

So, to summarize, none of these cause any sort of error, wether they are uploaded or present within the data sources:

- Additional fields
- Missing fields
- Completely different fields

### 5.

In terms of parallelism, what can be done to increase it is to simply add more nodes of everything. This architecture scales very well horizontally. More kafka producers, more kafka clusters, more ksql servers and more MongoDB shard nodes. Also, using a key for the kafka streams and MongoDB collections.

To do this all that is needed is to use the '--scale' parameter of docker-compose, for example. In addition, it is also possible to scale each service independently of each other.

Another approach is to specify the number of replicas directly in the compose file.

I attempted to test parallelism but I could not deploy this project on a computer powerful enough to run it. It was extremely slow and unresponsive.

### Part 3 - Connection

### 1.

This is already implemented. All that needs to be done is to have a sink that is configured to listen to the relevant Kafka topics where the analytics results are stored.

All that is needed is to configure the sink with all the needed settings like
the MongoDB port, database, collection, etc.

### 2.

The currently implemented batch analytics looks at the output of the streaming analytics in windows of 1 day. It processes the amount of visits per day but it only displays the current day data to the customer.

One way of satisfying the requirements of this question by analyzing historical data would be to show the amount of visits to each room, by day, for every day. All this requires is to save the output of the batch analytics to a database.

### 3.

So let's say the data we have also had an 'alert' field and it could be either 'safe' or 'warning'. We want to trigger batch analytics when there are too many 'warning' values in a short time-frame.

With KSQL, you can filter and react to events in real time rather than performing historical analysis of record data from cold storage.

One way of implementing this would be to have separate batch processing that calculates the amount of 'warning' values, with a window of 1 hour or so.

And then, if the value is above a certain threshold, an alert is sent to the appropriate Kafka topic to begin it's job.

This would have to be implemented with Kafka Streams, though, since KSQL is similar to SQL and does not have any way of sending messages or other such things.

### 4.

For scaling up mysimbdp, the most important components would be the KSQL servers, since they are doing most of the processing and should be the only bottleneck.

A technique I would use is to follow a lambda architecture and separate the streaming and batch analytics.

### 5.

Yes, exactly-once delivery is possible here.

Stream processing applications written in the Kafka Streams library can turn on exactly-once semantics by simply making a single config change, to set the configuration option named “processing.guarantee” to “exactly_once”, with no code change required.
