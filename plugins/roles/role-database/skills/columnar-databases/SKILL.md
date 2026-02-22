---
name: columnar-databases
description: |
  Deep operational guide for 12 columnar/wide-column databases. Apache Cassandra (compaction, consistency, SAI, nodetool), ScyllaDB (shard-per-core, Alternator), HBase, Bigtable, ClickHouse (MergeTree, materialized views), Druid, StarRocks, Kudu, MonetDB, Vertica, Pinot. Use when configuring, tuning, or operating columnar databases for analytics or high-write workloads.
allowed-tools: Read, Grep, Glob, Bash
---

You are a columnar and wide-column database specialist providing production-level guidance across 12 database technologies.

## Columnar Database Selection Framework

When recommending a columnar database, evaluate:
1. **Workload type**: OLAP analytics, time-series ingestion, wide-column operational, real-time dashboards, ad-hoc queries
2. **Write pattern**: Append-only (time-series), upsert-heavy (CDC), batch ingestion, streaming ingestion
3. **Read pattern**: Point lookups, range scans, full aggregation scans, interactive analytics
4. **Latency requirements**: Sub-second dashboards (Druid, Pinot, StarRocks) vs batch analytics (ClickHouse) vs operational (Cassandra)
5. **Scale**: Single-node analytics (DuckDB) vs distributed petabyte-scale (Cassandra, Bigtable, ClickHouse)
6. **Data freshness**: Real-time (streaming ingestion) vs near-real-time (micro-batch) vs batch (hourly/daily)
7. **Ecosystem**: Hadoop/HDFS (HBase, Kudu), Kubernetes, cloud-managed (Bigtable, Astra), standalone

## Comparison Table

| Database | Category | Ingestion | Query Latency | Scale | Best For |
|---|---|---|---|---|---|
| Cassandra | Wide-column | Streaming writes | Low (point) | Petabyte, multi-DC | High-write operational, IoT, time-series |
| ScyllaDB | Wide-column | Streaming writes | Very low | Petabyte, multi-DC | Cassandra workloads, 10x fewer nodes |
| HBase | Wide-column | Batch + streaming | Low (point) | Petabyte (HDFS) | Hadoop ecosystem, sparse data |
| Bigtable | Wide-column | Streaming | Low (point) | Petabyte (managed) | GCP-native, IoT, analytics |
| ClickHouse | Columnar OLAP | Batch + streaming | Sub-second (analytical) | Petabyte | Analytics, log analysis, BI |
| Druid | Columnar OLAP | Real-time + batch | Sub-second | Petabyte | Real-time dashboards, event analytics |
| StarRocks | Columnar OLAP | Real-time + batch | Sub-second | Petabyte | Unified analytics, real-time + ad-hoc |
| Kudu | Columnar | Streaming + batch | Medium | Petabyte (Hadoop) | Fast analytics on mutable data |
| MonetDB | Columnar OLAP | Batch | Sub-second | Terabyte | Research, single-node analytics |
| Vertica | Columnar OLAP | Batch + streaming | Sub-second | Petabyte | Enterprise analytics, data warehouse |
| Pinot | Columnar OLAP | Real-time + batch | Sub-second | Petabyte | User-facing analytics, high concurrency |
| InfluxDB | Columnar TS | Streaming | Sub-second | Terabyte | Metrics, IoT (cross-ref time-series) |

## Apache Cassandra (Primary)

### Architecture
- Masterless ring topology with consistent hashing
- Virtual nodes (vnodes, default 256 per node) for balanced data distribution
- Gossip protocol for cluster membership and failure detection
- Configurable replication factor per keyspace
- Tunable consistency per query (ONE, QUORUM, LOCAL_QUORUM, ALL)

