# Search Engine Patterns and Operations

## When to load
Load when selecting a search engine, designing relevance tuning, planning data synchronization, managing indexes, applying security, or deciding on search architecture patterns.

## Engine Selection Guide

```
Small dataset (<100K docs), simple search:
  -> PostgreSQL FTS (pg_trgm, tsvector) or SQLite FTS5

Medium dataset, instant search needed:
  -> Typesense or Meilisearch (easy setup, great UX, typo tolerance)

Large dataset, complex queries, analytics:
  -> Elasticsearch or OpenSearch (mature, flexible)

E-commerce with merchandising and A/B testing:
  -> Algolia (InstantSearch, analytics, AI Recommend)

Budget-conscious, ES-compatible, no JVM:
  -> Zinc (lightweight, Go-based, ~50MB RAM)

Lightweight text search only:
  -> Sonic (minimal resources, ~30MB, returns IDs only)

MySQL ecosystem:
  -> Manticore Search (MySQL protocol, real-time indexes)
```

## Search Architecture Patterns

### Pattern 1: Dedicated Search Service
```
Application -> Primary Database (PostgreSQL)
                    |
              CDC/Sync Layer (Debezium, custom sync)
                    |
              Search Engine (Elasticsearch/Typesense)
                    |
              Search API -> Application
```

### Pattern 2: Search-as-a-Service
```
Application -> Algolia/Typesense Cloud
                    |
              Indexing API (push on write)
              Search API (direct from frontend)
```

### Pattern 3: Embedded Search
```
Application -> Database with Built-in Search
               (MongoDB Atlas Search, PostgreSQL FTS, Supabase + pg_trgm, SQLite FTS5)
```

## Relevance Tuning

### Field Boosting
```
Product name: 3x weight (most relevant)
Tags/keywords: 2x weight
Description: 1x weight (default)
Category: 0.5x weight (contextual)
```

### Query-Time Signals
```
1. Exact match bonus: boost exact phrase matches
2. Proximity bonus: boost when search terms are close together
3. Freshness: boost recent documents
4. Popularity: boost by view count, sales, or engagement
5. Personalization: boost by user preferences or history
```

### Index-Time Optimization
```
1. Synonyms: define at index time for consistent handling
2. Stop words: remove common words (the, is, at)
3. Stemming: normalize word forms (running -> run)
4. N-grams: edge n-grams for autocomplete
5. Phonetic analysis: match similar-sounding words
```

## Data Synchronization Strategy

```
1. Real-time (lowest latency):
   - CDC via Debezium -> Kafka -> Search connector
   - Database triggers -> queue -> indexer

2. Near real-time (seconds):
   - Application-level dual writes (with retry)
   - Change streams (MongoDB) -> indexer

3. Batch sync (minutes-hours):
   - Scheduled full/incremental reindex
   - ETL pipeline

Best practice: CDC for production, batch for recovery/rebuild
```

## Index Management

- Alias-based reindexing: create new index, reindex data, swap alias atomically
- Blue-green indexing for zero-downtime schema changes
- Monitor index size and query latency
- Alert on zero-result queries to identify coverage gaps
- Track search analytics: popular queries, no-result queries, click position

## Performance Optimization

- Use filters (not queries) for non-scoring criteria — filters are cached
- Limit returned fields to what the UI actually needs
- Prefer search-after pagination over deep offset (avoids scoring all pages)
- Cache frequent queries at application level
- Shard by tenant for multi-tenant workloads
- Monitor query latency percentiles (p50, p95, p99)

## Security

- Separate admin and search-only API keys
- Tenant-scoped API keys for multi-tenant search (Algolia, Meilisearch)
- Never expose admin keys to frontend code
- Rate limit the search API to prevent abuse
- Sanitize user input before constructing queries
- Always use HTTPS for search traffic

## Cross-References

- Elasticsearch and OpenSearch: see document-databases skill
- MongoDB Atlas Search: see document-databases skill
- PostgreSQL FTS (tsvector/tsquery): see relational-databases skill
