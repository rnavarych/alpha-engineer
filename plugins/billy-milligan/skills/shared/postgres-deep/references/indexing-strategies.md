# PostgreSQL Indexing Strategies

## When to Load
Load when designing indexes for a new table, choosing between index types, or understanding which index structure fits a query pattern.

## Index Type Decision Tree

```
What does your query do?
├── Equality/range on scalar column (int, text, timestamp) → B-tree (default)
├── JSONB containment (@>), array overlap (&&), full-text search (@@ tsquery) → GIN
├── Geometric/spatial queries (PostGIS), range type overlap, nearest-neighbor → GiST
├── Append-only time-series, large monotonic columns, low cardinality → BRIN
└── Equality only, fast build, no range scan → Hash (rarely used in practice)
```

## B-tree Indexes

```sql
-- Single column: equality and range
CREATE INDEX idx_orders_user_id ON orders(user_id);

-- Composite: left-prefix rule
-- Covers: (user_id), (user_id, created_at), but NOT (created_at) alone
CREATE INDEX idx_orders_user_created ON orders(user_id, created_at DESC);
-- Query: WHERE user_id = $1 ORDER BY created_at DESC → uses index fully
-- Query: WHERE user_id = $1 AND created_at > $2 → uses both columns
-- Query: WHERE created_at > $2 → cannot use this index (missing left prefix)

-- Covering index: INCLUDE eliminates heap fetch (index-only scan)
CREATE INDEX idx_orders_user_covering ON orders(user_id, created_at DESC)
INCLUDE (id, total, status);
-- Query: SELECT id, total, status FROM orders WHERE user_id=$1 ORDER BY created_at DESC
-- → Index Only Scan: zero table access
```

## GIN Indexes

```sql
-- JSONB containment and key existence
CREATE INDEX idx_events_metadata ON events USING GIN(metadata);
SELECT * FROM events WHERE metadata @> '{"type": "click"}';
SELECT * FROM events WHERE metadata ? 'user_id';

-- GIN on specific JSONB path (faster build, smaller index)
CREATE INDEX idx_events_type ON events USING GIN((metadata -> 'type'));

-- Full-text search
CREATE INDEX idx_products_fts ON products
USING GIN(to_tsvector('english', name || ' ' || coalesce(description, '')));

-- Array operators
CREATE INDEX idx_posts_tags ON posts USING GIN(tags);
SELECT * FROM posts WHERE tags && ARRAY['postgres', 'performance'];  -- overlap
SELECT * FROM posts WHERE tags @> ARRAY['postgres'];                  -- contains
```

## GiST Indexes

```sql
-- PostGIS spatial queries
CREATE INDEX idx_stores_location ON stores USING GIST(location);
SELECT name, location <-> ST_MakePoint(-73.9857, 40.7484) AS distance
FROM stores
ORDER BY location <-> ST_MakePoint(-73.9857, 40.7484)
LIMIT 5;

-- Range type overlap
CREATE INDEX idx_bookings_range ON bookings USING GIST(tstzrange(start_at, end_at));
SELECT * FROM bookings
WHERE tstzrange(start_at, end_at) && tstzrange($check_in, $check_out);
```

## BRIN Indexes

```sql
-- Extremely small index (128 bytes per range, not per row)
-- Only useful when: data is physically ordered on disk (append-only inserts)
CREATE INDEX idx_events_created_brin ON events
USING BRIN(created_at) WITH (pages_per_range = 128);
-- For 1B row events table: BRIN index = ~8MB vs B-tree = ~20GB

-- Not useful when:
-- Rows are randomly distributed (updates, deletions change physical order)
-- High-cardinality queries with precise predicates → B-tree is better
```

## Quick Reference

```
B-tree:  equality, range, ORDER BY — most indexes
GIN:     JSONB @>, ?; array &&, @>; full-text @@
GiST:    spatial <->, range &&, nearest-neighbor
BRIN:    append-only time-series; 1/10000 size of B-tree
Composite: left-prefix rule; equality columns first, then range, then ORDER BY
Covering: INCLUDE columns → index-only scan, no heap fetch
```