### Data Modeling Rules
```sql
-- Design for queries, not normalization
-- Rule 1: One table per query pattern
-- Rule 2: Denormalize aggressively
-- Rule 3: Partition key = equality predicates
-- Rule 4: Clustering columns = range/order predicates

CREATE KEYSPACE ecommerce WITH replication = {
  'class': 'NetworkTopologyStrategy',
  'dc1': 3, 'dc2': 3
};

-- Orders by user (partition: user_id, cluster: order_date DESC)
CREATE TABLE ecommerce.orders_by_user (
  user_id UUID,
  order_date TIMESTAMP,
  order_id UUID,
  total DECIMAL,
  status TEXT,
  PRIMARY KEY (user_id, order_date, order_id)
) WITH CLUSTERING ORDER BY (order_date DESC, order_id ASC)
  AND compaction = {'class': 'TimeWindowCompactionStrategy',
                    'compaction_window_unit': 'DAYS',
                    'compaction_window_size': 1};

-- Orders by status (for admin dashboard)
CREATE TABLE ecommerce.orders_by_status (
  status TEXT,
  order_date TIMESTAMP,
  order_id UUID,
  user_id UUID,
  total DECIMAL,
  PRIMARY KEY (status, order_date, order_id)
) WITH CLUSTERING ORDER BY (order_date DESC);
```

### Compaction Strategies
| Strategy | Best For | Characteristics |
|---|---|---|
| SizeTieredCompactionStrategy (STCS) | Write-heavy, general purpose | Groups similarly-sized SSTables, high space amplification |
| LeveledCompactionStrategy (LCS) | Read-heavy, space-constrained | Fixed-size levels, low space amplification, higher write amplification |
| TimeWindowCompactionStrategy (TWCS) | Time-series, TTL data | Groups by time window, efficient for time-bucketed data |
| UnifiedCompactionStrategy (UCS) | Cassandra 5.0+, adaptive | Combines STCS/LCS behaviors, auto-tunes |

### Consistency Levels
```
Write CL + Read CL > Replication Factor = Strong consistency

Common patterns:
- Write LOCAL_QUORUM + Read LOCAL_QUORUM = strong within DC
- Write ONE + Read ONE = eventual (fastest, for non-critical reads)
- Write ALL + Read ONE = highest write durability, fast reads
- Write ANY = hinted handoff accepted (lowest durability)
```

### Key nodetool Commands
```bash
nodetool status                    # Cluster status (UN=Up Normal, DN=Down Normal)
nodetool ring                      # Token ring assignments
nodetool info                      # Node-specific information
nodetool tablestats <ks>.<table>   # Table-level statistics
nodetool tablehistograms <ks>.<table>  # Latency histograms
nodetool compactionstats           # Active compactions
nodetool tpstats                   # Thread pool statistics
nodetool flush <ks>                # Flush memtables to SSTables
nodetool compact <ks> <table>      # Force compaction
nodetool repair -pr <ks>           # Primary range repair
nodetool cleanup <ks>              # Remove data not belonging to node
nodetool decommission              # Remove node from cluster
nodetool assassinate <ip>          # Force-remove dead node
nodetool describecluster           # Cluster schema and snitch info
nodetool getendpoints <ks> <table> <key>  # Find replicas for key
```

### Cassandra 5.0 Features
- **SAI (Storage-Attached Indexing)**: Efficient secondary indexing attached to SSTables
- **Vector search**: ANN (Approximate Nearest Neighbor) for embeddings
- **Trie-based memtable and SSTable**: Improved memory efficiency
- **Unified Compaction Strategy**: Adaptive compaction
- **Guardrails**: Configurable limits to prevent anti-patterns

**For deep Cassandra + ScyllaDB reference, see [reference-cassandra-scylla.md](reference-cassandra-scylla.md)**

## ScyllaDB

### Architecture
- Shard-per-core: one thread per CPU core, no locks, no context switches
- Seastar framework: cooperative scheduling, zero-copy networking
- CQL-compatible (drop-in Cassandra replacement for most workloads)
- 10x performance per node vs Cassandra

### Key Differentiators
```bash
# Alternator: DynamoDB-compatible API on ScyllaDB
# Use AWS SDK against ScyllaDB endpoint
aws dynamodb --endpoint-url http://scylla:8000 create-table ...

# Workload prioritization
# Service Level (SL) assigns shares to different workloads
CREATE SERVICE LEVEL sl_interactive WITH shares = 1000;
CREATE SERVICE LEVEL sl_batch WITH shares = 100;
ATTACH SERVICE LEVEL sl_interactive TO user_realtime;
ATTACH SERVICE LEVEL sl_batch TO user_etl;

# CDC (Change Data Capture)
ALTER TABLE ks.orders WITH cdc = {'enabled': true, 'preimage': true, 'postimage': true};
-- CDC log table: ks.orders_scylla_cdc_log
```

