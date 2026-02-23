# Backend Performance

## Response Time Budget

```
Target: p50 < 100ms, p99 < 500ms

Budget breakdown for typical API endpoint:
  Framework overhead:     1-5ms
  Auth/middleware:        2-10ms
  Database query:         5-50ms (simple), 50-200ms (complex join)
  Cache lookup:           0.5-2ms (Redis)
  Business logic:         1-10ms
  Serialization:          1-5ms
  Network (same region):  0.5-2ms
  ────────────────────
  Total p50:              ~50-100ms
  Total p99:              ~200-500ms

Alert thresholds:
  p50 > 100ms:  investigation needed
  p99 > 500ms:  immediate action
  p99 > 1000ms: incident
```

## Node.js Profiling

```bash
# clinic.js — identify bottlenecks
npm install -g clinic

# CPU flame graph — what's consuming CPU
clinic flame -- node dist/server.js
# Then hit with load: ab -n 5000 -c 50 http://localhost:3000/api/orders

# Event loop delay — what's blocking the event loop
clinic bubbleprof -- node dist/server.js

# Memory profiling — find leaks
clinic heapprofiler -- node dist/server.js
```

```typescript
// Instrument slow operations
const start = performance.now();
const result = await db.query(stmt);
const durationMs = performance.now() - start;

if (durationMs > 100) {
  logger.warn({ durationMs, query: 'listOrders' }, 'Slow query detected');
}

// Prometheus histogram — latency distribution
import { Histogram } from 'prom-client';

const httpDuration = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5],
});

app.use((req, res, next) => {
  const end = httpDuration.startTimer({ method: req.method, route: req.route?.path });
  res.on('finish', () => end({ status: res.statusCode }));
  next();
});
```

## Python Profiling

```python
# cProfile — function-level profiling
import cProfile
cProfile.run('process_orders()', sort='cumulative')

# py-spy — production-safe profiling (no code changes)
# pip install py-spy
# py-spy top --pid <PID>                    # Live view
# py-spy record -o profile.svg --pid <PID>  # Flame graph

# line_profiler — line-by-line timing
@profile
def process_orders(orders):
    for order in orders:         # 2.3ms per iteration
        validate(order)           # 0.1ms
        save_to_db(order)         # 2.0ms  <-- bottleneck
        send_notification(order)  # 0.2ms
```

## Go Profiling

```go
import _ "net/http/pprof" // Enable pprof endpoints

// Access profiling data:
// http://localhost:8080/debug/pprof/
// CPU: go tool pprof http://localhost:8080/debug/pprof/profile?seconds=30
// Memory: go tool pprof http://localhost:8080/debug/pprof/heap
// Goroutines: go tool pprof http://localhost:8080/debug/pprof/goroutine

// Benchmarks
func BenchmarkProcessOrder(b *testing.B) {
    order := createTestOrder()
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        processOrder(order)
    }
}
// go test -bench=. -benchmem -count=5 ./...
```

## N+1 Detection

```typescript
// Detect: log query count per request
let queryCount = 0;
pool.on('query', () => queryCount++);

app.use((req, res, next) => {
  queryCount = 0;
  res.on('finish', () => {
    if (queryCount > 10) {
      logger.warn({ queryCount, path: req.path }, 'Potential N+1 detected');
    }
  });
  next();
});

// Fix: eager load with JOIN or batch
// Before: 1 + N queries (orders + user per order)
// After:  1 query (JOIN) or 2 queries (batch IN clause)
```

## Connection Pooling

```
Pool sizing rule of thumb:
  max_connections = CPU_cores x 2 + 1

  4 core server: pool_size = 9
  8 core server: pool_size = 17
  Default safe: pool_size = 20

Monitor pool health:
  - Active connections vs max
  - Wait time for connection
  - Idle connection count
  - Connection timeout errors
```

## Anti-Patterns
- Premature optimization — profile first, optimize the measured bottleneck
- `SELECT *` on wide tables — fetch only needed columns
- Sync computation on Node.js main thread — blocks all requests
- No connection pool monitoring — pool exhaustion discovered in production
- Missing request tracing — cannot correlate slow request to slow query

## Quick Reference
```
Budget: auth <10ms, DB <50ms, total p50 <100ms, p99 <500ms
Node.js: clinic flame (CPU), clinic bubbleprof (event loop)
Python: py-spy (production), cProfile (dev), line_profiler (detailed)
Go: pprof endpoints, go tool pprof, benchmarks with -benchmem
N+1: log query count per request, alert on >10 queries
Pool: CPU cores x 2 + 1, monitor active/idle/wait
Tracing: request ID -> spans -> slow query identification
```
