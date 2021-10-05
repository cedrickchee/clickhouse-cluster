# Tutorial: Creating a ClickHouse Cluster

Based on this tutorial: ["Creating a ClickHouse cluster - Part I: Sharding"](https://dev.to/zergon321/creating-a-clickhouse-cluster-part-i-sharding-4j20)

The final cluster has:
- 1 cluster, with 2 shards
- Each shard has 2 replica server
- clickhouse-servers:
    - Master node run at 127.0.0.1, ports 9000
    - Subordinate/worker nodes run at 127.0.0.1, ports 9001-9004

## Cluster Deployment

Now we are ready to launch the system. I will do it using `docker-compose`:

First, SSH to my Multipass VM (instance name is "clickhouse"). Then run:

```sh
$ cd ~/dev/tutorial/clickhouse-cluster

$ ~/dev/tutorial/clickhouse-cluster$ docker-compose up
Creating network "clickhouse-cluster_default" with the default driver
Creating volume "clickhouse-cluster_ch-master-data" with default driver
Creating volume "clickhouse-cluster_ch-master-logs" with default driver
Creating volume "clickhouse-cluster_ch-sub-1-data" with default driver
Creating volume "clickhouse-cluster_ch-sub-1-logs" with default driver
Creating volume "clickhouse-cluster_ch-sub-2-data" with default driver
Creating volume "clickhouse-cluster_ch-sub-2-logs" with default driver
Creating volume "clickhouse-cluster_ch-sub-3-data" with default driver
Creating volume "clickhouse-cluster_ch-sub-3-logs" with default driver
Pulling ch-sub-1 (yandex/clickhouse-server:19.14.13.4)...
19.14.13.4: Pulling from yandex/clickhouse-server
a1125296b23d: Pull complete
3c742a4a0f38: Pull complete
4c5ea3b32996: Pull complete
1b4be91ead68: Pull complete
8e89ff3b8b56: Pull complete
b54bb3d8e5ac: Pull complete
a955f5266cb6: Pull complete
d200f6bc678a: Pull complete
1250dc772f64: Pull complete
fad28a14cd72: Pull complete
dfe82dbaecba: Pull complete
Digest: sha256:ccf9c2b5e3f22dfda4d00b85d44fb37f90e49d119b9724160981508c31220070
Status: Downloaded newer image for yandex/clickhouse-server:19.14.13.4
Creating ch_sub_2 ... done
Creating ch_sub_1 ... done
Creating ch_sub_3 ... done
Creating ch_master ... done
Attaching to ch_sub_2, ch_sub_1, ch_sub_3, ch_master
ch_sub_1     | Poco::Exception. Code: 1000, e.code() = 0, e.displayText() = Not found: user_files_path (version 19.14.13.4 (official build)
ch_sub_1     | Poco::Exception. Code: 1000, e.code() = 0, e.displayText() = Not found: format_schema_path (version 19.14.13.4 (official build)
ch_sub_1     | Logging trace to /var/log/clickhouse-server/clickhouse-server.log
ch_sub_1     | Logging errors to /var/log/clickhouse-server/clickhouse-server.err.log
ch_sub_1     | Include not found: networks
ch_sub_2     | Poco::Exception. Code: 1000, e.code() = 0, e.displayText() = Not found: user_files_path (version 19.14.13.4 (official build)
ch_sub_2     | Poco::Exception. Code: 1000, e.code() = 0, e.displayText() = Not found: format_schema_path (version 19.14.13.4 (official build)
ch_sub_2     | Logging trace to /var/log/clickhouse-server/clickhouse-server.log
ch_sub_2     | Logging errors to /var/log/clickhouse-server/clickhouse-server.err.log
ch_sub_2     | Include not found: networks
ch_sub_3     | Poco::Exception. Code: 1000, e.code() = 0, e.displayText() = Not found: user_files_path (version 19.14.13.4 (official build)
ch_sub_3     | Poco::Exception. Code: 1000, e.code() = 0, e.displayText() = Not found: format_schema_path (version 19.14.13.4 (official build)
ch_sub_3     | Logging trace to /var/log/clickhouse-server/clickhouse-server.log
ch_sub_3     | Logging errors to /var/log/clickhouse-server/clickhouse-server.err.log
ch_sub_3     | Include not found: networks
ch_master    | Poco::Exception. Code: 1000, e.code() = 0, e.displayText() = Not found: user_files_path (version 19.14.13.4 (official build)
ch_master    | Poco::Exception. Code: 1000, e.code() = 0, e.displayText() = Not found: format_schema_path (version 19.14.13.4 (official build)
ch_master    | Logging trace to /var/log/clickhouse-server/clickhouse-server.log
ch_master    | Logging errors to /var/log/clickhouse-server/clickhouse-server.err.log
ch_master    | Include not found: networks
```

Noticed the errors. To fix, we need to modified `master-config.xml` and `sub-config.xml` that we get from the article's [project source](https://github.com/zergon321/clickhouse-clustering). Edit and add these lines in the two config files:

```xml
<user_files_path>/var/lib/clickhouse/user_files/</user_files_path>

...

<format_schema_path>/var/lib/clickhouse/format_schemas/</format_schema_path>
```

---

## Usage

Once we're done with the cluster deployment, the next step is interacting with the cluster.

Install Python packages and run:

```sh
$ make
```

Install or update Python packages:

```sh
$ make install
```

Run app only:

```sh
$ make run
```

##  Cluster Tables

After everything is up and running, it's time to create data tables.
For this task I will use Python programming language and [clickhouse-driver](https://pypi.org/project/clickhouse-driver/) library.
Now onto the first script, [create-cluster.py](./create-cluster.py):

```sh
$ python create-cluster.py
```

### Distributed Table on the Master Node

**Sharding key**

The sharding key is an expression whose result is used to decide which shard stores the data row depending on the values of the columns.
If you specify rand(), the row goes to the random shard. Sharding key is only applicable if you do INSERT operations on the master table (note that the master table itself doesn't store any data, it only aggregates the data from the shards during queries). But we can perform INSERT operations directly on the subordinate nodes:

```sh
$ python sub-1.py
```

You can insert any data you want to any node.

```sh
$ python sub-2.py
$ python sub-3.py
```

## Cluster Operations

Now try to connect to the master node via ClickHouse client:

```sh
$ docker run --network="clickhouse-cluster_default" -it --rm --link ch_master:clickhouse-server yandex/clickhouse-client:19.14.12.2 --host clickhouse-server
ClickHouse client version 19.14.12.2 (official build).
Connecting to clickhouse-server:9000 as user default.
Connected to ClickHouse server version 19.14.13 revision 54425.

39b6272b0804 :) 
```

When you are in, try to execute the next set of SQL instructions:

```sh
39b6272b0804 :) USE db
...

Ok.

0 rows in set. Elapsed: 0.003 sec.

39b6272b0804 :) SELECT * FROM entries
...
┌───────────timestamp─┬─parameter──┬─value─┐
│ 2021-10-05 06:55:09 │ elasticity │  38.9 │
└─────────────────────┴────────────┴───────┘
┌───────────timestamp─┬─parameter───┬─value─┐
│ 2021-10-05 06:40:00 │ temperature │  38.9 │
└─────────────────────┴─────────────┴───────┘
┌───────────timestamp─┬─parameter─┬─value─┐
│ 2021-10-05 06:55:09 │ density   │  19.8 │
└─────────────────────┴───────────┴───────┘
┌───────────timestamp─┬─parameter─┬─value─┐
│ 2021-10-05 06:40:00 │ density   │  12.3 │
└─────────────────────┴───────────┴───────┘
┌───────────timestamp─┬─parameter─┬─value─┐
│ 2021-10-05 06:55:09 │ gravity   │  27.2 │
└─────────────────────┴───────────┴───────┘
┌───────────timestamp─┬─parameter─┬─value─┐
│ 2021-10-05 06:40:00 │ humidity  │  27.2 │
└─────────────────────┴───────────┴───────┘
┌───────────timestamp─┬─parameter─┬─value─┐
│ 2021-10-05 06:46:12 │ humidity  │  39.8 │
└─────────────────────┴───────────┴───────┘
┌───────────timestamp─┬─parameter───┬─value─┐
│ 2021-10-05 06:46:12 │ temperature │ 88.13 │
└─────────────────────┴─────────────┴───────┘
┌───────────timestamp─┬─parameter─┬─value─┐
│ 2021-10-05 06:46:12 │ voltage   │  72.8 │
└─────────────────────┴───────────┴───────┘

9 rows in set. Elapsed: 0.021 sec.
```

If everything has been set up properly, you'll see all the data you sent to each shard.

Tear down cluster

```sh
# also remove volumes
$ docker-compose down -v
```

## Part 2: Enable Replication

This part is based on this article: ["Creating a ClickHouse cluster - Part II: Replication"](https://dev.to/zergon321/creating-a-clickhouse-cluster-part-ii-replication-23mc)

In the previous set up, we run ClickHouse in cluster mode using only sharding.
It's enough for load distribution, but we also need to ensure fault tolerance via replication.

### ZooKeeper

To enable native replication ZooKeeper is required.

(... see the article ...)

### Cluster Configuration

I will use 1 master with 2 shards, 2 replicas for each shard.

So, we are going to build a 2(shard) x 2(replica) = 6 node ClickHouse cluster.

Here's the deployments configuration:

(... see the article ...)

_The above configuration creates a 7 nodes cluster (+1 for ZooKeeper node)._

### Cluster Deployment

After all the config files are set up, we can finally use scripts to create a cluster and run it.

```sh
$ docker-compose up
```

When all the database nodes are up and running, we should first execute our Python scripts for subordinate nodes.
All of them look like this:

```python
# sub-1.py

from clickhouse_driver import Client
from datetime import datetime

if __name__ == "__main__":
    client = Client("127.0.0.1", port="9001")

    client.execute("CREATE DATABASE IF NOT EXISTS billing")

    client.execute(r'''CREATE TABLE IF NOT EXISTS billing.transactions(
                      timestamp DateTime,
                      currency String,
                      value Float64)
                      ENGINE = ReplicatedMergeTree('/clickhouse/tables/{shard}/billing.transactions', '{replica}')
                      PARTITION BY currency
                      ORDER BY timestamp''')
```

As you can see, the subordinate table now uses `ReplicatedMergeTree` engine.
Its constructor takes the path to the table records in ZooKeeper as the first parameter 
and the replica name as the second parameter.
The path to the table in ZooKeeper should be unique.
All the parameters in `{}` are taken from the aforementioned macros section of the replica config file.

```sh
$ python sub-1.py
$ python sub-2.py
$ python sub-3.py
$ python sub-4.py
```

When all the subordinate tables are created, it's time to create a master table.
There's no difference from the previous case when only sharding was utilized:

```python
from clickhouse_driver import Client
from datetime import datetime

if __name__ == "__main__":
    client = Client("127.0.0.1", port="9000")

    client.execute("CREATE DATABASE IF NOT EXISTS billing")

    client.execute('''CREATE TABLE IF NOT EXISTS billing.transactions(
                      timestamp DateTime,
                      currency String,
                      value Float64)
                      ENGINE = Distributed(example_cluster, billing, transactions, rand())''')
```

```sh
$ python master.py
```

Query distributed tables (subordinate tables and master table):

```sh
$ python query-cluster.py
```

If you set up all the things properly, you will get a working ClickHouse cluster with replication enabled.
The shard is alive if at least one of its replicas is up.
Table replication strengthens fault tolerance of the cluster.

# References

- [How to Create Python 3 Virtual Environment on Ubuntu 20.04](https://linoxide.com/how-to-create-python-virtual-environment-on-ubuntu-20-04/)
- Other [tutorial for setup clickhouse server](https://github.com/vejed/clickhouse-cluster)

---

## TODO

- Improve `docker-compose.yml`:
    - `ch-zookeeper`: add one more port
    - `ch-master` and `ch-sub-{1-4}:
        - add `hostname`
        - add `ulimits`
- Improve node configs
    - Move all config files to a new directory named `config`
    - Break the current one big config file into multiple configs. Example of container `volumes`:
        - `./config/clickhouse_config.xml:/etc/clickhouse-server/config.xml`
        - `./config/clickhouse_metrika.xml:/etc/clickhouse-server/metrika.xml`
        - `./config/macros/macros-01.xml:/etc/clickhouse-server/config.d/macros.xml`
        - `./config/users.xml:/etc/clickhouse-server/users.xml`
        - `./data/server-01:/var/lib/clickhouse`
