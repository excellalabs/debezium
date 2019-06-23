# Debezium Deployment
CI/CD pipeline for deploying Debezium Connector for RDS PostgreSQL. This will deploy the connector in a Fargate docker container.

## Tech Stack
  * Ruby
  * Cloudformation
  * Docker
  * Amazon Fargate
  * Amazon ECR
  * JMX Exporter
  * Debezium Connect
  * Jenkins

## Dependencies
  * [aws ruby sdk](https://aws.amazon.com/sdk-for-ruby/)
  * [keystore](https://github.com/stelligent/keystore)
  * [minimal pipeline](https://github.com/stelligent/minimal-pipeline-gem)
  * Apache Kafka
  * Zookeeper
  * Kafka Connect

# What is Debezium?
Debezium is a distributed platform that turns your existing databases into event streams, so applications can see and respond immediately to each row-level change in the databases. Debezium is built on top of [Apache Kafka](http://kafka.apache.org/) and provides [Kafka Connect](http://kafka.apache.org/documentation.html#connect) compatible connectors that monitor specific database management systems. Debezium records the history of data changes in Kafka logs, from where your application consumes them. This makes it possible for your application to easily consume all of the events correctly and completely. Even if your application stops (or crashes), upon restart it will start consuming the events where it left off so it misses nothing.

# Running Debezium with Docker
Running Debezium involves three major services: [Zookeeper](http://zookeeper.apache.org/), [Kafka](http://kafka.apache.org/), and [Debezium](https://debezium.io)’s connector service. [This tutorial](https://debezium.io/docs/tutorial/) walks you through starting a single instance of these services using Docker and Debezium’s Docker images. Production environments, on the other hand, require running multiple instances of each service to provide the performance, reliability, replication, and fault tolerance. This can be done with a platform like [Amazon ECS](https://aws.amazon.com/ecs/), [OpenShift](https://www.openshift.com/) and [Kubernetes](http://kubernetes.io/) that manages multiple Docker containers running on multiple hosts and machines, but often you’ll want to [install on dedicated hardware](https://debezium.io/docs/install/).

## Connector Configuration
```json
{
  "name": "debezium-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "tasks.max": "number tasks - 1 in usual cases",
    "database.hostname": "<db host name>",
    "database.port": "<db port>",
    "database.user": "<db user>",
    "database.password": "<db password>",
    "database.dbname": "<database name>",
    "database.server.name": "<server name>",
    "schema.whitelist": "<comma seperated list of schemas>"
  }
}
```
##### For Postgres on Amazon RDS
```json
{
  "plugin.name": "wal2json_rds"
}
```
To get it running you must fulfill the following conditions
* The instance parameter <span style="color:darkred">`rds.logical_replication`</span> is set to <span style="color:darkred">`1`</span>.
* Verify that <span style="color:darkred">`wal_level`</span> parameter is set to <span style="color:darkred">`logical`</span>; this might not be the case in multi-zone replication setups.
* Set <span style="color:darkred">`plugin.name`</span> Debezium parameter to <span style="color:darkred">`wal2json`</span>.
* Use database master account for replication as RDS currently does not support setting of <span style="color:darkred">`REPLICATION`</span> privilege for another account.


For *flattening* the events, we can add more properties:
```json
{
  "transforms": "unwrap",
  "transforms.unwrap.type": "io.debezium.transforms.UnwrapFromEnvelope",
  "transforms.unwrap.drop.tombstones": "false"
}
```

## Environment Variables
Basic configuration:
```sh
export BOOTSTRAP_SERVERS=localhost:9092
export CONFIG_STORAGE_TOPIC='dbz_connect_configs'
export GROUP_ID=1
export OFFSET_STORAGE_TOPIC='dbz_connect_offsets'
export STATUS_STORAGE_TOPIC='dbz_connect_statuses'
```
If you do not want schema in the events body:
```sh
export CONNECT_KEY_CONVERTER_SCHEMAS_ENABLE=false
export CONNECT_VALUE_CONVERTER_SCHEMAS_ENABLE=false
```
For JMX monitoring and metrics:
```sh
export KAFKA_OPTS=-javaagent:/kafka/jmx_prometheus_javaagent.jar=7071:/pass/to/config.yml
export JMX_PORT=6001
```

## REST Interface
Since Kafka Connect is intended to be run as a service, it also supports a REST API for managing connectors. By default this service runs on port <span style="color:darkred">`8083`</span>. When executed in distributed mode, the REST API will be the primary interface to the cluster. You can make requests to any cluster member; the REST API automatically forwards requests if required.
Currently the top level resources are <span style="color:darkred">`connector`</span> and <span style="color:darkred">`connector-plugins`</span>. The sub-resources for <span style="color:darkred">`connector`</span> lists configuration settings and tasks and the sub-resource for <span style="color:darkred">`connector-plugins`</span> provides configuration validation and recommendation.

#### Connectors
<span style="color:darkred">```GET /connectors```</span> Get a list of active connectors
##### Example request:
```sh
GET /connectors HTTP/1.1
Host: connect.example.com
Accept: application/json
```
##### Example response:
```sh
HTTP/1.1 200 OK
Content-Type: application/json

["my-jdbc-source", "my-hdfs-sink"]
```

##### Create Connectors
```sh
curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d @config.json
```
[This](#connector-configuration) is the configuration json structure.

##### Connectos Status
```sh
curl http://localhost:8083/connectors/{connector-name}/status
```

Check [here](https://docs.confluent.io/current/connect/references/restapi.html) for the full Kafka Connect REST endpoints.

## Events
All data change events produced by the PostgreSQL connector have a key and a value, although the structure of the key and value depend on the table from which the change events originated. Check [here](https://debezium.io/docs/connectors/postgresql/#events) for more information.

##### Sample Event With Schema
```json
{
  "schema": {
    "type": "struct",
    "fields": [
      {
        "type": "struct",
        "fields": [
          {
            "type": "int32",
            "optional": false,
            "field": "id"
          },
          {
            "type": "string",
            "optional": false,
            "field": "name"
          }
        ],
        "optional": true,
        "name": "db.public.contacts.Value",
        "field": "before"
      },
      {
        "type": "struct",
        "fields": [
          {
            "type": "int32",
            "optional": false,
            "field": "id"
          },
          {
            "type": "string",
            "optional": false,
            "field": "name"
          }
        ],
        "optional": true,
        "name": "db.public.contacts.Value",
        "field": "after"
      },
      {
        "type": "struct",
        "fields": [
          {
            "type": "string",
            "optional": true,
            "field": "version"
          },
          {
            "type": "string",
            "optional": false,
            "field": "name"
          },
          {
            "type": "string",
            "optional": false,
            "field": "db"
          },
          {
            "type": "int64",
            "optional": true,
            "field": "ts_usec"
          },
          {
            "type": "int64",
            "optional": true,
            "field": "txId"
          },
          {
            "type": "int64",
            "optional": true,
            "field": "lsn"
          },
          {
            "type": "string",
            "optional": true,
            "field": "schema"
          },
          {
            "type": "string",
            "optional": true,
            "field": "table"
          },
          {
            "type": "boolean",
            "optional": true,
            "default": false,
            "field": "snapshot"
          },
          {
            "type": "boolean",
            "optional": true,
            "field": "last_snapshot_record"
          }
        ],
        "optional": false,
        "name": "io.debezium.connector.postgresql.Source",
        "field": "source"
      },
      {
        "type": "string",
        "optional": false,
        "field": "op"
      },
      {
        "type": "int64",
        "optional": true,
        "field": "ts_ms"
      }
    ],
    "optional": false,
    "name": "db.public.contacts.Envelope"
  },
  "payload": {
    "before": null,
    "after": {
      "id": 1,
      "name": "John Doe"
    },
    "source": {
      "version": "0.8.3.Final",
      "name": "db",
      "db": "postgres",
      "ts_usec": 1551298964946376,
      "txId": 578,
      "lsn": 23991559,
      "schema": "public",
      "table": "contacts",
      "snapshot": false,
      "last_snapshot_record": null
    },
    "op": "c",
    "ts_ms": 1551298965161
  }
}
```
#### Sample Event Without Schema
```json
{
  "before": null,
  "after": {
    "id": 1,
    "name": "John Doe"
  },
  "source": {
    "version": "0.9.1.Final",
    "connector": "postgresql",
    "name": "db",
    "db": "postgres",
    "ts_usec": 1551297408166568,
    "txId": 585,
    "lsn": 24302704,
    "schema": "public",
    "table": "contacts",
    "snapshot": false,
    "last_snapshot_record": null
  },
  "op": "c",
  "ts_ms": 1551297408465
}
```
#### Sample Flattened Event
```json
{
  "id": 3,
  "name": "John Doe"
}
```
