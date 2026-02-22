# Specialized Database Reference

## Graph Databases

### Neo4j
- **Cypher**: `MATCH (a:Person)-[:KNOWS]->(b:Person) RETURN a, b`
- Index-free adjacency, APOC procedures
- Graph Data Science: PageRank, community detection, pathfinding, embeddings, link prediction
- GenAI: vector indexes, knowledge graph from LLMs
- Aura managed (AuraDB, AuraDS)
- Use cases: social networks, recommendations, knowledge graphs, fraud detection, identity graphs

### Amazon Neptune
- Managed. Gremlin + SPARQL. Neptune Analytics. Neptune ML. Serverless.

### Dgraph
- GraphQL native. DQL. Distributed. Badger KV. Dgraph Cloud.

### JanusGraph
- Open-source. Pluggable storage (Cassandra, HBase, Bigtable). Gremlin.

### TigerGraph
- Enterprise analytics. GSQL. Deep link analytics (10+ hops). In-DB ML.

## Columnar Databases

### Apache Cassandra
- Consistent hashing, vnodes, tunable consistency (ONE, QUORUM, ALL, LOCAL_QUORUM)
- CQL. Compaction: SizeTiered, Leveled, TimeWindow, Unified (5.0)
- Cassandra 5.0: SAI, vector search, Trie-based indexes
- Best for: high write throughput, time-series at scale, geo-distributed

### ScyllaDB
- C++ Cassandra rewrite, shard-per-core, 10x performance/node
- CQL-compatible. Workload prioritization. CDC.
- Alternator: DynamoDB-compatible API. ScyllaDB Cloud.

### HBase
- Hadoop ecosystem (HDFS, ZooKeeper). Column families. Phoenix SQL layer.

### ClickHouse
- Columnar OLAP. MergeTree family (Replacing, Aggregating, Collapsing)
- Vectorized execution. Approximate processing. Materialized views.
- ClickHouse Cloud. Best for: analytics, log analysis, BI dashboards.

## Key-Value Stores

### Redis / Valkey
- Caching (SET/GET+TTL), sessions, rate limiting (INCR+EXPIRE, sliding window)
- Pub/Sub, sorted sets (leaderboards), streams (event sourcing, consumer groups)
- Cluster mode (16384 hash slots), Sentinel (failover)
- **Redis Stack**: RediSearch (FTS), RedisJSON, RedisTimeSeries, RedisBloom (probabilistic)
- **Valkey**: Linux Foundation fork. Full Redis compatibility.

### DynamoDB
- Partition key + sort key. GSI/LSI. On-demand vs provisioned.
- Streams CDC. DAX caching. Single-table design. PartiQL.
- Global Tables (multi-region). PITR. Export/Import S3.
- Zero-ETL with Redshift and OpenSearch.

### etcd
- Raft consensus. Watch API. Leases. Kubernetes backing store.

### FoundationDB
- Multi-model foundation. Strong ACID. Apple/Snowflake. Record Layer. Open-source.

## Time Series Databases

### InfluxDB
- Measurement → tags → fields → timestamp. Retention policies.
- Flux language. InfluxDB 3.0 (DataFusion, Arrow, Parquet). Cloud Serverless.

### Prometheus
- Pull-based. PromQL. Alertmanager. Federation.
- Long-term: Thanos, Cortex, Mimir, VictoriaMetrics.

### TimescaleDB
- PostgreSQL extension. Hypertables. Continuous aggregates. 90%+ compression.
- Promscale for Prometheus in PostgreSQL.

### QuestDB
- High-performance columnar. SQL-native. SIMD-optimized. InfluxDB Line Protocol. PG wire protocol.

### VictoriaMetrics
- MetricsQL (PromQL superset). High compression. VMAgent, VMAlert. Single-node + cluster.

## Vector Databases

### Pinecone
- Managed. Serverless + pod. Metadata filtering. Sparse-dense hybrid. Inference API.

### Weaviate
- Open-source. GraphQL + REST. Built-in vectorizers (OpenAI, Cohere, HuggingFace, Ollama).
- Hybrid search (vector + BM25). Multi-tenancy. Generative search. Reranking.

### Milvus / Zilliz
- GPU-accelerated. IVF_FLAT, HNSW, DiskANN, SCANN. Attribute filtering. Zilliz Cloud.

### pgvector
- PostgreSQL extension. HNSW + IVFFlat. Cosine, L2, inner product. halfvec for memory.

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

## Multi-Model

### SurrealDB
- Document + graph + relational. SurrealQL. LIVE SELECT. Built-in auth. Rust-based.

### FaunaDB
- Serverless. Document-relational. Distributed ACID. FQL. GraphQL API. Temporal queries.

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

## Decentralized
- **BigchainDB**: Blockchain-like on MongoDB. Immutable, append-only.
- **GunDB**: P2P graph DB. Real-time sync. Offline-first. SEA layer.
- **OrbitDB**: P2P on IPFS. Event log, KV, documents.
