#!/usr/bin/env bash
# analyze-slow-queries.sh
# Reads pg_stat_statements to surface the top optimization targets.
# Usage: ./analyze-slow-queries.sh [--limit N] [--min-calls N] [--dsn "postgresql://..."]
# Requires: psql in PATH, pg_stat_statements extension enabled on target database

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
LIMIT=15
MIN_CALLS=5
DSN="${DATABASE_URL:-postgresql://localhost:5432/postgres}"

# ── Argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --limit)     LIMIT="$2";     shift 2 ;;
    --min-calls) MIN_CALLS="$2"; shift 2 ;;
    --dsn)       DSN="$2";       shift 2 ;;
    -h|--help)
      echo "Usage: $0 [--limit N] [--min-calls N] [--dsn DSN]"
      echo "  --limit     Number of queries to return (default: 15)"
      echo "  --min-calls Ignore queries with fewer calls (default: 5)"
      echo "  --dsn       PostgreSQL DSN (default: \$DATABASE_URL)"
      exit 0 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# ── Check extension ───────────────────────────────────────────────────────────
echo "=== Checking pg_stat_statements ==="
EXTENSION_CHECK=$(psql "$DSN" -tAc "SELECT COUNT(*) FROM pg_extension WHERE extname = 'pg_stat_statements'" 2>/dev/null || echo "0")
if [[ "$EXTENSION_CHECK" == "0" ]]; then
  echo "ERROR: pg_stat_statements extension is not installed."
  echo "Add to postgresql.conf: shared_preload_libraries = 'pg_stat_statements'"
  echo "Then run: CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"
  exit 1
fi
echo "pg_stat_statements: OK"
echo ""

# ── 1. Top queries by total execution time ────────────────────────────────────
echo "=== TOP ${LIMIT} QUERIES BY TOTAL EXECUTION TIME ==="
echo "(These are the highest-ROI optimization targets)"
echo ""
psql "$DSN" -P pager=off <<SQL
SELECT
  LEFT(regexp_replace(query, '\s+', ' ', 'g'), 120) AS query_snippet,
  calls,
  ROUND(total_exec_time::numeric / 1000, 2)          AS total_sec,
  ROUND(mean_exec_time::numeric, 2)                   AS mean_ms,
  ROUND(stddev_exec_time::numeric, 2)                 AS stddev_ms,
  ROUND(100.0 * shared_blks_hit
        / NULLIF(shared_blks_hit + shared_blks_read, 0), 1) AS cache_hit_pct,
  rows
FROM pg_stat_statements
WHERE calls >= ${MIN_CALLS}
ORDER BY total_exec_time DESC
LIMIT ${LIMIT};
SQL

echo ""

# ── 2. Top queries by mean execution time (worst average latency) ─────────────
echo "=== TOP ${LIMIT} QUERIES BY MEAN LATENCY ==="
echo "(Queries with highest per-call cost — candidates for index optimization)"
echo ""
psql "$DSN" -P pager=off <<SQL
SELECT
  LEFT(regexp_replace(query, '\s+', ' ', 'g'), 120) AS query_snippet,
  calls,
  ROUND(mean_exec_time::numeric, 2)                  AS mean_ms,
  ROUND(max_exec_time::numeric, 2)                   AS max_ms,
  ROUND(stddev_exec_time::numeric, 2)                AS stddev_ms
FROM pg_stat_statements
WHERE calls >= ${MIN_CALLS}
  AND mean_exec_time > 10  -- Only queries averaging >10ms
ORDER BY mean_exec_time DESC
LIMIT ${LIMIT};
SQL

echo ""

# ── 3. Worst cache hit ratio (reading from disk) ──────────────────────────────
echo "=== TOP ${LIMIT} QUERIES BY WORST CACHE HIT RATIO ==="
echo "(These are hammering disk — missing index or cold cache)"
echo ""
psql "$DSN" -P pager=off <<SQL
SELECT
  LEFT(regexp_replace(query, '\s+', ' ', 'g'), 100) AS query_snippet,
  calls,
  shared_blks_hit                                    AS cache_hits,
  shared_blks_read                                   AS disk_reads,
  ROUND(100.0 * shared_blks_hit
        / NULLIF(shared_blks_hit + shared_blks_read, 0), 1) AS cache_hit_pct
FROM pg_stat_statements
WHERE calls >= ${MIN_CALLS}
  AND shared_blks_read > 100   -- Only queries doing meaningful disk reads
ORDER BY cache_hit_pct ASC
LIMIT ${LIMIT};
SQL

echo ""

# ── 4. Table-level sequential scan counts ─────────────────────────────────────
echo "=== TABLES WITH HIGH SEQUENTIAL SCANS (possible missing indexes) ==="
echo ""
psql "$DSN" -P pager=off <<SQL
SELECT
  relname                                               AS table_name,
  seq_scan,
  idx_scan,
  ROUND(100.0 * idx_scan / NULLIF(seq_scan + idx_scan, 0), 1) AS idx_hit_pct,
  pg_size_pretty(pg_total_relation_size(relid))         AS table_size,
  n_live_tup                                            AS live_rows
FROM pg_stat_user_tables
WHERE seq_scan > 50                  -- Ignore tables rarely scanned
  AND n_live_tup > 10000             -- Ignore tiny tables
ORDER BY seq_scan DESC
LIMIT 20;
SQL

echo ""

# ── 5. Unused indexes ─────────────────────────────────────────────────────────
echo "=== UNUSED INDEXES (write overhead with zero read benefit) ==="
echo ""
psql "$DSN" -P pager=off <<SQL
SELECT
  indexrelid::regclass                        AS index_name,
  relid::regclass                             AS table_name,
  idx_scan                                    AS times_used,
  pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
JOIN pg_index USING (indexrelid)
WHERE idx_scan = 0
  AND NOT indisprimary
  AND NOT indisunique         -- Keep unique constraints even if not queried directly
  AND schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC
LIMIT 20;
SQL

echo ""

# ── 6. Lock contention ────────────────────────────────────────────────────────
echo "=== CURRENT LOCK WAIT CHAINS ==="
echo "(Non-empty = active lock contention right now)"
echo ""
psql "$DSN" -P pager=off <<SQL
SELECT
  blocked_locks.pid           AS blocked_pid,
  blocked_activity.usename    AS blocked_user,
  blocking_locks.pid          AS blocking_pid,
  blocking_activity.usename   AS blocking_user,
  blocked_activity.query      AS blocked_statement,
  blocking_activity.query     AS blocking_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity
  ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks
  ON blocking_locks.locktype = blocked_locks.locktype
  AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
  AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity
  ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
SQL

echo ""
echo "=== Analysis complete. ==="
echo ""
echo "Next steps:"
echo "  1. EXPLAIN (ANALYZE, BUFFERS) <slow query> — get the actual query plan"
echo "  2. CREATE INDEX CONCURRENTLY on columns in WHERE/ORDER BY of top queries"
echo "  3. ANALYZE <table> if estimation errors are visible in EXPLAIN output"
echo "  4. Consider pg_stat_statements_reset() after tuning to measure improvement"
