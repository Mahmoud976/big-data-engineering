# Tools Usage Guide

This repository runs a Big Data lab with Docker Compose. The Compose file is the source of truth for service names, profiles, ports, volumes, and container-to-container hostnames.

## Start and stop

Run commands from the repository root:

```bash
# Core Hadoop group: ZooKeeper, NameNode, and three DataNodes
docker compose up -d

# All profiles and services
docker compose --profile "*" up -d

# Individual groups
docker compose --profile hive-query up -d
docker compose --profile hue up -d
docker compose --profile notebooks-stream-processing up -d
docker compose --profile hbase up -d
docker compose --profile data-ingestion up -d
docker compose --profile kafka-monitoring up -d
docker compose --profile analytics up -d

# Status, logs, and stopping
docker compose ps
docker compose logs -f <service>
docker compose stop <service>
docker compose down
```

The core Hadoop services are included whenever a profile is started. Data is persisted in `base/`, so do not delete those directories unless you intend to reset the lab.

## Host access and container access

Use `localhost` and the published port from applications running on the host. Use the Compose service name and the container port from another service in the Compose network.

```text
Host application:       http://localhost:50070
Container application:  http://namenode:50070
HDFS client in a container: hdfs://namenode:8020
```

Prefer service names such as `namenode`, `hive-server`, `kafka`, and `zookeeper` instead of relying on the fixed `net_pet` IP addresses.

## Hadoop HDFS

