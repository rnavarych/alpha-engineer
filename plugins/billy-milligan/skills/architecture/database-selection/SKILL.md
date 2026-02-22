---
name: database-selection
description: |
  Database selection guide: PostgreSQL as default (10k TPS), Redis for ephemeral data,
  ClickHouse for analytics, Elasticsearch for search, MongoDB tradeoffs (The MongoDB Incident),
  DynamoDB patterns, time-series DBs. Decision matrix with specific use-case triggers.
  Use when choosing a database for a new system or questioning an existing choice.
allowed-tools: Read, Grep, Glob
---

# Database Selection

## When to Use This Skill
- Choosing a database for a new service or feature
- Questioning whether the current DB is the right fit
- Evaluating polyglot persistence strategy
- Deciding between SQL and NoSQL
- Selecting for compliance (GDPR, HIPAA, PCI)

## Core Principles

1. **PostgreSQL is the default** — it handles OLTP, JSON, full-text search, geospatial, and time-series adequately
2. **Add a new database only when PostgreSQL demonstrably can't do it** — not "might be better"
3. **Each new database is operational cost** — migrations, backups, expertise, monitoring
4. **Read your access patterns before choosing** — key-value lookups vs complex joins need different engines
5. **The MongoDB Incident is a cautionary tale** — it happened. Don't repeat it.

---

## Patterns ✅

### Decision Matrix

| Use Case | Best Choice | Why |
|----------|-------------|-----|
| General OLTP (users, orders, products) | **PostgreSQL** | ACID, joins, JSON, full-text, mature tooling |
| Session/cache/ephemeral | **Redis** | Sub-millisecond reads, TTL, atomic operations |
| Analytical queries, data warehouse | **ClickHouse** or **BigQuery** | Columnar, 100x faster than PG for analytics |
| Full-text search, faceted filtering | **Elasticsearch** or **PG full-text** | Depends on scale; PG adequate up to 10M docs |
| High-write IoT/metrics time-series | **TimescaleDB** or **InfluxDB** | Hypertables, downsampling, time-range queries |
| Global low-latency key-value at scale | **DynamoDB** | Single-digit ms at any scale, multi-region active-active |
| Document store (truly schema-less) | **MongoDB** | When schema genuinely varies per document at massive scale |
| Graph relationships | **Neo4j** or **PostgreSQL with recursive CTEs** | Neo4j for >3-hop traversals; PG adequate for simpler graphs |

### PostgreSQL — Default Justification

```sql
-- PostgreSQL handles more than people realize

-- JSONB for flexible schema (partial schema-flexibility)
SELECT id, metadata->>'source'
FROM events
WHERE metadata @> '{"type": "click"}'  -- GIN index on JSONB
  AND created_at > NOW() - INTERVAL '7 days';

-- Full-text search (adequate up to ~10M rows)
SELECT * FROM products
WHERE to_tsvector('english', name || ' ' || description)
  @@ to_tsquery('english', 'wireless & headphones');

-- Time-series with TimescaleDB extension
SELECT time_bucket('1 hour', timestamp) AS bucket,
       AVG(value) AS avg_value
FROM metrics
WHERE timestamp > NOW() - INTERVAL '7 days'
GROUP BY bucket
ORDER BY bucket;

-- 10k TPS on commodity hardware with connection pooling (PgBouncer)
-- 100k TPS on dedicated high-memory instance
-- Row-level security for multi-tenancy
-- LISTEN/NOTIFY for lightweight event signaling
```

### When to Add Redis

```typescript
// Redis IS appropriate for:

// 1. Session storage (TTL-managed, fast)
await redis.setex(`session:${sessionId}`, 86400, JSON.stringify(sessionData));

// 2. Rate limiting (atomic increment)
const count = await redis.incr(`rate:${userId}`);
if (count === 1) await redis.expire(`rate:${userId}`, 3600);

// 3. Distributed locks (see redis-deep skill for Redlock)
const lock = await redis.set(lockKey, lockId, 'NX', 'PX', 30000);

// 4. Real-time leaderboards
await redis.zadd('leaderboard', score, userId);
const top10 = await redis.zrevrange('leaderboard', 0, 9, 'WITHSCORES');

// 5. Cache for expensive queries (cache-aside pattern)
const cached = await redis.get(`product:${id}`);
if (cached) return JSON.parse(cached);
const product = await db.findProduct(id);
await redis.setex(`product:${id}`, 3600, JSON.stringify(product));
return product;

// Redis is NOT appropriate for:
// - Primary data store (no durability guarantees by default)
// - Complex queries (no joins, no aggregations)
// - Data larger than RAM budget
```