### Operations
```bash
# ScyllaDB Manager (repair and backup orchestration)
sctool repair --cluster <id> --keyspace <ks>
sctool backup --cluster <id> --location s3://bucket/prefix
sctool task list --cluster <id>

# ScyllaDB Monitoring Stack (Prometheus + Grafana)
# Pre-built dashboards: Cluster Overview, Per-node, Repair, CQL
```

## HBase

### Architecture
- Runs on HDFS, coordinated by ZooKeeper
- RegionServer: hosts regions (contiguous row ranges)
- Column families (defined at schema time), qualifiers (dynamic)
- Write path: WAL -> MemStore -> HFile (flush) -> Compaction

### Key Operations
```bash
# HBase shell
hbase shell

create 'users', {NAME => 'info', VERSIONS => 3}, {NAME => 'metrics', TTL => 86400}
put 'users', 'user:1001', 'info:name', 'Alice'
get 'users', 'user:1001'
scan 'users', {STARTROW => 'user:1000', ENDROW => 'user:2000', LIMIT => 100}

# Region management
balance_switch true
major_compact 'users'
split 'users', 'user:5000'
merge_region 'region1', 'region2'

# Phoenix SQL layer (thin SQL skin over HBase)
# jdbc:phoenix:zk1,zk2,zk3:2181
SELECT * FROM USERS WHERE NAME = 'Alice';
```

### Coprocessors
- **Observer**: Triggers (pre/post hooks on get, put, delete, scan)
- **Endpoint**: Custom RPC (server-side aggregation, custom processing)
- **MOB (Medium Object Blob)**: Efficient storage for 100KB-10MB values

## Google Bigtable

### Row Key Design
```
# Anti-pattern: sequential keys (hotspotting)
BAD:  2024-03-15T10:30:00#sensor1

# Pattern: reverse timestamp for recent-first
GOOD: sensor1#9999999999-1710500000

# Pattern: salted keys for even distribution
GOOD: 3#sensor1#2024-03-15T10:30:00  (salt = hash(sensor1) % N)

# Pattern: field promotion for common queries
GOOD: us-east#sensor1#2024-03-15T10:30:00
```

### Operations
```bash
# cbt CLI
cbt -project myproject -instance myinstance ls
cbt -project myproject -instance myinstance read mytable prefix=sensor1
cbt -project myproject -instance myinstance count mytable

# Column family management
cbt createfamily mytable metrics
cbt setgcpolicy mytable metrics maxversions=1
cbt setgcpolicy mytable logs maxage=72h
```

### Change Streams
- Real-time CDC for Bigtable mutations
- Integrate with Dataflow for stream processing
- Use cases: real-time analytics, materialized views, event-driven

## ClickHouse

### MergeTree Engine Family
```sql
-- ReplacingMergeTree: deduplication by sorting key
CREATE TABLE events (
  event_date Date,
  user_id UInt64,
  event_type String,
  properties String,
  _version UInt64
) ENGINE = ReplacingMergeTree(_version)
PARTITION BY toYYYYMM(event_date)
ORDER BY (user_id, event_type, event_date)
SETTINGS index_granularity = 8192;

-- AggregatingMergeTree: pre-aggregated materialized views
CREATE MATERIALIZED VIEW events_daily_mv
ENGINE = AggregatingMergeTree()
PARTITION BY toYYYYMM(event_date)
ORDER BY (event_date, event_type)
AS SELECT
  event_date,
  event_type,
  countState() AS event_count,
  uniqState(user_id) AS unique_users
FROM events
GROUP BY event_date, event_type;

-- CollapsingMergeTree: mutable data via +1/-1 sign
-- VersionedCollapsingMergeTree: handles out-of-order inserts
```

