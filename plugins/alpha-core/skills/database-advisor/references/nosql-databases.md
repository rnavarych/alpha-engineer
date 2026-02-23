# NoSQL Database Reference

## When to load
Load when working with MongoDB, CouchDB, Elasticsearch/OpenSearch, or Couchbase — including data modeling patterns, indexing strategies, aggregation pipelines, and advanced features.

## MongoDB

### Data Modeling
- Embed for 1:1 and 1:few relationships (denormalize)
- Reference for 1:many and many:many relationships
- Use `$lookup` for JOINs (prefer embedding for read performance)
- Schema validation with JSON Schema validators
- Patterns: polymorphic, bucket (time-series/IoT), computed, outlier, subset, extended reference

### Indexing
- Single field, compound, multikey (arrays), text, geospatial, hashed
- Wildcard indexes for dynamic schemas
- Use `explain()` to verify index usage
- Partial indexes, TTL indexes, hidden indexes
- Columnstore indexes (MongoDB 7.0+)

### Aggregation Pipeline
- `$match` → `$group` → `$project` → `$sort` (order matters)
- `$lookup` for JOINs, `$unwind` for array flattening
- `$facet` for multi-faceted aggregations
- `$merge` / `$out` for materialized views
- `$setWindowFields` for window functions
- `$densify` for filling time gaps, `$fill` for interpolation

### Advanced Features
- **Atlas Search**: Lucene-based FTS. Facets, autocomplete, highlights. Compound queries.
- **Atlas Vector Search**: kNN. RAG support. Embedding integration.
- **Time Series Collections**: Optimized storage. Auto bucketing.
- **Queryable Encryption**: Query encrypted data without server decryption. CSFLE field-level.
- **Change Streams**: Real-time events. Resumable. Pre/post images.
- **Atlas Data Federation**: Query across clusters, S3, HTTP endpoints.
- **Atlas Triggers**: Database, scheduled, authentication triggers.

### Operations
- Replica sets (PSA/PSS), sharding (range, hash, zone-based)
- Atlas: managed, auto-scaling, global clusters, multi-cloud
- mongodump/mongorestore, filesystem snapshots

## CouchDB
- HTTP/REST API, multi-master replication (eventual consistency)
- MapReduce views, Mango queries
- PouchDB for offline-first sync
- Use cases: offline-first apps, multi-region sync, CMS

## ElasticSearch / OpenSearch

### Core Concepts
- Inverted index for full-text search
- Shards and replicas for scaling
- Mapping types: text, keyword, numeric, date, geo_point, dense_vector, sparse_vector
- ILM for automated tiering, data streams for time-series

### Query DSL
- `match`, `term`, `bool` (must, should, must_not, filter)
- `aggs` (terms, date_histogram, nested, pipeline)
- `knn` for vector search, `multi_match`, `function_score`
- `runtime_fields` for computed fields at query time

### Advanced Features
- **ES|QL**: Pipe-based query language (8.11+)
- **ESRE**: ML-powered semantic search
- **Cross-cluster search/replication**
- **Transforms**: Pivot and latest aggregations
- **Anomaly detection**, **alerting**, **ingest pipelines**
- **Painless scripting**

### Best Practices
- Hot/warm/cold/frozen tiers for time-based data
- Aliases for zero-downtime reindexing
- Explicit mappings in production
- `_bulk` API for batch indexing
- Search templates for parameterized queries

### OpenSearch Specifics
- AWS fork of ES 7.10, security built-in
- OpenSearch Dashboards (Kibana fork)
- SQL plugin, anomaly detection, observability
- Amazon OpenSearch Serverless
- OpenSearch Ingestion for data pipelines

## Couchbase
- Document + KV + FTS + analytics + eventing
- N1QL: SQL++ for JSON
- Memory-first with async persistence
- Sub-document operations, XDCR
- Mobile sync with Couchbase Lite
- Services: Data, Query, Index, Search, Analytics, Eventing, Backup
- **Capella**: Managed DBaaS, multi-cloud, columnar analytics
