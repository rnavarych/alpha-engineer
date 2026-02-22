# role-database

Senior Database Engineer plugin for Claude Code covering 230+ databases across 14 categories and 12 cross-cutting DBA disciplines.

## Agent

- **senior-database-engineer** — Acts as a Senior Database Engineer / DBA with 10+ years of experience managing production databases at scale. Deep operational expertise across all major database categories.

## Database Category Skills (Tier 1)

| Skill | Databases Covered |
|-------|-------------------|
| **relational-databases** | PostgreSQL, MySQL, MariaDB, Oracle, MS SQL Server, SQLite, IBM Db2, SAP HANA, Firebird, Informix, SingleStore, EDB, Percona Server, Amazon Aurora, Google AlloyDB, Azure SQL, Neon, Supabase, CockroachDB, YugabyteDB |
| **document-databases** | MongoDB, Elasticsearch, OpenSearch, CouchDB, Couchbase, RavenDB, Amazon DocumentDB, Azure Cosmos DB, Firebase Firestore, FerretDB, ToroDB, ArangoDB |
| **key-value-stores** | Redis, Valkey, Amazon DynamoDB, Memcached, etcd, FoundationDB, Amazon ElastiCache, Azure Cache for Redis, Google Memorystore, KeyDB, Dragonfly, Apache Ignite, Hazelcast, Aerospike, Garnet |
| **columnar-databases** | Apache Cassandra, ScyllaDB, HBase, Google Bigtable, ClickHouse, Apache Druid, StarRocks, Apache Kudu, MonetDB, Vertica, Apache Pinot, InfluxDB |
| **graph-databases** | Neo4j, Amazon Neptune, Dgraph, JanusGraph, TigerGraph, ArangoDB, Memgraph, TypeDB, Apache AGE, NebulaGraph, Blazegraph, Stardog |
| **time-series-databases** | InfluxDB, Prometheus, TimescaleDB, QuestDB, VictoriaMetrics, TDengine, Apache IoTDB, Graphite, KDB+, OpenTSDB, M3DB, CrateDB, Amazon Timestream, GridDB |
| **newsql-distributed** | CockroachDB, YugabyteDB, TiDB, Google Spanner, Vitess, PlanetScale, Citus, SingleStore, OceanBase, AlloyDB, Neon, CockroachDB Serverless |
| **vector-databases** | Pinecone, Weaviate, Milvus/Zilliz, Qdrant, ChromaDB, pgvector, LanceDB, Vespa, Marqo, Vald, Elasticsearch kNN, MongoDB Atlas Vector Search, Redis Stack Vector, Neo4j Vector, SingleStore Vector, Turbopuffer |
| **streaming-databases** | Apache Kafka, Apache Pulsar, Redpanda, NATS/JetStream, Apache Flink, Materialize, RisingWave, Spark Structured Streaming, Amazon Kinesis, Azure Event Hubs, Google Pub/Sub, RabbitMQ Streams, EventStoreDB, Memphis |
| **data-warehouse-olap** | Snowflake, Google BigQuery, Databricks, Amazon Redshift, DuckDB, Apache Druid, Apache Spark SQL, Trino, Apache Hive, Apache Doris, Firebolt, Vertica, StarRocks, ClickHouse |
| **embedded-databases** | SQLite, RocksDB, LevelDB, LMDB, BoltDB/bbolt, BadgerDB, Realm, ObjectBox, libSQL, DuckDB, H2, HSQLDB |
| **multi-model-databases** | ArangoDB, SurrealDB, FaunaDB, Azure Cosmos DB, OrientDB, MarkLogic, InterSystems IRIS, Couchbase |
| **serverless-databases** | Neon, Turso/libSQL, Supabase, PlanetScale, Cloudflare D1, Xata, Upstash, CockroachDB Serverless, Amazon Aurora Serverless, Azure Cosmos DB Serverless |
| **search-engines** | Apache Solr, Typesense, Meilisearch, Algolia, Zinc, Manticore Search, Sonic, Elasticsearch, OpenSearch, MongoDB Atlas Search |

## DBA Lifecycle Skills (Tier 2)

| Skill | Description |
|-------|-------------|
| **schema-design** | Normalization, denormalization, multi-tenancy patterns, PK strategies, naming conventions |
| **query-optimization** | EXPLAIN analysis, indexing strategies, N+1 elimination, pagination patterns |
| **replication-ha** | Replication topologies, failover automation, consensus protocols, split-brain prevention |
| **backup-recovery** | Full/incremental/differential backups, PITR, backup verification, RPO/RTO planning |
| **database-migration** | Migration tools, zero-downtime patterns, cross-engine migration, CDC-based migration |
| **database-monitoring** | pg_stat_statements, Performance Schema, mongostat, Redis INFO, Datadog, PMM, pganalyze |
| **database-security** | Authentication, RBAC, encryption at rest/in transit, audit logging, compliance |
| **capacity-planning** | Storage/IOPS/memory sizing, connection pooling, sharding triggers, cost estimation |
| **data-modeling** | ER modeling, document modeling, graph modeling, dimensional modeling, Data Vault |
| **connection-management** | PgBouncer, pgcat, ProxySQL, HikariCP, serverless connection strategies |
| **performance-diagnostics** | Lock contention, deadlocks, I/O bottlenecks, memory pressure, benchmarking |
| **database-devops** | Terraform, K8s operators, Helm charts, GitOps, schema migration in CI/CD, Testcontainers |

## Cross-Cutting Dependencies

This plugin references foundational skills from `alpha-core`:
- database-advisor, security-advisor, performance-optimization, architecture-patterns, observability, cloud-infrastructure, ci-cd-patterns