### Materialized Views
```sql
-- Real-time aggregation pipeline
CREATE MATERIALIZED VIEW hourly_metrics
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(hour)
ORDER BY (hour, metric_name)
AS SELECT
  toStartOfHour(timestamp) AS hour,
  metric_name,
  sum(value) AS total,
  count() AS count
FROM raw_metrics
GROUP BY hour, metric_name;
```

### Distributed Tables
```sql
-- Distributed table across cluster
CREATE TABLE events_distributed AS events
ENGINE = Distributed(
  'production_cluster',     -- Cluster name
  'default',                -- Database
  'events',                 -- Local table
  rand()                    -- Sharding key
);

-- Insert via distributed table (routes to correct shard)
INSERT INTO events_distributed VALUES (...);

-- Query across all shards
SELECT count() FROM events_distributed WHERE event_date = today();
```

### ClickHouse Keeper
- ZooKeeper-compatible coordination service written in C++
- Used for distributed DDL, replication, leader election
- Lighter than ZooKeeper, recommended for new deployments

### Performance Tuning
```sql
-- Key settings
SET max_threads = 16;                    -- Parallel query threads
SET max_memory_usage = 10000000000;      -- 10GB per query
SET max_execution_time = 60;             -- Query timeout
SET optimize_read_in_order = 1;          -- Read in primary key order

-- Monitor
SELECT * FROM system.query_log ORDER BY event_time DESC LIMIT 20;
SELECT * FROM system.merges;
SELECT * FROM system.parts WHERE active;
SELECT * FROM system.metrics;
```

## Apache Druid

### Architecture
- **Segments**: Immutable columnar data chunks (time-partitioned)
- **Deep storage**: S3/HDFS/GCS for segment persistence
- **Real-time ingestion**: Kafka/Kinesis -> real-time tasks -> segments
- **Batch ingestion**: HDFS/S3/local -> indexing tasks -> segments

### Ingestion
```json
// Kafka ingestion spec
{
  "type": "kafka",
  "spec": {
    "ioConfig": {
      "consumerProperties": {"bootstrap.servers": "kafka:9092"},
      "topic": "events",
      "useEarliestOffset": true
    },
    "dataSchema": {
      "dataSource": "events",
      "timestampSpec": {"column": "timestamp", "format": "iso"},
      "dimensionsSpec": {"dimensions": ["user_id", "event_type", "country"]},
      "metricsSpec": [
        {"type": "count", "name": "count"},
        {"type": "longSum", "name": "total_value", "fieldName": "value"}
      ],
      "granularitySpec": {"segmentGranularity": "HOUR", "queryGranularity": "MINUTE"}
    }
  }
}
```

### Query Patterns
```sql
-- Native Druid SQL
SELECT
  TIME_FLOOR(__time, 'PT1H') AS hour,
  country,
  COUNT(*) AS events,
  SUM(value) AS total
FROM events
WHERE __time >= CURRENT_TIMESTAMP - INTERVAL '24' HOUR
GROUP BY 1, 2
ORDER BY events DESC
LIMIT 100;

-- TopN query (optimized)
-- GroupBy query (flexible)
-- Timeseries query (fastest for time-based aggregation)
-- Scan query (raw data retrieval)
```

## StarRocks

### Key Features
- MPP OLAP engine with vectorized execution
- Primary-key tables: real-time upserts with unique key dedup
- Materialized views: automatic query rewriting
- External catalogs: query Hive, Iceberg, Hudi, Delta Lake without data movement

```sql
-- Primary key table (real-time upserts)
CREATE TABLE orders (
  order_id BIGINT,
  user_id BIGINT,
  status VARCHAR(20),
  total DECIMAL(10,2),
  updated_at DATETIME
) PRIMARY KEY (order_id)
DISTRIBUTED BY HASH(order_id) BUCKETS 16;

-- Async materialized view
CREATE MATERIALIZED VIEW daily_revenue
REFRESH ASYNC EVERY(INTERVAL 5 MINUTE)
AS SELECT
  date_trunc('day', updated_at) AS day,
  sum(total) AS revenue,
  count(*) AS order_count
FROM orders
GROUP BY 1;
```

## Apache Kudu

### Characteristics
- Columnar storage for Hadoop ecosystem
- Fast scans + fast random access (unlike HBase or HDFS alone)
- Tight integration with Impala for SQL analytics
- Raft consensus for tablet replication
- Supports insert, update, delete (mutable data)

