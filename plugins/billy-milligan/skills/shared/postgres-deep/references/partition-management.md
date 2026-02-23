# PostgreSQL Partition Management

## When to Load
Load when automating partition creation and retention, migrating an existing table to a partitioned one, or maintaining a partitioned schema in production.

## Partition Maintenance Operations

```sql
-- Add new monthly partition (automate this; never do it manually in prod)
CREATE TABLE events_2024_03 PARTITION OF events
  FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');
CREATE INDEX ON events_2024_03 (user_id, created_at DESC);

-- Drop old partition instantly (vs DELETE which is slow and bloating)
-- Detach first to allow concurrent queries to finish
ALTER TABLE events DETACH PARTITION events_2022_01 CONCURRENTLY;
DROP TABLE events_2022_01;
-- Dropping 100M rows: 0.01 seconds (just removes partition directory)
-- Deleting 100M rows: 10-30 minutes with heavy I/O

-- Archive partition to cheaper storage before dropping
CREATE TABLE events_2022_01 (LIKE events INCLUDING ALL);
-- Restore data into it, then re-attach:
ALTER TABLE events ATTACH PARTITION events_2022_01
  FOR VALUES FROM ('2022-01-01') TO ('2022-02-01');

-- Check partition sizes
SELECT
  child.relname                               AS partition_name,
  pg_size_pretty(pg_relation_size(child.oid)) AS partition_size,
  pg_stat_user_tables.n_live_tup              AS row_estimate
FROM pg_inherits
JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
JOIN pg_class child  ON pg_inherits.inhrelid  = child.oid
LEFT JOIN pg_stat_user_tables ON pg_stat_user_tables.relname = child.relname
WHERE parent.relname = 'events'
ORDER BY child.relname;
```

## pg_partman Extension (Automated Management)

```sql
-- pg_partman automates partition creation and retention
-- Installation: CREATE EXTENSION pg_partman;

SELECT partman.create_parent(
  p_parent_table => 'public.events',
  p_control      => 'created_at',
  p_type         => 'range',
  p_interval     => 'monthly',  -- 'daily', 'weekly', 'monthly', 'yearly'
  p_premake      => 3           -- Pre-create 3 future partitions
);

-- Retention: automatically drop partitions older than 12 months
UPDATE partman.part_config
SET retention            = '12 months',
    retention_keep_table = false
WHERE parent_table = 'public.events';

-- Run maintenance (schedule with pg_cron every hour)
SELECT partman.run_maintenance('public.events');

-- pg_cron schedule
SELECT cron.schedule('partition-maintenance', '0 * * * *',
  $$SELECT partman.run_maintenance()$$);
```

## Anti-Patterns

### Partitioning Without Partition Key in Queries
If 80% of your queries do `SELECT * FROM events WHERE user_id = $1` (no `created_at`), partitioning by `created_at` means every query scans all partitions. Performance is worse than unpartitioned. Partition by user_id (hash) or redesign queries.

### Too Many Partitions
1000+ partitions cause planner overhead for partition pruning itself. Daily partitions over 10 years = 3650 partitions. Use monthly (120 partitions) instead.

### Forgetting to Create Indexes on New Partitions
Each partition needs its own indexes. Forgetting means the new partition does Seq Scans. Automate index creation as part of partition creation — use pg_partman or a migration script.

## Quick Reference

```
DETACH PARTITION CONCURRENTLY: safe removal without blocking reads
DROP TABLE on partition: instant even for 100M+ rows
ATTACH PARTITION: restore archived data back into the parent table
pg_partman: create_parent() + retention policy + run_maintenance() via pg_cron
p_premake = 3: always pre-create future partitions; never let them go missing
Too many partitions: monthly is the sweet spot; daily only for short retention windows
```
