---
name: data-modeling
description: |
  Data modeling methodologies and patterns across paradigms. Entity-Relationship modeling (Chen, Crow's Foot, UML), document modeling (embedding vs referencing, polymorphic, bucket, outlier patterns), graph modeling (labeled property graph, RDF), time-series modeling, event sourcing, dimensional modeling (star/snowflake schema, SCD), Data Vault (hubs, links, satellites), polyglot persistence. Use when designing data models, choosing between modeling approaches, or mapping domain models to database schemas.
allowed-tools: Read, Grep, Glob, Bash
---

# Data Modeling

## Relational Data Modeling

### Entity-Relationship Modeling

**Notation Systems:**
| Notation | Origin | Key Feature |
|----------|--------|-------------|
| **Chen** | Peter Chen (1976) | Diamonds for relationships, circles for attributes |
| **Crow's Foot** | Gordon Everest | Fork symbol for "many", most popular in industry |
| **UML Class Diagram** | OMG | Software engineering style, multiplicity labels |
| **IDEF1X** | US DoD | Formal, identifying vs non-identifying relationships |

**Relationship Types:**
| Type | Example | Implementation |
|------|---------|----------------|
| **1:1** | User ↔ Profile | FK with UNIQUE constraint, or same table |
| **1:N** | Customer → Orders | FK on the "many" side |
| **M:N** | Students ↔ Courses | Junction/bridge table with composite FK |
| **Self-referential** | Employee → Manager | FK referencing same table |
| **Polymorphic** | Comment → Post/Photo | Separate FKs per type (not commentable_type + commentable_id) |

### Normalization Decision Guide

| Scenario | Target Normal Form | Reason |
|----------|-------------------|--------|
| OLTP, simple queries | 3NF/BCNF | Balance integrity and performance |
| High-throughput writes | 3NF | Minimize update anomalies |
| Read-heavy reporting | 2NF with denormalization | Fewer joins, faster reads |
| Data warehouse | 1NF (dimensional model) | Optimized for analytical queries |
| Embedded/mobile | Pragmatic denormalization | Limited query capabilities |

## Document Data Modeling

### MongoDB Modeling Patterns

**Embedding vs Referencing Decision:**
| Factor | Embed | Reference |
|--------|-------|-----------|
| Relationship | 1:1, 1:few | 1:many, M:N |
| Access pattern | Always read together | Read independently |
| Update frequency | Rarely updated | Frequently updated |
| Data size | Small subdocument | Large or growing |
| Duplication | Acceptable | Unacceptable |

### Document Design Patterns

**Polymorphic Pattern:**
```javascript
// Different product types in same collection
{ _id: 1, type: "book", title: "...", author: "...", isbn: "..." }
{ _id: 2, type: "movie", title: "...", director: "...", runtime: 120 }
// Common fields indexed, type-specific fields vary
```

**Bucket Pattern (Time-Series):**
```javascript
// Group measurements into time buckets
{
    sensor_id: "temp-001",
    bucket_start: ISODate("2024-01-15T00:00:00Z"),
    bucket_end: ISODate("2024-01-15T01:00:00Z"),
    count: 60,
    measurements: [
        { ts: ISODate("2024-01-15T00:00:00Z"), value: 22.5 },
        { ts: ISODate("2024-01-15T00:01:00Z"), value: 22.6 },
        // ...60 measurements per document
    ],
    summary: { min: 22.1, max: 23.4, avg: 22.7 }
}
```

**Outlier Pattern:**
```javascript
// Most users have <100 followers, but some have millions
// Normal case: embed
{ _id: 1, name: "Alice", followers: ["user2", "user3", ...] }

// Outlier: overflow document
{ _id: 2, name: "Celebrity", followers: ["user1", ...], has_overflow: true }
{ _id: "2_overflow_1", base_user: 2, followers: [... more followers ...] }
```

**Subset Pattern:**
```javascript
// Product with many reviews: embed only recent/top reviews
{
    _id: 1,
    name: "Widget",
    price: 29.99,
    recent_reviews: [/* top 10 reviews */],
    review_count: 15234
}
// Full reviews in separate collection
{ product_id: 1, user_id: 42, rating: 5, text: "...", date: "..." }
```

**Computed Pattern:**
```javascript
// Pre-compute expensive aggregations
{
    _id: "movie-123",
    title: "...",
    rating_count: 45000,
    rating_sum: 180000,
    rating_avg: 4.0  // computed: sum/count
}
// Update atomically: { $inc: { rating_count: 1, rating_sum: 5 }, $set: { rating_avg: ... } }
```

## Graph Data Modeling

### Labeled Property Graph Model
```
(Person {name: "Alice", age: 30})-[:KNOWS {since: 2020}]->(Person {name: "Bob"})
(Person {name: "Alice"})-[:WORKS_AT {role: "Engineer"}]->(Company {name: "Acme"})
```

**Graph Modeling Best Practices:**
- Nodes = nouns (entities), Relationships = verbs (actions/connections)
- Properties on relationships for metadata (weight, timestamp, type)
- Avoid long property lists — use relationships for connected data
- Model bidirectional as single relationship with direction (query both ways)
- Use labels for type categorization (`:Person`, `:Company`, `:Product`)

### RDF Triple Model
```
<http://example.org/Alice> <http://xmlns.com/foaf/0.1/knows> <http://example.org/Bob> .
<http://example.org/Alice> <http://xmlns.com/foaf/0.1/name> "Alice" .
```
- Subject-Predicate-Object triples
- URIs for global identity
- SPARQL for querying
- Use for semantic web, knowledge graphs, linked data

## Time-Series Data Modeling

### Schema Design Principles
1. **Partition by time**: Range partition on timestamp (daily, weekly, monthly)
2. **Tags vs fields**: Tags are indexed metadata (device_id, region), fields are measured values (temperature, cpu_usage)
3. **Cardinality control**: Limit tag value combinations (high cardinality = performance killer)
4. **Downsampling**: Define retention tiers (raw → 1min → 1hour → 1day)

### Time-Series Table Design
```sql
-- PostgreSQL / TimescaleDB
CREATE TABLE metrics (
    time        TIMESTAMPTZ NOT NULL,
    device_id   TEXT NOT NULL,
    metric_name TEXT NOT NULL,
    value       DOUBLE PRECISION NOT NULL,
    tags        JSONB
);

-- TimescaleDB hypertable
SELECT create_hypertable('metrics', 'time');

-- Partition by time range (PostgreSQL native)
CREATE TABLE metrics (
    time TIMESTAMPTZ NOT NULL,
    device_id TEXT NOT NULL,
    value DOUBLE PRECISION NOT NULL
) PARTITION BY RANGE (time);

CREATE TABLE metrics_2024_01 PARTITION OF metrics
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
```

## Dimensional Modeling (Data Warehouse)

### Star Schema
```
           ┌──────────┐
           │ dim_date  │
           └─────┬────┘
                 │
┌──────────┐    │    ┌──────────────┐
│dim_product├────┼────┤ fact_sales    │
└──────────┘    │    └──────┬───────┘
                │           │
           ┌────┴────┐ ┌───┴──────┐
           │dim_store │ │dim_customer│
           └─────────┘ └──────────┘
```

**Fact Tables:**
- Contain measures (quantity, revenue, cost)
- Foreign keys to dimension tables
- Grain = finest level of detail (one row per transaction line item)

**Dimension Tables:**
- Descriptive attributes (product name, category, customer address)
- Denormalized for query performance
- Slowly Changing Dimensions (SCD) for historical tracking

### Slowly Changing Dimensions (SCD)

| Type | Strategy | Tracks History | Example |
|------|----------|---------------|---------|
| **SCD 0** | Retain original | No | Original signup date |
| **SCD 1** | Overwrite | No | Fix typos, current address |
| **SCD 2** | New row + effective dates | Yes | Customer address changes |
| **SCD 3** | Previous value column | Limited | Store current + previous only |
| **SCD 4** | Separate history table | Yes | Mini-dimension for rapidly changing |
| **SCD 6** | Hybrid 1+2+3 | Yes | Current flag + effective dates + previous value |

### SCD Type 2 Implementation
```sql
CREATE TABLE dim_customer (
    customer_key BIGINT PRIMARY KEY,       -- surrogate key
    customer_id TEXT NOT NULL,              -- natural/business key
    name TEXT, address TEXT, city TEXT,
    effective_from DATE NOT NULL,
    effective_to DATE NOT NULL DEFAULT '9999-12-31',
    is_current BOOLEAN NOT NULL DEFAULT true
);

-- New address: expire old, insert new
UPDATE dim_customer SET effective_to = CURRENT_DATE, is_current = false
WHERE customer_id = 'CUST-001' AND is_current = true;

INSERT INTO dim_customer (customer_key, customer_id, name, address, city, effective_from, is_current)
VALUES (nextval('customer_key_seq'), 'CUST-001', 'Alice', 'New Address', 'New City', CURRENT_DATE, true);
```

## Data Vault Modeling

### Components
| Component | Purpose | Keys |
|-----------|---------|------|
| **Hub** | Business keys (customer_id, order_id) | Hash key, business key, load date, source |
| **Link** | Relationships between hubs | Hash key, hub FKs, load date, source |
| **Satellite** | Descriptive attributes | Hub/Link FK, load date, attributes, hash diff |

### Data Vault Advantages
- **Auditable**: Full history with load dates and sources
- **Flexible**: Add new sources without restructuring
- **Parallel loadable**: Hubs, links, satellites load independently
- **Raw Vault**: Store data as-is from source → Business Vault: apply business rules

## Polyglot Persistence

### Pattern: Right Database for Each Data Type

| Data Type | Recommended Database | Reason |
|-----------|---------------------|--------|
| User accounts, orders | PostgreSQL | ACID, relational, complex queries |
| Session/cache | Redis | Fast read/write, TTL, ephemeral |
| Product search | Elasticsearch / Typesense | Full-text, faceted, ranking |
| Social graph | Neo4j | Traversals, recommendations |
| Time-series metrics | TimescaleDB / InfluxDB | Compression, aggregation |
| File metadata | MongoDB | Flexible schema, embedded docs |
| ML embeddings | pgvector / Pinecone | Vector similarity search |
| Event log | Kafka | Ordered, durable, replayable |

### Consistency Across Stores
- **Eventual consistency**: CDC (Debezium) from primary to secondary stores
- **Saga pattern**: Distributed transactions across stores
- **Outbox pattern**: Write event to outbox table → CDC → publish to other stores
- **CQRS**: Write to primary (PostgreSQL), read from projections (Elasticsearch, Redis)

## Modeling Tools

| Tool | Type | Best For |
|------|------|----------|
| **dbdiagram.io** | Web | Quick ER diagrams with DSL |
| **ERDPlus** | Web | Academic ER modeling |
| **Moon Modeler** | Desktop | Visual, MongoDB/PostgreSQL/MySQL |
| **DataGrip** | Desktop | JetBrains, schema visualization |
| **pgModeler** | Desktop | PostgreSQL-specific, generates DDL |
| **Prisma visualizer** | CLI | From Prisma schema file |
| **DBeaver** | Desktop | Universal, ER from existing DB |
| **DrawSQL** | Web | Collaborative, export DDL |
