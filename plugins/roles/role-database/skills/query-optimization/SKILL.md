---
name: role-database:query-optimization
description: |
  Cross-engine query optimization guide. EXPLAIN/EXPLAIN ANALYZE across PostgreSQL, MySQL, MongoDB, Cassandra, ClickHouse. Index strategies (B-tree, hash, GIN, GiST, BRIN, partial, covering, composite). N+1 detection, cursor-based pagination, materialized views, query plan analysis, slow query diagnosis. Use when optimizing slow queries, designing indexes, or analyzing query performance.
allowed-tools: Read, Grep, Glob, Bash
---

# Query Optimization

## Reference Files

Load from `references/` based on what's needed:

### references/explain-indexes.md
EXPLAIN analysis for PostgreSQL (red flags, buffer hit ratio), MySQL (type column, FORMAT=TREE), MongoDB (executionStats, COLLSCAN vs IXSCAN), ClickHouse (system.query_log).
Index type comparison table (B-tree, Hash, GIN, GiST, BRIN, partial, covering).
Composite index design rules (equality first, range last, selectivity order).
Partial indexes and covering indexes with INCLUDE. Statistics and cardinality management.
Load when: analyzing query plans, designing indexes, or fixing stale statistics.

### references/pagination-antipatterns.md
N+1 detection via pg_stat_statements, elimination patterns (eager load, DataLoader, window functions).
Offset vs cursor-based pagination with multi-column cursor example.
Materialized views: creation, blocking vs concurrent refresh, automated refresh strategies.
Query anti-patterns: SELECT *, functions on indexed columns, correlated subqueries, implicit type conversions, missing LIMIT.
Load when: fixing N+1 problems, implementing pagination, or eliminating slow query patterns.
