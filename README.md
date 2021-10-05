# Tutorial: Creating a ClickHouse Cluster

Based on this tutorial: ["Creating a ClickHouse cluster - Part I: Sharding"](https://dev.to/zergon321/creating-a-clickhouse-cluster-part-i-sharding-4j20)

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

# References

- [How to Create Python 3 Virtual Environment on Ubuntu 20.04](https://linoxide.com/how-to-create-python-virtual-environment-on-ubuntu-20-04/)
