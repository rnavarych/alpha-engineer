---
name: performance
description: |
  Performance optimization: PostgreSQL slow query profiling with EXPLAIN ANALYZE, Node.js
  profiling with clinic.js, response time budgets (auth <5ms, DB <50ms), bundle analysis,
  Core Web Vitals targets, N+1 detection, memory leak patterns. Use when investigating
  performance issues, setting performance budgets, optimizing slow endpoints.
allowed-tools: Read, Grep, Glob
---

# Performance Optimization

## When to Use This Skill
- Investigating slow API endpoints or database queries
- Setting and measuring performance budgets
- Optimizing Core Web Vitals for web applications
- Profiling Node.js memory and CPU usage
- Finding and fixing N+1 queries

## Core Principles

1. **Measure before optimizing** — guessing is expensive; profiling is cheap
2. **Database is usually the bottleneck** — 90% of API latency is DB time
3. **Response time budget** — break down your 200ms target into components
4. **N+1 kills at scale** — 10 users: unnoticeable. 1000 users: outage.
5. **Core Web Vitals are ranking signals** — LCP, CLS, INP affect SEO and conversion

---

## Patterns ✅

### Response Time Budget

```
Target: p99 API response < 500ms, p50 < 100ms

Budget breakdown for a typical API endpoint:
  Framework overhead:     1–5ms
  Auth/middleware:        2–10ms
  Database query:         5–50ms (simple), 50–200ms (complex)
  Cache lookup:           0.5–2ms (Redis)
  Business logic:         1–10ms
  Serialization:          1–5ms
  Network (same region):  0.5–2ms
  ─────────────────────
  Target p50 total:       ~50–100ms
  Target p99 total:       ~200–500ms

Alert thresholds:
  p50 > 100ms: investigation needed
  p99 > 500ms: immediate action
  p99 > 1000ms: incident
```

### PostgreSQL EXPLAIN ANALYZE

```sql
-- Always run EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) to see actual execution
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT o.id, o.total, u.name, u.email
FROM orders o
JOIN users u ON u.id = o.user_id
WHERE o.status = 'pending'
  AND o.created_at > NOW() - INTERVAL '7 days'
ORDER BY o.created_at DESC
LIMIT 50;

-- Read the output:
-- Seq Scan (Sequential): BAD for large tables — reads every row
-- Index Scan: GOOD — uses index to find rows
-- Index Only Scan: BEST — answer from index alone (covering index)
-- Nested Loop: good for small inner sets
-- Hash Join: good for large table joins
-- rows=X (actual rows): compared to rows=Y (estimated) shows statistics quality
-- Buffers: hit=X read=Y — hit=cache, read=disk. High read → consider more memory or better indexes

-- Identify slow queries from pg_stat_statements
SELECT
  query,
  calls,
  round(total_exec_time::numeric, 2) AS total_ms,
  round(mean_exec_time::numeric, 2) AS mean_ms,
  round((100 * total_exec_time / sum(total_exec_time) OVER ())::numeric, 2) AS percentage
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_%'
ORDER BY total_exec_time DESC
LIMIT 20;
```

### Adding Indexes for Performance

```sql
-- Simple index for equality + range queries
CREATE INDEX CONCURRENTLY idx_orders_status_created
  ON orders (status, created_at DESC)
  WHERE status != 'cancelled';  -- Partial index — smaller, faster

-- Covering index — query answered from index alone (Index Only Scan)
CREATE INDEX CONCURRENTLY idx_orders_user_list
  ON orders (user_id, created_at DESC)
  INCLUDE (id, status, total);  -- Include columns needed in SELECT

-- Before adding index: verify it's needed
EXPLAIN (ANALYZE) SELECT ... -- Check current plan
-- Add index
CREATE INDEX CONCURRENTLY idx_new ON table (column);
-- Re-run EXPLAIN to verify Index Scan is now used
-- If not used: query planner may have reasons (low selectivity, small table)
```

### Node.js Performance Profiling

```bash
# clinic.js — identifies bottlenecks in Node.js
npm install -g clinic

# CPU flame graph — find what's eating CPU
clinic flame -- node dist/server.js

# Event loop delay — find what's blocking the event loop
clinic bubbleprof -- node dist/server.js

# Memory profiling
clinic heapsampler -- node dist/server.js

# Load test while profiling
clinic flame -- node server.js &
ab -n 10000 -c 100 http://localhost:3000/api/orders  # Apply load during profiling
```

