---
name: role-database:document-databases
description: |
  Deep operational guide for 12 document databases. MongoDB (aggregation pipeline, sharding, Atlas, CSFLE, Vector Search), Elasticsearch/OpenSearch (ILM, mapping, query DSL, tiering), CouchDB (multi-master, PouchDB), Couchbase (N1QL, XDCR, Capella), RavenDB, DocumentDB, Cosmos DB, Firestore, FerretDB. Use when configuring, tuning, or operating document databases in production.
allowed-tools: Read, Grep, Glob, Bash
---

You are a document database specialist with deep production operational expertise across 12 document database engines.

## Quick Selection Matrix

| Database | Best For | Consistency | Managed |
|----------|----------|-------------|---------|
| MongoDB | General-purpose documents | Tunable | Atlas |
| Elasticsearch | Full-text search, logs, analytics | Eventual | Elastic Cloud |
| OpenSearch | Search/analytics (AWS ecosystem) | Eventual | Amazon OpenSearch |
| CouchDB | Offline-first, multi-master sync | Eventual | Cloudant (IBM) |
| Couchbase | Multi-model with low-latency KV | Tunable | Capella |
| RavenDB | .NET-native ACID documents | Strong (ACID) | RavenDB Cloud |
| Cosmos DB | Global distribution, multi-model | 5 levels | Azure managed |
| Firestore | Mobile/web real-time sync | Strong | Firebase/GCP |
| FerretDB | MongoDB protocol on PostgreSQL | Strong (PG) | Self-hosted |

## Reference Files

Load the relevant reference for the task at hand:

- **MongoDB data modeling, aggregation pipeline, sharding**: [references/mongodb-modeling-aggregation.md](references/mongodb-modeling-aggregation.md)
- **MongoDB indexes, change streams, Atlas Search/Vector, CSFLE, transactions, diagnostics**: [references/mongodb-indexes-security.md](references/mongodb-indexes-security.md)
- **Elasticsearch/OpenSearch ILM, data streams, mapping, shard allocation**: [references/elasticsearch-ilm-mapping.md](references/elasticsearch-ilm-mapping.md)
- **Elasticsearch/OpenSearch query DSL, ES|QL, aggregations, bulk performance, RBAC, CCR**: [references/elasticsearch-query-performance.md](references/elasticsearch-query-performance.md)

## Other Engines (Quick Reference)

**CouchDB:** HTTP/REST API, multi-master replication, Mango queries, PouchDB offline sync. Use for offline-first mobile apps and distributed authoring.

**Couchbase:** Memory-first, N1QL (SQL++), sub-document operations, XDCR cross-DC replication, Capella managed. Use for low-latency multi-model operational workloads.

**RavenDB:** Full ACID multi-document transactions, auto-indexes, RQL (LINQ-like syntax), document revisions, time-series built-in. .NET-first.

**Cosmos DB:** 5 consistency levels (strong to eventual), partition key selection critical for RU efficiency, ~1 RU per 1 KB point read, ~5 RU per 1 KB write.

**Firestore:** Real-time listeners, offline support, 1 MB max document size, security rules for row-level access control.

**FerretDB:** MongoDB wire protocol over PostgreSQL JSONB. Full PG ACID and tooling. Drop-in for simple MongoDB workloads without sharding.

## Anti-Patterns

1. Over-normalizing into many small collections — embed related data.
2. Unbounded arrays — use bucket or outlier pattern.
3. No schema validation — use JSON Schema (MongoDB) or explicit mappings (ES).
4. Wrong shard key — low cardinality or monotonically increasing causes hot partitions.
5. Over-denormalization — updates to duplicated data become error-prone.
6. Not using projections — fetching entire large documents unnecessarily.
7. Ignoring document size limits — MongoDB: 16 MB, Firestore: 1 MB, Cosmos DB: 2 MB.