### When to Add ClickHouse (Analytics)

```sql
-- ClickHouse for analytical queries on large datasets
-- 1B row aggregation in ~2 seconds vs PostgreSQL's ~10 minutes

-- Example: revenue by country per day for last 90 days
SELECT
  toDate(created_at) AS date,
  country,
  sum(amount) AS revenue,
  count() AS order_count
FROM orders
WHERE created_at >= today() - 90
GROUP BY date, country
ORDER BY date DESC, revenue DESC;

-- PostgreSQL struggles here: columnar storage = 10–100x faster for analytics
-- ClickHouse typical: <2s for this query on 500M rows
-- PostgreSQL typical: 45–120s on same dataset

-- Write from PostgreSQL via CDC (Debezium → Kafka → ClickHouse)
-- Or direct insert from application
```

### MongoDB — When It's Actually Appropriate

MongoDB is appropriate when:
1. **Schema genuinely varies per document** and cannot be modeled with JSONB + table
2. **Deeply nested document writes** at high frequency (embedded arrays of objects)
3. **Scale > 10TB** with horizontal sharding requirements from day one
4. **Team has strong MongoDB expertise** and zero PostgreSQL expertise

```javascript
// Legitimate MongoDB use case: CMS with highly variable content blocks
// Each article type has completely different fields
{
  "_id": "article_123",
  "type": "product_review",
  "title": "...",
  "pros": ["fast", "light"],       // Array, type-specific
  "cons": ["expensive"],
  "rating": 4.5,
  "affiliate_links": { ... }        // Deeply nested, varies by product
}
// vs
{
  "_id": "article_456",
  "type": "tutorial",
  "title": "...",
  "steps": [...],                   // Completely different structure
  "code_examples": [...],
  "difficulty": "intermediate"
}
```

---

## Anti-Patterns ❌

### The MongoDB Incident (Using Document DB for Relational Data)

**The Incident**: Viktor chose MongoDB for a system with Users, Orders, Products, Inventory, and Reviews — all with relationships. "NoSQL is faster and more flexible."

**What broke**:
- Orders reference products by ID — but MongoDB has no foreign keys, so orphaned references accumulated
- "Get all orders with product details" required multiple round-trips (no joins)
- Inventory updates across order items required manual transaction simulation
- Data inconsistency found by Sasha: 47 documents with orphaned references after 3 months

**The fix**: PostgreSQL with JSONB for the few truly schema-less parts. Months of migration.

**Rule**: If your data has relationships (user HAS orders, order HAS items, item IS a product), use a relational database.

### Premature Polyglot Persistence

**What it is**: Using 6 different databases because each "excels" at its domain.
**Cost**: 6 operational concerns, 6 backup strategies, 6 expertise sets, 6 points of failure.
**When it breaks**: Your SRE is on-call for PostgreSQL, Redis, Elasticsearch, Kafka, MongoDB, AND ClickHouse. Alert fatigue. Nobody knows everything.

**Threshold**: Don't add a new database until PostgreSQL demonstrably fails to meet the requirement with evidence (slow queries, storage limits, missing features with benchmarks).

### Using Redis as Primary Database

**What breaks**: Redis AOF/RDB persistence is async by default — up to 1 second of data loss on crash. No complex queries. No transactions across keys without Lua scripts. Memory-only until data > RAM.
**Rule**: Redis is cache and ephemeral state. Never the source of truth for data you cannot afford to lose.

---

## Quick Reference

```
Default choice: PostgreSQL — handles 10k TPS, JSONB, full-text, geospatial
Add Redis for: sessions, rate limiting, caches, leaderboards, distributed locks
Add ClickHouse for: >100M row analytics (PG too slow)
Add Elasticsearch for: full-text search at >10M documents with ranking
Add TimescaleDB for: IoT metrics, time-series, high-frequency writes
MongoDB: only for truly schema-varying documents at scale
New DB threshold: PostgreSQL demonstrably fails with evidence — not "might be better"
```
