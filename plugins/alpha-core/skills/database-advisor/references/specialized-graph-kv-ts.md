# Specialized Databases: Graph, Columnar, Key-Value, Time Series, Vector

## When to load
Load when working with graph databases (Neo4j, Neptune), columnar stores (Cassandra, ClickHouse), key-value stores (Redis, DynamoDB, etcd), time series databases (InfluxDB, Prometheus, TimescaleDB), or vector databases (Pinecone, Weaviate, pgvector).

## Graph Databases

### Neo4j
- **Cypher**: `MATCH (a:Person)-[:KNOWS]->(b:Person) RETURN a, b`
- Index-free adjacency, APOC procedures
- Graph Data Science: PageRank, community detection, pathfinding, embeddings, link prediction
- GenAI: vector indexes, knowledge graph from LLMs
- Aura managed (AuraDB, AuraDS)
- Use cases: social networks, recommendations, knowledge graphs, fraud detection, identity graphs

### Other Graph Databases
- **Amazon Neptune**: Managed. Gremlin + SPARQL. Neptune Analytics. Neptune ML. Serverless.
- **Dgraph**: GraphQL native. DQL. Distributed. Badger KV. Dgraph Cloud.
- **JanusGraph**: Open-source. Pluggable storage (Cassandra, HBase, Bigtable). Gremlin.
- **TigerGraph**: Enterprise analytics. GSQL. Deep link analytics (10+ hops). In-DB ML.

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

### ClickHouse
- Columnar OLAP. MergeTree family (Replacing, Aggregating, Collapsing)
- Vectorized execution. Approximate processing. Materialized views.
- ClickHouse Cloud. Best for: analytics, log analysis, BI dashboards.

### HBase
- Hadoop ecosystem (HDFS, ZooKeeper). Column families. Phoenix SQL layer.

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

### Other Key-Value
- **etcd**: Raft consensus. Watch API. Leases. Kubernetes backing store.
- **FoundationDB**: Multi-model foundation. Strong ACID. Apple/Snowflake. Record Layer. Open-source.

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

### Other Vector Stores
- **Qdrant**: Rust-based. Filtering during search. Quantization. gRPC + REST.
- **ChromaDB**: Lightweight embeddable. Python/JS. Local or client/server.
- **LanceDB**: Serverless. Lance columnar format. Multi-modal.
