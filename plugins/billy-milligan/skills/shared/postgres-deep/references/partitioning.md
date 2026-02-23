# PostgreSQL Table Partitioning

## When to Load
Load when a table exceeds ~50M rows and queries slow down despite indexing, or when you need time-based data expiry without expensive DELETE operations.

## When Partitioning Helps (and When It Does Not)

```
Helps:
  - Table > 50M rows and growing
  - Most queries filter on the partition key (e.g., WHERE created_at BETWEEN ...)
  - You need to drop old data fast (DROP TABLE on a partition = instant)
  - Bulk loads of new data can be COPY'd into a specific partition

Does NOT help:
  - Queries that scan ALL partitions (no partition key in WHERE) — actually slower
  - Tables with < 10M rows (overhead not worth it)
  - Frequent cross-partition joins (planner complexity increases)
```

## Range Partitioning (Time-Series)

```sql
-- Parent table: holds schema only, no data
CREATE TABLE events (
  id          BIGSERIAL,
  user_id     UUID NOT NULL,
  event_type  TEXT NOT NULL,
  payload     JSONB,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
) PARTITION BY RANGE (created_at);

-- Monthly partitions
CREATE TABLE events_2024_01 PARTITION OF events
  FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE events_2024_02 PARTITION OF events
  FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

-- Each partition can have its own indexes
CREATE INDEX ON events_2024_01 (user_id, created_at DESC);

-- Default partition catches rows that don't match any range
CREATE TABLE events_default PARTITION OF events DEFAULT;

-- Queries with partition key in WHERE → partition pruning
SELECT * FROM events
WHERE created_at BETWEEN '2024-01-01' AND '2024-01-31'
  AND user_id = $1;
-- → only scans events_2024_01

-- Verify partition pruning:
EXPLAIN SELECT * FROM events WHERE created_at >= '2024-01-01' AND created_at < '2024-02-01';
-- Look for: "Partitions selected: 1" in plan output
```

## List Partitioning (Region/Status)

```sql
CREATE TABLE orders (
  id         BIGSERIAL,
  region     TEXT NOT NULL,
  total      NUMERIC(12,2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
) PARTITION BY LIST (region);

CREATE TABLE orders_us    PARTITION OF orders FOR VALUES IN ('us');
CREATE TABLE orders_eu    PARTITION OF orders FOR VALUES IN ('eu');
CREATE TABLE orders_apac  PARTITION OF orders FOR VALUES IN ('apac');
CREATE TABLE orders_other PARTITION OF orders DEFAULT;

-- Useful when: data access is region-scoped, regulatory isolation needed
```

## Hash Partitioning (Even Distribution)

```sql
CREATE TABLE sessions (
  id         UUID PRIMARY KEY,
  user_id    UUID NOT NULL,
  data       JSONB,
  expires_at TIMESTAMPTZ NOT NULL
) PARTITION BY HASH (user_id);

CREATE TABLE sessions_0 PARTITION OF sessions FOR VALUES WITH (MODULUS 8, REMAINDER 0);
CREATE TABLE sessions_1 PARTITION OF sessions FOR VALUES WITH (MODULUS 8, REMAINDER 1);
-- ... through sessions_7

-- Use when: no time-based access pattern, want to limit per-partition size
-- Cannot drop old data by partition (no time dimension)
```

## Partitioned Table Constraints

```sql
-- Primary key and unique indexes must include the partition key
-- WRONG:
CREATE UNIQUE INDEX ON events(id);  -- ERROR if id is not the partition key

-- RIGHT:
ALTER TABLE events ADD CONSTRAINT events_pkey PRIMARY KEY (id, created_at);

-- Foreign keys TO a partitioned table require partition key in FK
-- Consider application-level references for cross-partition FKs
```

## Quick Reference

```
Use when: table > 50M rows, queries filter on partition key
Range:   time-series (monthly partitions); drop old months instantly
List:    discrete values (region, status with few values)
Hash:    even distribution when no natural key; can't expire by partition
Partition pruning: EXPLAIN must show "Partitions selected: N" not all
PK must include partition key — PostgreSQL requirement
Monthly partitions: sweet spot for most time-series (12-120 partitions)
```