| Service | Host endpoint | How to use |
|---|---|---|
| NameNode | [http://localhost:50070](http://localhost:50070) | Open the HDFS UI. HDFS clients use `hdfs://namenode:8020`. WebHDFS is available at `http://localhost:50070/webhdfs/v1`. |
| DataNode 1 | [http://localhost:50075](http://localhost:50075) | Open the DataNode status page. Data is persisted in `base/hdfs/datanode1`. |
| DataNode 2 (`datanode2`) | [http://localhost:50080](http://localhost:50080) | Open the DataNode status page. Its container port remains `50075`; `50080` is only the host port. |
| DataNode 3 (`datanode3`) | [http://localhost:50085](http://localhost:50085) | Open the DataNode status page. Its container port remains `50075`; `50085` is only the host port. |

Useful commands:

```bash
docker compose exec namenode hdfs dfs -mkdir -p /data/input
docker compose exec namenode hdfs dfs -ls -R /data
docker compose cp ./file.csv namenode:/tmp/file.csv
docker compose exec namenode hdfs dfs -put /tmp/file.csv /data/input/
docker compose exec namenode hdfs dfs -cat /data/input/file.csv
```

## ZooKeeper

ZooKeeper starts with the core stack. Connect from the host at `localhost:2181`, or from another Compose service at `zookeeper:2181`. Kafka uses this service for coordination. Inspect it with `docker compose logs -f zookeeper`; data is persisted in `base/zookeeper`.

## Hive and Presto

Start them with:

```bash
docker compose --profile hive-query up -d
```

| Service | Host endpoint | How to use |
|---|---|---|
| Hive Metastore PostgreSQL | Internal: `hive-metastore-postgresql:5432` | Stores Hive metadata. It is not published to the host. |
| Hive Metastore | `localhost:9083` | Hive clients inside the network use `thrift://hive-metastore:9083`. |
| Hive Server | `localhost:10000` | Use Beeline or a HiveServer2 client. Example: `beeline -u 'jdbc:hive2://hive-server:10000/default'`. |
| Presto | [http://localhost:18080](http://localhost:18080) | Open the coordinator UI. From a container use `presto --server presto:8080 --catalog hive --schema default`. |

Example Hive commands:

```bash
docker compose exec hive-server beeline -u 'jdbc:hive2://hive-server:10000/default'  #This will enter you in interactive shell, use Hue instead
docker compose exec hive-server beeline -u 'jdbc:hive2://hive-server:10000/default' -e 'SHOW DATABASES;'
docker compose exec hive-server beeline -u 'jdbc:hive2://hive-server:10000/default' -e 'CREATE TABLE IF NOT EXISTS users (id INT, name STRING);'
```

Hive table data is stored in HDFS. Check NameNode and HDFS state before troubleshooting Hive queries.

## Hue and MySQL

Start them with:

```bash
docker compose --profile hue up -d
```

| Service | Host endpoint | How to use |
|---|---|---|
| Hue | [http://localhost:8888](http://localhost:8888) | Use the web UI for HDFS and configured SQL tools. The documented initial login is `admin` / `admin`; change it for any non-local deployment. |
| Hue metadata MySQL | `localhost:33061` | Connect with user `root`, password `secret`, database `hue`: `mysql -h 127.0.0.1 -P 33061 -u root -p hue`. Inside Compose use `hue_metadata_database:3306`. |

Hue configuration is in `base/hue/hue-overrides.ini`. MySQL data is persisted in `base/mysql/data`.

## Jupyter Spark

Start it with:

```bash
docker compose --profile notebooks-stream-processing up -d
```

Open [http://localhost:8889](http://localhost:8889). The Compose service is `jupyter-spark`. Notebooks are mounted from `base/notebooks`. Spark runs in local mode (`local[*]`), and Spark application UIs may use ports `4040` through `4043`. The environment is defined in `base/jupyter/jupyter.env`.

### Deploy a Spark notebook as a Python script

Notebook files on the host are mounted at `/mnt/notebooks` inside `jupyter-spark`. Convert a notebook to a Python script with `nbconvert`:

```bash
# Convert base/notebooks/analysis.ipynb to base/notebooks/analysis.py
docker compose exec jupyter-spark \
	jupyter nbconvert --to script /mnt/notebooks/analysis.ipynb \
	--output-dir /mnt/notebooks
```

Before deployment, clean the generated script so it contains executable Python only:

- Remove notebook-only commands such as `%matplotlib`, `%time`, and `!shell-command`.
- Move reusable imports and configuration into the script.
- Replace display-only expressions with `print()` or file output.
- Make sure the script has a clear entry point and does not depend on notebook variables created in an earlier cell.
- Use paths visible to the container, such as `/mnt/notebooks/data.csv` or `hdfs://namenode:8020/data/input/data.csv`.

For repeatable jobs, use a `main()` function and an explicit Spark shutdown:

```python
from pyspark.sql import SparkSession


def main() -> None:
		spark = SparkSession.builder.appName("analysis").getOrCreate()
		try:
				data = spark.read.csv("hdfs://namenode:8020/data/input/data.csv", header=True)
				data.groupBy("category").count().write.mode("overwrite").parquet(
						"hdfs://namenode:8020/data/output/category_counts"
				)
		finally:
				spark.stop()


if __name__ == "__main__":
		main()
```

Submit the generated script as a Spark job from the Jupyter/Spark container:

```bash
docker compose exec jupyter-spark \
	/opt/spark/bin/spark-submit \
	--master local[*] \
	--name analysis \
	/mnt/notebooks/analysis.py
```

The job runs in Spark local mode in this stack. Monitor its application UI at [http://localhost:4040](http://localhost:4040) while the job is active. For a file on the host that is not under `base/notebooks`, copy it into the mounted notebook directory first, or use `docker compose cp`.

## Flink

Flink is started by the same `notebooks-stream-processing` profile. The stack builds a Python-enabled Flink 1.20.3 image and starts one health-gated TaskManager with two task slots. Open the JobManager UI at [http://localhost:8082](http://localhost:8082). The container UI port is `8081`; port `6123` is used for JobManager RPC.

Check Python and PyFlink inside the JobManager:

```bash
docker compose exec flink python3 --version
docker compose exec flink python3 -c "import pyflink; print(pyflink.__version__)"
```

Submit the repository example from a file copied into the container:

```bash
docker compose cp ./base/flink/example.py flink:/tmp/example.py
docker compose exec flink flink run --python /tmp/example.py
```

The Python job must use the same PyFlink version as the cluster, `1.20.3`. The TaskManager service is `flink-taskmanager`; it starts automatically with the profile and waits for the JobManager health check.

### Submit the Java JAR through the UI

The repository includes [FlinkJavaExample.jar](base/flink/FlinkJavaExample.jar). To submit it from the Flink UI:

1. Open [http://localhost:8082](http://localhost:8082).
2. Select **Submit New Job**.
3. Select **Add New** and upload `base/flink/FlinkJavaExample.jar`.
4. Select the uploaded JAR, set the entry class to `FlinkJavaExample`, and submit the job.

The JAR is built for Flink 1.20.3 and uses the cluster-provided Flink libraries, so it should be uploaded as-is without bundling the Flink runtime.

## HBase

Start it with:

```bash
docker compose --profile hbase up -d
```

Open the HBase Master UI at [http://localhost:16010](http://localhost:16010). HBase uses the existing NameNode, DataNodes, and ZooKeeper. Open the shell with:

```bash
docker compose exec hbase-master hbase shell
```

Example shell commands:

```text
status
create 'users', 'profile'
put 'users', '1', 'profile:name', 'Ada'
scan 'users'
```

## Sqoop

Start it with the `data-ingestion` profile:

```bash
docker compose --profile data-ingestion up -d
docker compose exec sqoop sqoop version
docker compose exec sqoop bash
```

The `sqoop` service intentionally stays alive with `tail -f /dev/null`, so use it as an interactive client. In this image the executable is `/usr/lib/sqoop/bin/sqoop`, not `sqoop` on `PATH`. A JDBC driver and a reachable source database are required.

### Load a database table into HDFS

The following example imports the `users` table from the stack's MySQL metadata database into HDFS. Replace the JDBC URL, table, and credentials when using another source database:

```bash
docker compose exec sqoop /usr/lib/sqoop/bin/sqoop list-databases \
	--connect jdbc:mysql://hue_metadata_database:3306 \
	--username root \
	--password secret

docker compose exec sqoop /usr/lib/sqoop/bin/sqoop import \
	--connect jdbc:mysql://hue_metadata_database:3306/hue \
	--username root \
	--password secret \
	--table users \
	--target-dir hdfs://namenode:8020/data/import/users \
	--num-mappers 1 \
	--delete-target-dir
```

The source database must be reachable from the `sqoop` container. `--target-dir` is an HDFS path, not a host filesystem path. Inspect the result with:

```bash
docker compose exec namenode hdfs dfs -ls -R /data/import/users
docker compose exec namenode hdfs dfs -cat /data/import/users/part-m-00000
```

For a table with an integer primary key, parallelize the import with `--num-mappers 2`. Add `--split-by id` to select the column used to divide work. Use `--delete-target-dir` only when replacing an existing HDFS export.

## Flume

Start it with the `data-ingestion` profile:

```bash
docker compose --profile data-ingestion up -d
```

The configured agent listens for plain TCP/netcat input on `localhost:44444` and logs events:

```bash
printf 'hello from flume\n' | nc 127.0.0.1 44444
docker compose logs -f flume
```

The source and sink are defined in `base/flume/flume.conf`. The current sink is a logger, not HDFS or Kafka.

### Transfer events from Flume to HDFS

The current configuration receives events on TCP port `44444` and prints them to the Flume log. To transfer them into HDFS, edit `base/flume/flume.conf` and replace the logger sink with an HDFS sink:

```properties
docker.sources = netcat-source
docker.sinks = hdfs-sink
docker.channels = memory-channel

docker.sources.netcat-source.type = netcat
docker.sources.netcat-source.bind = 0.0.0.0
docker.sources.netcat-source.port = 44444
docker.sources.netcat-source.channels = memory-channel

docker.sinks.hdfs-sink.type = hdfs
docker.sinks.hdfs-sink.hdfs.path = hdfs://namenode:8020/data/flume/%Y-%m-%d/%H
docker.sinks.hdfs-sink.hdfs.filePrefix = events
docker.sinks.hdfs-sink.hdfs.fileSuffix = .txt
docker.sinks.hdfs-sink.hdfs.fileType = DataStream
docker.sinks.hdfs-sink.hdfs.rollInterval = 30
docker.sinks.hdfs-sink.hdfs.rollSize = 0
docker.sinks.hdfs-sink.hdfs.rollCount = 0
docker.sinks.hdfs-sink.channel = memory-channel

docker.channels.memory-channel.type = memory
docker.channels.memory-channel.capacity = 1000
docker.channels.memory-channel.transactionCapacity = 100
```

Restart Flume after changing the mounted configuration:

```bash
docker compose restart flume
```

Send events from the host and inspect the HDFS output:

```bash
printf 'first event\nsecond event\n' | nc 127.0.0.1 44444
docker compose exec namenode hdfs dfs -ls -R /data/flume
docker compose exec namenode hdfs dfs -cat /data/flume/*/*/*
```

The Flume image must include the Hadoop HDFS sink dependencies and be able to resolve `namenode:8020`. If the sink fails, check `docker compose logs -f flume` and verify that the HDFS client libraries are present in the image.

## Kafka and Kafka Manager

Start them with:

```bash
docker compose --profile kafka-monitoring up -d
```

Kafka accepts host connections at `localhost:9092`; clients inside Compose should use `kafka:9092`. Kafka Manager (`kafkamanager`) is at [http://localhost:9000](http://localhost:9000). Its ZooKeeper connection is `zookeeper:2181`, and the broker address is `kafka:9092`.

Example commands, if the image contains the standard Kafka scripts:

```bash
docker compose exec kafka kafka-topics.sh --bootstrap-server kafka:9092 --create --topic demo --partitions 1 --replication-factor 1
docker compose exec kafka kafka-console-producer.sh --broker-list kafka:9092 --topic demo
docker compose exec kafka kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic demo --from-beginning
```

Kafka advertises `kafka` as its hostname. Host-native clients must therefore be able to resolve `kafka`, while container clients should use `kafka:9092`.

## Metabase

Start it with:

```bash
docker compose --profile analytics up -d
```

Open [http://localhost:3000](http://localhost:3000) to complete setup and add connections. Use Compose hostnames for databases, such as `hue_metadata_database` for MySQL or `hive-server` for HiveServer2-compatible access. Metabase data is persisted in `base/metabase/data`.

## Health checks and troubleshooting

```bash
docker compose ps
docker compose logs -f namenode datanode1 hive-metastore hive-server
docker network ls
docker network inspect docker-bigdata-tools_net_pet
docker compose exec hive-server getent hosts namenode hive-metastore
```

Allow the dependency chain to finish starting before using Hive, HBase, Kafka, or Hue. If a service fails after a previous experiment, inspect its logs first; persisted state in `base/` survives normal restarts.

## Port summary

| Tool | Host port |
|---|---:|
| ZooKeeper | 2181 |
| NameNode UI | 50070 |
| DataNode 1 UI | 50075 |
| DataNode 2 UI | 50080 |
| DataNode 3 UI | 50085 |
| Hive Metastore | 9083 |
| HiveServer2 | 10000 |
| Presto | 8080 |
| Hue | 8888 |
| Jupyter | 8889 |
| Spark application UIs | 4040-4043 |
| Flink UI | 8082 |
| HBase Master UI | 16010 |
| Flume TCP input | 44444 |
| Kafka | 9092 |
| Kafka Manager | 9000 |
| Hue metadata MySQL | 33061 |
| Metabase | 3000 |
