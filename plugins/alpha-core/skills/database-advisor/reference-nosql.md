# NoSQL Database Reference

## MongoDB

### Data Modeling
- Embed for 1:1 and 1:few relationships (denormalize)
- Reference for 1:many and many:many relationships
- Use `$lookup` for JOINs (but prefer embedding for read performance)
- Schema validation with JSON Schema validators

### Indexing
- Single field, compound, multikey (arrays), text, geospatial, hashed
- Use `explain()` to verify index usage
- Partial indexes for subset queries
- TTL indexes for auto-expiring documents

### Aggregation Pipeline
- `$match` → `$group` → `$project` → `$sort` (order matters for performance)
- `$lookup` for left outer joins
- `$unwind` for array flattening
- `$facet` for multi-faceted aggregations

### Operations
- Replica sets for HA (PSA or PSS topology)
- Sharding for horizontal scaling (choose shard key carefully)
- Change streams for real-time event processing
- Atlas: managed, auto-scaling, global clusters

## CouchDB

### Key Features
- HTTP/REST API for all operations
- Multi-master replication (eventually consistent)
- MapReduce views for queries
- Mango query language (JSON-based)
- PouchDB client for offline-first sync

### Use Cases
- Offline-first mobile/web apps
- Multi-region sync with conflict resolution
- Document-centric applications

## ElasticSearch / OpenSearch

### Core Concepts
- Inverted index for full-text search
- Shards and replicas for scaling
- Mapping types: text (analyzed), keyword (exact), numeric, date, geo_point

### Query DSL
- `match` for full-text search
- `term` for exact matches
- `bool` for combining queries (must, should, must_not, filter)
- `aggs` for aggregations (terms, date_histogram, nested)

### Best Practices
- Separate hot/warm/cold tiers for time-based data
- Use aliases for zero-downtime reindexing
- Set explicit mappings (don't rely on dynamic mapping in production)
- Use `_bulk` API for batch indexing
- Monitor with `_cat` APIs and Kibana
