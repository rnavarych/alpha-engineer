# Specialized Databases: NewSQL, Multi-Model, Streaming, Serverless, OLAP

## When to load
Load when working with distributed SQL (CockroachDB, Spanner, TiDB), multi-model databases (SurrealDB, ArangoDB), streaming/event stores (Kafka, Redpanda, Materialize), serverless databases (Neon, Turso, Supabase, D1), or OLAP/data warehouse systems (Snowflake, Databricks, ClickHouse, DuckDB).

## NewSQL / Distributed SQL

### CockroachDB
- PostgreSQL-compatible. Raft. Serializable isolation. Geo-partitioning.
- Multi-region survival goals. Changefeeds CDC. Serverless + Dedicated.

### YugabyteDB
- YSQL (PostgreSQL) + YCQL (Cassandra). DocDB (Raft + LSM).
- xCluster replication. Colocated tables. YugabyteDB Managed.

### TiDB
- MySQL-compatible. TiKV + TiFlash (HTAP). TiSpark. TiCDC. TiDB Cloud.

### Google Spanner
- Globally consistent. TrueTime. PostgreSQL interface. 99.999% SLA.

### Other NewSQL
- **Vitess**: MySQL horizontal scaling. YouTube heritage. PlanetScale managed.
- **PlanetScale**: Vitess-powered. Branching. Non-blocking schema changes.

## Multi-Model Databases

### SurrealDB
- Document + graph + relational. SurrealQL. LIVE SELECT. Built-in auth. Rust-based.

### FaunaDB
- Serverless. Document-relational. Distributed ACID. FQL. GraphQL API. Temporal queries.

### ArangoDB
- Document + Graph + KV. AQL. SmartGraphs. Foxx microservices.

## Streaming / Event Store

### Apache Kafka
- Topics, partitions, consumer groups. EOS. KRaft (no ZooKeeper).
- Kafka Streams, Connect (200+ connectors), Schema Registry. Tiered storage.
- Confluent Cloud, Amazon MSK, Redpanda (compatible).

### Redpanda
- Kafka-compatible C++. No JVM/ZooKeeper. Lower latency. Built-in Schema Registry. Console UI.

### Materialize
- Streaming SQL. PostgreSQL wire-compatible. Incremental materialized views.
- Sources: Kafka, PostgreSQL CDC, webhooks. Sinks: Kafka.

### RisingWave
- Distributed streaming SQL. PostgreSQL-compatible. Cloud-native. Materialized views on streams.

### Other Streaming
- **Apache Pulsar**: Multi-tenant. Geo-replication. Tiered storage. Functions.
- **NATS JetStream**: Lightweight messaging + persistence. KV and Object Store.

## Serverless Databases

- **Neon**: Serverless PostgreSQL. Branching. Scale-to-zero.
- **Turso / libSQL**: SQLite for edge. Embedded replicas. Multi-region.
- **Supabase**: PostgreSQL + Auth + Realtime + Edge Functions + Storage.
- **Cloudflare D1**: SQLite at edge. Workers integration.
- **Xata**: Serverless PostgreSQL + search + analytics + file storage.

## Data Warehouse / OLAP

- **Snowflake**: Separate compute/storage. Time Travel. Zero-copy cloning. Snowpark.
- **Databricks**: Lakehouse. Delta Lake. Unity Catalog. SQL + ML + streaming.
- **BigQuery**: Serverless. BQML. BI Engine. Streaming inserts.
- **Amazon Redshift**: Columnar MPP. Serverless. Spectrum for S3.
- **Apache Druid**: Real-time OLAP. Sub-second queries. Kafka ingestion.
- **StarRocks**: MPP OLAP. Vectorized execution. Primary-key upserts.
- **DuckDB**: Embedded OLAP. In-process. Parquet/CSV/JSON native. Arrow integration.

## Embedded Databases

- **SQLite**: See sql-databases.md — zero-config, 700B+ databases in use.
- **DuckDB**: See OLAP section — embedded analytical queries.
- **RocksDB**: LSM-tree KV. Foundation for CockroachDB, TiKV.
- **LevelDB**: Google's lightweight KV. LSM-tree.
- **LMDB**: Memory-mapped B+tree. Zero-copy reads. ACID.
- **Realm**: Mobile-first object DB. Sync with Atlas.

## Decentralized

- **BigchainDB**: Blockchain-like on MongoDB. Immutable, append-only.
- **GunDB**: P2P graph DB. Real-time sync. Offline-first. SEA layer.
- **OrbitDB**: P2P on IPFS. Event log, KV, documents.
