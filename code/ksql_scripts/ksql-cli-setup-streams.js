SET 'auto.offset.reset'='latest';
CREATE STREAM client_1_ksql_in (part_id VARCHAR, \
                             ts_date VARCHAR, \
                             ts_time VARCHAR, \
                             room VARCHAR) \
        WITH (KAFKA_TOPIC='client_1_in', \
        VALUE_FORMAT='JSON');
CREATE STREAM client_1_analytics_1 AS \
    SELECT * \
    FROM CLIENT_1_KSQL_IN \
    WHERE ts_time between '10:00' and '18:00';
CREATE TABLE client_1_analytics_2 AS \
    SELECT room, COUNT(room) AS visits \
    FROM client_1_analytics_1 \
    WINDOW TUMBLING (SIZE 1 DAY) \
    GROUP BY room;
SHOW TOPICS;
SHOW STREAMS;
SHOW TABLES;
