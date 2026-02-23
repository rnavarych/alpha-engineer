---
name: postgres-deep
description: |
  PostgreSQL deep-dive: EXPLAIN ANALYZE interpretation, index types (B-tree, GIN, GiST, BRIN),
  partial/covering/composite indexes, pg_stat_statements slow query analysis, Row Level Security,
  window functions, CTEs, advisory locks, LISTEN/NOTIFY, connection pooling with PgBouncer.
  Use when optimizing slow queries, designing indexing strategy, implementing multi-tenancy.
allowed-tools: Read, Grep, Glob
---

# PostgreSQL Deep Dive

## When to Use This Skill
- Optimizing slow queries with EXPLAIN ANALYZE
- Designing indexes for specific access patterns
- Implementing Row Level Security for multi-tenancy
- Using window functions for analytics queries
- Configuring PgBouncer for connection pooling

## Core Principles

1. **EXPLAIN ANALYZE before optimizing** — never guess; measure first; the plan shows the actual cost
2. **Index the access pattern, not the column** — a composite index `(user_id, created_at DESC)` beats two separate indexes for paginated user queries
3. **Partial indexes reduce size and maintenance cost** — `WHERE status = 'pending'` on a 10M row table with 1000 pending rows = tiny, fast index
4. **RLS is enforced at the DB layer** — even if application code has a bug, unauthorized rows are invisible
5. **pg_stat_statements is your slow query log** — enable it; it shows cumulative query costs across all calls

## References available
- `references/query-optimization.md` — EXPLAIN ANALYZE interpretation, node types, warning signs, stale statistics, work_mem, CTEs
- `references/query-anti-patterns.md` — N+1 queries, missing FK indexes, over-fetching, OFFSET pagination, NOT IN gotcha, DISTINCT misuse
- `references/indexing-strategies.md` — B-tree, GIN, GiST, BRIN index types; composite and covering indexes; index type decision tree
- `references/index-tuning.md` — partial indexes, expression indexes, index maintenance, unused/bloated index detection, CONCURRENTLY
- `references/partitioning.md` — range/list/hash partitioning, when to partition, partition pruning, partitioned table constraints
- `references/partition-management.md` — partition maintenance, DETACH/DROP/ATTACH, pg_partman automation, anti-patterns
- `references/connection-pooling.md` — PgBouncer setup, pool modes (session/transaction/statement), pool sizing, application config
- `references/connection-diagnostics.md` — SHOW POOLS, pg_stat_activity monitoring, connection troubleshooting runbook, Kubernetes deploy

## Scripts available
- `scripts/analyze-slow-queries.sh` — query pg_stat_statements for top consumers and low cache-hit queries