```typescript
// Track slow operations in code
const start = performance.now();
const result = await db.query(...);
const duration = performance.now() - start;

if (duration > 100) {
  logger.warn({ duration, query: 'fetchOrders' }, 'Slow database query');
}

// Prometheus histogram for latency distribution
const dbQueryDuration = new Histogram({
  name: 'db_query_duration_seconds',
  help: 'Database query duration',
  labelNames: ['operation'],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1],
});

async function trackedQuery<T>(operation: string, fn: () => Promise<T>): Promise<T> {
  const end = dbQueryDuration.startTimer({ operation });
  try {
    return await fn();
  } finally {
    end();
  }
}
```

### Core Web Vitals Optimization

```
Targets (Google's "Good" threshold):
  LCP (Largest Contentful Paint): < 2.5 seconds
  CLS (Cumulative Layout Shift):  < 0.1
  INP (Interaction to Next Paint): < 200ms
  TTFB (Time to First Byte):      < 800ms

LCP optimization:
  - Preload hero image: <link rel="preload" as="image" href="/hero.webp">
  - Use Next.js Image component: automatic WebP, lazy loading, srcset
  - CDN for static assets (CloudFront, Vercel Edge)
  - Avoid client-side rendering for above-the-fold content

CLS prevention:
  - Always set width/height on img elements (or use aspect-ratio CSS)
  - Reserve space for dynamic content (skeleton loaders with fixed height)
  - Avoid inserting content above existing content

INP optimization:
  - No heavy computation on main thread (use Web Workers)
  - Debounce input handlers: 300ms for search, 16ms for scroll
  - Virtualize long lists (react-window, TanStack Virtual)
  - Avoid synchronous localStorage in event handlers
```

### Bundle Analysis and Optimization

```bash
# Next.js bundle analysis
npm install @next/bundle-analyzer

# next.config.js
const withBundleAnalyzer = require('@next/bundle-analyzer')({
  enabled: process.env.ANALYZE === 'true',
});
module.exports = withBundleAnalyzer({});

# Run analysis
ANALYZE=true next build
# Opens interactive bundle visualization in browser

# Common bundle sizes:
# moment.js: 230KB — replace with date-fns (tree-shakeable)
# lodash: 70KB — replace with lodash-es or individual imports
# @mui/material full: 500KB — use tree-shaking imports
# recharts: 450KB — consider victory or visx for smaller bundles
```

---

## Anti-Patterns ❌

### Optimizing Without Measuring
**What it is**: "I think this is slow, let me add caching/indexes/rewrite it."
**What breaks**: You optimize the wrong thing. The actual bottleneck is elsewhere. You spent a week on a 5ms gain.
**Fix**: Profile first. Use `EXPLAIN ANALYZE`, flame graphs, Prometheus histograms. Optimize the actual bottleneck.

### SELECT * on Large Tables
**What it is**: `SELECT * FROM orders` when you only need `id, status, total`.
**What breaks**: Table with a `description TEXT` column (avg 5KB) × 1000 rows = 5MB over the wire when you needed 15KB.
**Multiplied by**: connection pool, ORM deserialization, JSON serialization.
**Fix**: Always specify columns. Add covering indexes for frequently-queried column sets.

### Synchronous Heavy Computation on Node.js Main Thread
**What it is**: Parsing 10MB JSON, computing bcrypt, image resizing — all in the event loop.
**What breaks**: Node.js is single-threaded. Heavy computation blocks ALL requests. p50 latency spikes for everyone while one request runs.
**Fix**: Web Workers for CPU-bound work. `worker_threads` for Node.js. `bcrypt` is async — but still 300ms of CPU time. Run expensive ops in worker pool.

---

## Quick Reference

```
Response budget: auth <10ms, DB <50ms, total p50 <100ms, p99 <500ms
EXPLAIN: always ANALYZE + BUFFERS — estimated rows vs actual rows
pg_stat_statements: find top-N slowest queries by total execution time
Partial index: WHERE clause on index — smaller, faster for filtered queries
Covering index: INCLUDE columns — enables Index Only Scan
clinic flame: CPU bottleneck in Node.js
clinic bubbleprof: event loop blocking in Node.js
LCP target: <2.5s | CLS: <0.1 | INP: <200ms
Bundle: moment (230KB) → date-fns, lodash → lodash-es
```
