# Graph, Time-Series, Dimensional, and Data Vault Modeling

## When to load
Load when designing graph data models (labeled property graph, RDF), time-series schemas (TimescaleDB, partitioning), data warehouse dimensional models (star/snowflake schema, SCD), or Data Vault structures. Also covers polyglot persistence decisions.

## Graph Data Modeling

### Labeled Property Graph Model
```
(Person {name: "Alice", age: 30})-[:KNOWS {since: 2020}]->(Person {name: "Bob"})
(Person {name: "Alice"})-[:WORKS_AT {role: "Engineer"}]->(Company {name: "Acme"})
```

**Best Practices:**
- Nodes = nouns (entities), Relationships = verbs (actions/connections)
- Properties on relationships for metadata (weight, timestamp, type)
- Use labels for type categorization (`:Person`, `:Company`, `:Product`)
- Model bidirectional as single relationship with direction (query both ways)

### RDF Triple Model
```
<http://example.org/Alice> <http://xmlns.com/foaf/0.1/knows> <http://example.org/Bob> .
```
Subject-Predicate-Object. URIs for global identity. SPARQL for querying. Use for semantic web, knowledge graphs, linked data.

## Time-Series Data Modeling

### Design Principles
1. **Partition by time**: Range partition on timestamp (daily, weekly, monthly)
2. **Tags vs fields**: Tags are indexed metadata (device_id, region), fields are measured values
3. **Cardinality control**: Limit tag value combinations (high cardinality = performance killer)
4. **Downsampling**: Define retention tiers (raw → 1min → 1hour → 1day)

### TimescaleDB and Native Partitioning
```sql
-- TimescaleDB hypertable
CREATE TABLE metrics (
    time        TIMESTAMPTZ NOT NULL,
    device_id   TEXT NOT NULL,
    metric_name TEXT NOT NULL,
    value       DOUBLE PRECISION NOT NULL,
    tags        JSONB
);
SELECT create_hypertable('metrics', 'time');

-- PostgreSQL native range partitioning
CREATE TABLE metrics (
    time TIMESTAMPTZ NOT NULL, device_id TEXT NOT NULL, value DOUBLE PRECISION NOT NULL
) PARTITION BY RANGE (time);

CREATE TABLE metrics_2024_01 PARTITION OF metrics
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
```

## Dimensional Modeling (Data Warehouse)

### Star Schema Structure
```
Fact table: measures (quantity, revenue, cost) + FKs to dimension tables
Grain = finest level of detail (one row per transaction line item)

Dimension tables: descriptive attributes, denormalized for query performance
```

### Slowly Changing Dimensions (SCD)

| Type | Strategy | Tracks History | Example |
|------|----------|---------------|---------|
| **SCD 1** | Overwrite | No | Fix typos, current address |
| **SCD 2** | New row + effective dates | Yes | Customer address changes |
| **SCD 3** | Previous value column | Limited | Store current + previous only |
| **SCD 6** | Hybrid 1+2+3 | Yes | Current flag + effective dates + previous |

### SCD Type 2 Implementation
```sql
CREATE TABLE dim_customer (
    customer_key  BIGINT PRIMARY KEY,
    customer_id   TEXT NOT NULL,
    name TEXT, address TEXT, city TEXT,
    effective_from DATE NOT NULL,
    effective_to   DATE NOT NULL DEFAULT '9999-12-31',
    is_current     BOOLEAN NOT NULL DEFAULT true
);

UPDATE dim_customer SET effective_to = CURRENT_DATE, is_current = false
WHERE customer_id = 'CUST-001' AND is_current = true;

INSERT INTO dim_customer (customer_key, customer_id, name, address, city, effective_from, is_current)
VALUES (nextval('customer_key_seq'), 'CUST-001', 'Alice', 'New Address', 'New City', CURRENT_DATE, true);
```

## Data Vault

| Component | Purpose |
|-----------|---------|
| **Hub** | Business keys (customer_id, order_id) — hash key, business key, load date, source |
| **Link** | Relationships between hubs — hub FKs, load date, source |
| **Satellite** | Descriptive attributes — hub/link FK, load date, hash diff |

Advantages: full audit history, parallel loadable, flexible to add new sources, Raw Vault → Business Vault.

## Polyglot Persistence

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

**Consistency patterns:** CDC (Debezium) from primary to secondary stores, Saga/Outbox for distributed transactions, CQRS (write to PostgreSQL, read from Elasticsearch/Redis).
