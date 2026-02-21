# Specialized Database Reference

## Graph Databases

### Neo4j
- **Cypher query language**: `MATCH (a:Person)-[:KNOWS]->(b:Person) RETURN a, b`
- Native graph storage with index-free adjacency
- APOC procedures for import/export, algorithms, utilities
- Graph Data Science library: PageRank, community detection, pathfinding
- Use cases: social networks, recommendation engines, knowledge graphs, fraud detection

### Selection Criteria
- Use graph DB when relationships are first-class citizens
- Queries involving multiple hops/traversals (>3 JOINs in SQL)
- Dynamic/evolving schemas with complex relationships

## Columnar Databases

### Apache Cassandra
- Consistent hashing with virtual nodes (vnodes)
- Tunable consistency (ONE, QUORUM, ALL)
- CQL (Cassandra Query Language) — SQL-like syntax
- Compaction strategies: SizeTiered, Leveled, TimeWindow
- Best for: high write throughput, time-series at scale, geo-distributed
- Avoid: complex queries, JOINs, aggregations, frequent schema changes

### HBase
- Hadoop ecosystem (HDFS storage, ZooKeeper coordination)
- Column families for physical storage grouping
- Row key design is critical for performance
- Best for: Hadoop integration, batch + real-time, large-scale random R/W

## Key-Value Stores

### Redis Patterns
- **Caching**: SET/GET with TTL, cache-aside pattern
- **Session storage**: Hash per session, EXPIRE for timeout
- **Rate limiting**: INCR + EXPIRE or sliding window with sorted sets
- **Pub/Sub**: PUBLISH/SUBSCRIBE for real-time messaging
- **Sorted sets**: Leaderboards, priority queues
- **Streams**: Event sourcing, message queues (consumer groups)
- **Cluster mode**: Hash slots (16384), automatic sharding
- **Sentinel**: Automatic failover for standalone setups

### DynamoDB
- Partition key + optional sort key
- Global/Local secondary indexes
- On-demand vs provisioned capacity
- DynamoDB Streams for CDC
- DAX for microsecond latency caching
- Single-table design for efficient queries

## Time Series Databases

### InfluxDB
- Measurement → tags (indexed) → fields (not indexed) → timestamp
- Retention policies for auto-expiry
- Continuous queries for downsampling
- Flux language for transformations
- Best for: IoT sensor data, application metrics, real-time analytics

### Prometheus
- Pull-based model (scrapes targets)
- PromQL for querying
- Alertmanager for alert routing
- Federation for scaling
- Best for: infrastructure monitoring, Kubernetes metrics

### TimescaleDB
- PostgreSQL extension — full SQL support
- Hypertables auto-partition by time
- Continuous aggregates (materialized views auto-refresh)
- Compression for storage efficiency
- Best for: when you need SQL + time-series

## Hybrid / Multi-Model

### ArangoDB
- Document + Graph + Key-Value in one engine
- AQL (ArangoDB Query Language)
- SmartGraphs for enterprise sharding
- Foxx microservices framework
- Best for: projects needing multiple data models without multiple databases

## Decentralized

### BigchainDB
- Blockchain-like properties on top of MongoDB
- Immutable, append-only records
- Asset creation and transfer
- Best for: supply chain tracking, digital asset management, audit trails