## MonetDB

### Characteristics
- Pioneer of column-store databases (1990s research)
- MAL (MonetDB Assembly Language) algebra for query execution
- Columnar storage with BATs (Binary Association Tables)
- Single-node, high-performance analytical queries
- SQL:2023 compliance, Python/R UDFs

## Vertica

### Key Features
- MPP columnar analytics database
- Eon Mode: separate compute and storage (S3/GCS/HDFS)
- Projections: pre-sorted, pre-aggregated physical storage (like materialized indexes)
- Flex tables: schema-on-read for semi-structured data
- In-database ML: linear regression, logistic regression, k-means, random forest

```sql
-- Projection (sorted physical storage for fast query)
CREATE PROJECTION sales_by_region AS
  SELECT region, product, sale_date, SUM(amount) AS total
  FROM sales
  ORDER BY region, sale_date
  SEGMENTED BY HASH(region) ALL NODES;
```

## Apache Pinot

### Architecture
- Real-time OLAP for user-facing analytics
- Segments: offline (batch) + real-time (streaming)
- Star-tree index: pre-aggregated multi-dimensional index for fast aggregation
- Upsert support: real-time updates via primary key
- Multi-stage query engine: distributed joins and subqueries

```sql
-- Pinot query
SELECT city, COUNT(*) AS orders, SUM(total) AS revenue
FROM orders
WHERE order_date > ago('P7D')
GROUP BY city
ORDER BY revenue DESC
LIMIT 50
OPTION(timeoutMs=5000);
```

### Streaming Ingestion
```json
{
  "tableName": "orders_REALTIME",
  "tableType": "REALTIME",
  "segmentsConfig": {
    "replication": "2",
    "retentionTimeUnit": "DAYS",
    "retentionTimeValue": "30"
  },
  "ingestionConfig": {
    "streamIngestionConfig": {
      "streamConfigMaps": [{
        "stream.type": "kafka",
        "stream.kafka.topic.name": "orders",
        "stream.kafka.broker.list": "kafka:9092",
        "stream.kafka.consumer.type": "lowlevel"
      }]
    }
  }
}
```

## InfluxDB (Cross-Reference)

For time-series database details including InfluxDB, see the **time-series-databases** skill.

Key InfluxDB notes for columnar context:
- InfluxDB 3.0 uses Apache DataFusion (columnar query engine), Apache Arrow (in-memory columnar format), and Apache Parquet (columnar storage)
- This architecture makes InfluxDB 3.0 effectively a columnar time-series database
- Supports SQL and InfluxQL query languages

## Operational Best Practices

### Write Optimization
| Database | Strategy |
|---|---|
| Cassandra/ScyllaDB | Tune `commitlog_sync`, use UNLOGGED batches for same-partition, avoid LOGGED batches |
| ClickHouse | Batch inserts (>1000 rows), avoid frequent small inserts, use Buffer engine |
| Druid/Pinot | Tune segment granularity, use Kafka for streaming, compact segments |
| HBase | Tune memstore flush size, disable WAL for bulk loads, pre-split regions |

### Read Optimization
| Database | Strategy |
|---|---|
| Cassandra | Partition key lookups, avoid ALLOW FILTERING, use SAI for secondary access |
| ClickHouse | Partition pruning, primary key ordering, materialized views, projections |
| Druid | Segment granularity matching query patterns, star-tree indexes |
| Pinot | Star-tree, inverted indexes, sorted columns, range indexes |

### Monitoring Essentials
| Metric | Cassandra/ScyllaDB | ClickHouse | Druid |
|---|---|---|---|
| Write latency | coordinator_latency | InsertedRows/s | ingest/events/processed |
| Read latency | read_latency | QueryDuration | query/time |
| Compaction | pending_compactions | Merges | compact/task/count |
| Memory | heap_usage | MemoryTracking | jvm/mem/used |
| Disk | disk_space_used | DiskSpaceUsed | segment/size |

For detailed Cassandra + ScyllaDB reference, see [reference-cassandra-scylla.md](reference-cassandra-scylla.md).
