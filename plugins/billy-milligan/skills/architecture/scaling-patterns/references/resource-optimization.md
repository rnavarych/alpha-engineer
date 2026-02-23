# Resource Optimization

## When to load
Load when discussing memory profiling, CPU bottleneck identification, heap leak detection, I/O optimization, or response compression for a running service.

## Patterns

### CPU profiling
```typescript
// Node.js built-in profiler
// node --prof app.js
// node --prof-process isolate-*.log > profile.txt

// Common CPU hotspots and fixes:
// - Synchronous JSON parsing of large payloads -> use streaming parser
// - Regex on every request -> compile once, reuse
// - Tight loops in request handlers -> move to worker thread or background job

import { Worker } from 'worker_threads';

async function heavyComputation(data: unknown): Promise<unknown> {
  return new Promise((resolve, reject) => {
    const worker = new Worker('./compute-worker.js', { workerData: data });
    worker.on('message', resolve);
    worker.on('error', reject);
  });
}

// clinic.js for production-safe profiling
// npx clinic doctor -- node app.js
// npx clinic flame -- node app.js  (flame graph)
// npx clinic bubbleprof -- node app.js  (async bottlenecks)
```

### Memory leak detection
```typescript
// Node.js memory defaults: ~1.5GB heap (64-bit)
// Increase if needed: node --max-old-space-size=4096 app.js

// Heap snapshot comparison:
// node --inspect app.js
// Chrome DevTools -> Memory -> Take heap snapshot -> do action -> Take again -> Compare

// Common leaks:
// - Event listeners not removed
// - Growing arrays/maps without bounds
// - Closures holding references to large objects
// - Unbounded caches (fix: use LRU with max size)

import { LRUCache } from 'lru-cache';
const cache = new LRUCache({
  max: 10000,           // max items (prevents unbounded growth)
  maxSize: 50_000_000,  // 50MB max memory
  sizeCalculation: (value) => JSON.stringify(value).length,
  ttl: 300_000,         // 5 min TTL
});
```

```typescript
// Periodic heap usage logging (catch slow leaks early)
setInterval(() => {
  const mem = process.memoryUsage();
  logger.info({
    event: 'heap.usage',
    heapUsedMB: Math.round(mem.heapUsed / 1024 / 1024),
    heapTotalMB: Math.round(mem.heapTotal / 1024 / 1024),
    rssMB: Math.round(mem.rss / 1024 / 1024),
  });
}, 30_000);

// Alert if heapUsed / heapTotal > 0.85 (85% heap utilization)
```

### I/O optimization
```typescript
// 1. N+1 query prevention with DataLoader
import DataLoader from 'dataloader';

const userLoader = new DataLoader<string, User>(async (ids) => {
  const users = await db.query(
    'SELECT * FROM users WHERE id = ANY($1)',
    [ids]
  );
  return ids.map(id => users.find(u => u.id === id));
});
// Batches multiple getUser() calls into a single query per tick

// 2. Response compression
import compression from 'compression';
app.use(compression({ threshold: 1024 })); // compress responses >1KB

// 3. Streaming large responses instead of buffering
import { createReadStream } from 'fs';

app.get('/export/orders', async (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  res.setHeader('Transfer-Encoding', 'chunked');

  const cursor = db.query('SELECT * FROM orders').cursor(100);
  for await (const row of cursor) {
    res.write(JSON.stringify(row) + '\n');
  }
  res.end();
});
```

### Bottleneck identification checklist
```
1. Is CPU > 80% sustained?
   -> Profile with --prof or clinic flame
   -> Look for hot functions, synchronous operations

2. Is memory growing without bound?
   -> Heap snapshot diff over time
   -> Check for unbounded caches, event listeners, closures

3. Is I/O wait high?
   -> EXPLAIN ANALYZE on slow queries
   -> Check for sequential scans, missing indexes, N+1 patterns

4. Is connection pool saturated?
   -> Log pool.waitingCount and pool.idleCount
   -> Add PgBouncer if app instances > 10

5. Is bandwidth the limit?
   -> Enable compression (gzip/brotli)
   -> Check payload sizes, paginate large responses
   -> Use CDN for static assets
```

## Anti-patterns
- Increasing instance size without profiling -> hiding the real problem
- Ignoring compression -> sending 5x more bytes than necessary over the wire
- Unbounded in-process caches -> OOM kills in production at 3 AM
- Profiling in dev with small data sets -> production behavior is completely different

## Quick reference
```
CPU: node --prof + --prof-process, or clinic flame
Memory: heap snapshot diff in Chrome DevTools, log heapUsed every 30s
LRU cache: always set max items + maxSize, never unbounded
Compression: enable for responses >1KB (gzip threshold)
N+1: DataLoader batching, one query per tick
Streaming: cursor-based for large exports, never buffer full result set
Alert: heapUsed/heapTotal > 85%, CPU > 80% for >5 min
```
