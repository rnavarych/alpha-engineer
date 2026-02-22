---
name: performance-optimization
description: |
  Guides on performance: profiling (CPU, memory, I/O), caching layers (CDN, application, database),
  connection pooling, lazy loading, code splitting, database query optimization, and load balancing.
  Use when diagnosing performance issues, optimizing response times, or designing for scale.
allowed-tools: Read, Grep, Glob, Bash
---

You are a performance optimization specialist informed by the Software Engineer by RN competency matrix. Always measure before and after optimizing. Never optimize without profiling data.

## Performance Optimization Process
1. **Define goals**: Set measurable targets (p99 latency < 200ms, throughput > 5000 RPS, LCP < 2.5s)
2. **Measure baseline**: Establish current performance with profiling and benchmarks under realistic load
3. **Identify bottleneck**: Use profiling tools to find the actual bottleneck (CPU, memory, I/O, network, lock contention). Never guess.
4. **Hypothesize**: Form a specific hypothesis about what change will improve performance and by how much
5. **Optimize**: Implement the fix for the identified bottleneck only
6. **Verify**: Re-run the same measurements. Confirm improvement and check for regressions.
7. **Document**: Record what was changed, why, and the measured impact
8. **Repeat**: Address the next bottleneck. Stop when goals are met.

### Common Anti-Patterns
- Premature optimization without profiling data
- Optimizing code that runs once instead of hot paths
- Micro-benchmarking in isolation (not representative of production)
- Adding caching without understanding invalidation requirements
- Over-indexing databases (write penalty exceeds read benefit)

## Caching Layers

### CDN (Edge Caching)

#### CDN Providers
| Provider | Strengths | Edge Locations | Key Features |
|----------|-----------|----------------|--------------|
| **CloudFront** (AWS) | AWS integration, Lambda@Edge | 450+ | Origin Shield, signed URLs, real-time logs |
| **Fastly** (Varnish-based) | Instant purge (<150ms), VCL, Compute@Edge | 90+ | Real-time logging, edge compute (Wasm) |
| **Cloudflare** | Free tier, Workers, DDoS protection | 310+ | Workers (JS/Wasm edge compute), R2 storage, Cache Rules |
| **Akamai** | Enterprise, largest network | 4000+ | Edge computing, security suite |

#### Cache-Control Headers In Detail
```
# Hashed static assets (fingerprinted filenames like app.a1b2c3.js)
Cache-Control: public, max-age=31536000, immutable

# HTML pages (mutable content)
Cache-Control: public, max-age=0, must-revalidate
# Or with stale-while-revalidate for better UX:
Cache-Control: public, max-age=60, stale-while-revalidate=3600

# API responses (dynamic but cacheable)
Cache-Control: public, max-age=30, s-maxage=60, stale-while-revalidate=300
# s-maxage: CDN-specific max-age (overrides max-age for shared caches)

# Private data (user-specific)
Cache-Control: private, max-age=0, no-store

# Sensitive data (never cache)
Cache-Control: no-store, no-cache, must-revalidate, private

# ETag-based validation (conditional requests)
ETag: "abc123"
# Client sends: If-None-Match: "abc123" -> 304 Not Modified
```

#### stale-while-revalidate Pattern
- Serves stale content immediately while revalidating in the background
- Eliminates cache-miss latency spikes for users
- Pair with `stale-if-error` to serve stale content if origin is down
- Example: `Cache-Control: max-age=60, stale-while-revalidate=3600, stale-if-error=86400`

### Application Caching

#### In-Memory Caches
| Language | Library | Features |
|----------|---------|----------|
| Node.js | `lru-cache` | LRU eviction, TTL, size-based limits, stale-while-revalidate |
| Node.js | `node-cache` | Simple TTL cache, events, stats |
| Python | `cachetools` | LRU, LFU, TTL, RR policies, thread-safe |
| Python | `functools.lru_cache` | Built-in, decorator, maxsize, typed |
| Java | Caffeine | Near-optimal hit rate, async loading, size/time eviction, stats |
| Java | Guava Cache | Loading cache, expiration, weighing, removal listener |
| Go | `groupcache` | Distributed, singleflight (dedup concurrent loads), no expiration |
| Go | `ristretto` | Contention-free, high hit ratio, metrics |
| .NET | `IMemoryCache` | Built-in, size limits, sliding/absolute expiration, post-eviction callbacks |

#### Redis Patterns

```python
# Cache-aside with TTL (Python / redis-py)
import redis, json

r = redis.Redis(host='localhost', port=6379, decode_responses=True)

def get_user(user_id):
    cache_key = f"user:{user_id}"
    cached = r.get(cache_key)
    if cached:
        return json.loads(cached)
    user = db.query("SELECT * FROM users WHERE id = %s", user_id)
    r.setex(cache_key, 3600, json.dumps(user))  # TTL: 1 hour
    return user
```

```lua
-- Redis Lua script for atomic cache-aside with stampede prevention
-- KEYS[1] = cache key, KEYS[2] = lock key
-- ARGV[1] = TTL, ARGV[2] = lock TTL
local cached = redis.call('GET', KEYS[1])
if cached then return cached end

-- Try to acquire lock (only one caller recomputes)
local locked = redis.call('SET', KEYS[2], '1', 'NX', 'EX', ARGV[2])
if locked then
    return nil  -- Signal caller to compute and set
else
    -- Another caller is computing; wait or return stale
    return redis.call('GET', KEYS[1])
end
```

#### Cache Stampede Prevention
- **Locking**: Only one request recomputes; others wait or serve stale
- **Probabilistic early expiration**: Refresh cache before TTL expires with probability that increases as expiry approaches
- **stale-while-revalidate**: Serve stale value immediately, refresh asynchronously
- **Cache warming**: Pre-populate cache on deployment or schedule

### Cache Invalidation Strategies
- **TTL-based**: Simple, eventual consistency. Best for data that changes infrequently.
- **Event-based**: Invalidate on write events (CDC, pub/sub). Near real-time consistency.
- **Version-based**: Cache key includes data version or hash. Instant invalidation via key change.
- **Write-through**: Update cache synchronously on every write. Strong consistency, slower writes.
- **Write-behind**: Update cache immediately, write to DB asynchronously. Fast writes, risk of data loss.
- **Tag-based purge**: Group related cache entries with tags, purge all by tag (CDN-level: Fastly surrogate keys, CloudFront cache policies)

## Database Performance

### EXPLAIN ANALYZE Examples

```sql
-- PostgreSQL: Analyze a slow query
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT o.id, o.total, c.name
FROM orders o
JOIN customers c ON c.id = o.customer_id
WHERE o.created_at > NOW() - INTERVAL '30 days'
  AND o.status = 'completed'
ORDER BY o.created_at DESC
LIMIT 50;

-- Reading the output:
-- Seq Scan: Full table scan (bad for large tables, consider index)
-- Index Scan: Using index (good)
-- Index Only Scan: Covered by index (best)
-- Bitmap Index Scan: Multiple index conditions combined
-- Nested Loop: OK for small inner sets
-- Hash Join: Good for larger joins
-- Sort: Check if index can eliminate sort
-- Buffers: shared hit = from cache, shared read = from disk
```

```sql
-- MySQL: Analyze query plan
EXPLAIN ANALYZE
SELECT o.id, o.total, c.name
FROM orders o
JOIN customers c ON c.id = o.customer_id
WHERE o.created_at > DATE_SUB(NOW(), INTERVAL 30 DAY)
  AND o.status = 'completed'
ORDER BY o.created_at DESC
LIMIT 50;

-- Key indicators:
-- type: ALL (full scan, bad) -> index -> range -> ref -> eq_ref -> const (best)
-- rows: estimated rows examined (lower is better)
-- Extra: Using filesort (may need index), Using temporary (expensive), Using index (covering)
```

### Index Types

| Index Type | Engine | Use Case | Example |
|-----------|--------|----------|---------|
| **B-tree** | PG, MySQL, all | Default. Equality, range, sorting, prefix | `CREATE INDEX idx ON orders(created_at)` |
| **Hash** | PG, MySQL 8.0+ (memory) | Exact equality only. Faster than B-tree for `=` | `CREATE INDEX idx ON users USING hash(email)` |
| **GIN** (Generalized Inverted) | PostgreSQL | Arrays, JSONB, full-text search, tsvector | `CREATE INDEX idx ON docs USING gin(tags)` |
| **GiST** (Generalized Search Tree) | PostgreSQL | Geometric, range types, full-text, PostGIS | `CREATE INDEX idx ON places USING gist(location)` |
| **BRIN** (Block Range) | PostgreSQL | Large sequential data (timestamps, auto-increment) | `CREATE INDEX idx ON logs USING brin(created_at)` |
| **Partial** | PostgreSQL | Index subset of rows (reduces size) | `CREATE INDEX idx ON orders(id) WHERE status='pending'` |
| **Covering** | PG 11+, MySQL 8.0+ | Include non-key columns to avoid table lookup | `CREATE INDEX idx ON orders(status) INCLUDE (total, created_at)` |
| **Composite** | All | Multi-column queries. Left-to-right column order matters. | `CREATE INDEX idx ON orders(customer_id, created_at DESC)` |

### Query Plan Red Flags
- **Sequential scan on large table**: Add appropriate index
- **High rows estimate vs. actual**: Statistics are stale, run `ANALYZE`
- **Nested loop with large inner table**: Consider hash join, add index, or restructure query
- **Sort operation**: Can often be eliminated with index matching ORDER BY
- **High buffer reads vs. hits**: Working set exceeds shared_buffers, consider increasing memory or optimizing query

## Connection Pooling

### PgBouncer Configuration
```ini
[databases]
mydb = host=localhost port=5432 dbname=mydb

[pgbouncer]
listen_port = 6432
listen_addr = 0.0.0.0
auth_type = md5
pool_mode = transaction          ; transaction (recommended), session, statement
default_pool_size = 20           ; connections per user/database pair
min_pool_size = 5                ; pre-create connections
max_client_conn = 1000           ; max client connections
max_db_connections = 50          ; max connections to actual database
server_idle_timeout = 300        ; close idle server connections after 5 min
query_wait_timeout = 120         ; max time client waits for a server connection
```

### HikariCP Tuning (Java)
```yaml
# application.yml
spring:
  datasource:
    hikari:
      maximum-pool-size: 20        # Formula: connections = (core_count * 2) + disk_spindles
      minimum-idle: 5              # Keep 5 connections ready
      connection-timeout: 30000    # 30s to get connection from pool
      idle-timeout: 600000         # 10 min idle before eviction
      max-lifetime: 1800000        # 30 min max connection lifetime
      leak-detection-threshold: 60000  # Warn if connection held > 60s
```

### Pool Sizing Formula
```
# PostgreSQL recommended max connections
optimal_pool_size = (core_count * 2) + effective_spindle_count
# For SSD: effective_spindle_count = 1
# Example: 4-core server with SSD: (4 * 2) + 1 = 9 connections per pool

# If multiple application instances share a database:
max_connections_per_instance = total_db_connections / number_of_instances
# Example: PostgreSQL max_connections=100, 5 app instances = 20 per pool
```

## Application Performance

### Async Patterns by Language

| Language | Pattern | Library/Feature | Use Case |
|----------|---------|-----------------|----------|
| Node.js | Event loop, Promises, async/await | Built-in, `p-limit`, `p-queue` | I/O operations, API calls |
| Node.js | Worker threads | `worker_threads`, `piscina`, `workerpool` | CPU-intensive: image processing, crypto, parsing |
| Python | asyncio | `asyncio`, `aiohttp`, `httpx[async]` | I/O-bound: HTTP, database, file |
| Python | Multiprocessing | `concurrent.futures`, `multiprocessing` | CPU-bound: data processing, ML inference |
| Java | Virtual threads (Project Loom) | `Thread.ofVirtual()` (Java 21+) | High-concurrency I/O (millions of threads) |
| Java | CompletableFuture | `java.util.concurrent` | Async composition, fan-out/fan-in |
| Go | Goroutines + channels | Built-in, `errgroup`, `semaphore` | Concurrent I/O and CPU work |
| .NET | async/await, Task | `Task`, `ValueTask`, `Channel<T>` | I/O-bound work, producer-consumer |

### Streaming Responses
- Reduce time-to-first-byte by streaming data as it becomes available
- Node.js: `ReadableStream`, `pipeline()`, `res.write()` chunks
- Python: FastAPI `StreamingResponse`, Django `StreamingHttpResponse`
- Java: Spring WebFlux `Flux<T>`, `ResponseBodyEmitter`
- Go: `http.Flusher` interface, `io.Pipe()`

## Frontend Performance

### Core Web Vitals Targets and Optimization

| Metric | Good | Needs Improvement | Poor | What It Measures |
|--------|------|-------------------|------|-----------------|
| **LCP** (Largest Contentful Paint) | < 2.5s | 2.5s - 4.0s | > 4.0s | Loading performance (largest visible element) |
| **INP** (Interaction to Next Paint) | < 200ms | 200ms - 500ms | > 500ms | Responsiveness (replaces FID) |
| **CLS** (Cumulative Layout Shift) | < 0.1 | 0.1 - 0.25 | > 0.25 | Visual stability |

#### LCP Optimization
- Preload hero images: `<link rel="preload" as="image" href="hero.webp">`
- Use `fetchpriority="high"` on LCP image
- Serve responsive images: `<img srcset="..." sizes="...">`
- Optimize server response time (TTFB < 800ms)
- Avoid render-blocking CSS/JS (inline critical CSS, defer non-critical)

#### INP Optimization
- Break long tasks (>50ms) into smaller chunks using `requestIdleCallback`, `scheduler.yield()`
- Debounce/throttle event handlers
- Use `requestAnimationFrame` for visual updates
- Minimize main thread work during interactions
- Use Web Workers for heavy computation

#### CLS Optimization
- Always set `width` and `height` on images/video (or use `aspect-ratio`)
- Reserve space for dynamic content (ads, embeds, lazy-loaded images)
- Use `font-display: swap` or `optional` with `<link rel="preload">` for fonts
- Avoid inserting content above existing content

### Image Optimization
| Format | Use Case | Compression | Browser Support |
|--------|----------|-------------|-----------------|
| **WebP** | Photos, illustrations | 25-35% smaller than JPEG | 97%+ browsers |
| **AVIF** | Photos (best compression) | 50% smaller than JPEG | 92%+ browsers |
| **SVG** | Icons, logos, illustrations | Vector (infinite scale) | All browsers |
| **PNG** | Screenshots, transparency | Lossless | All browsers |

```html
<!-- Responsive image with format fallback -->
<picture>
  <source srcset="image.avif" type="image/avif">
  <source srcset="image.webp" type="image/webp">
  <img src="image.jpg" alt="..." width="800" height="600" loading="lazy" decoding="async">
</picture>
```

### Bundle Analysis and Code Splitting
- **Analyze**: `webpack-bundle-analyzer`, `source-map-explorer`, `vite-bundle-visualizer`
- **Route-based splitting**: `React.lazy()` + `Suspense`, Next.js automatic, Vue async components
- **Component-level splitting**: Dynamic `import()` for heavy components (charts, editors, maps)
- **Tree shaking**: ES module imports (`import { specific } from 'lib'`), avoid `import *`
- **Dependency optimization**: Replace heavy libraries (moment.js -> date-fns/dayjs, lodash -> lodash-es or native)

## Network Performance

### Protocol Comparison
| Feature | HTTP/1.1 | HTTP/2 | HTTP/3 (QUIC) |
|---------|----------|--------|---------------|
| **Multiplexing** | No (6 connections per domain) | Yes (single connection) | Yes (no head-of-line blocking) |
| **Header compression** | None | HPACK | QPACK |
| **Server push** | No | Yes (deprecated in practice) | No |
| **Connection setup** | TCP + TLS (2-3 RTT) | TCP + TLS (2-3 RTT) | 0-1 RTT (QUIC) |
| **Best for** | Legacy | Most web traffic | Mobile, lossy networks |

### Compression
- **Brotli** (`br`): 15-25% smaller than gzip. Use for static assets (pre-compressed). Slower compression, faster decompression.
- **gzip**: Universal support. Use for dynamic responses. Level 6 is good default (balance speed vs ratio).
- **zstd**: Emerging. Better ratio than gzip, faster than brotli. RFC 8878.
- Set `Content-Encoding` header, configure at reverse proxy (Nginx, Caddy) or CDN level.

### Connection Optimization
- **DNS prefetch**: `<link rel="dns-prefetch" href="//api.example.com">`
- **Preconnect**: `<link rel="preconnect" href="https://api.example.com">` (DNS + TCP + TLS)
- **HTTP keep-alive**: Reuse TCP connections (default in HTTP/1.1+)
- **Connection pooling**: Reuse connections in backend HTTP clients (`agentkeepalive` for Node.js, `httpx` connection pool for Python)

## Load Balancing

### Algorithms In Depth

| Algorithm | How It Works | Best For | Drawbacks |
|-----------|-------------|----------|-----------|
| **Round Robin** | Rotates through servers sequentially | Homogeneous servers, equal request cost | Ignores server load and capacity |
| **Weighted Round Robin** | Round robin with server weights | Heterogeneous servers (different CPU/RAM) | Static weights, no real-time adaptation |
| **Least Connections** | Routes to server with fewest active connections | Long-lived connections, variable request duration | May send bursts to newly added servers |
| **Least Response Time** | Routes to server with fastest response + fewest connections | Latency-sensitive applications | Requires active health monitoring |
| **IP Hash** | Hash client IP to consistent server | Session persistence without cookies | Uneven distribution, problematic behind NAT |
| **Consistent Hashing** | Hash ring with virtual nodes | Cache servers, stateful services, minimal redistribution on scaling | More complex implementation |
| **Random Two Choices** | Pick 2 random servers, choose least loaded | Simple, surprisingly effective at scale (power of two choices) | Slightly less optimal than least connections |

### Health Checks
- **HTTP health check**: `GET /health` -> 200 OK (check every 10-30s)
- **Deep health check**: `GET /health/ready` -> verifies database, cache, downstream dependencies
- **Liveness vs. readiness**: Liveness = process alive, readiness = able to serve traffic
- **Thresholds**: Mark unhealthy after 3 consecutive failures, healthy after 2 successes

### Circuit Breaker Pattern
```
States: CLOSED -> OPEN -> HALF-OPEN -> CLOSED
- CLOSED: Normal operation, count failures
- OPEN: Fail fast (no requests to downstream), wait timeout (30-60s)
- HALF-OPEN: Allow limited requests, if successful -> CLOSED, if failed -> OPEN

Libraries:
- Node.js: opossum
- Java: Resilience4j, Hystrix (deprecated)
- Go: sony/gobreaker, afex/hystrix-go
- Python: pybreaker
- .NET: Polly
```

### Rate Limiting
- **Token bucket**: Smooth rate, allows bursts up to bucket size. Best for APIs.
- **Sliding window**: Precise rate limiting, no burst allowance. Best for strict limits.
- **Fixed window**: Simple but allows 2x burst at window boundaries.
- **Implementation**: Redis (`INCR` + `EXPIRE`), Nginx (`limit_req`), API Gateway (AWS, Kong, Envoy)

## Auto-Scaling

### Metrics-Based Scaling
- **CPU utilization**: Target 60-70%. Most common. Lagging indicator.
- **Request count**: Requests per target. Good for web services.
- **Queue depth**: Messages in queue. Good for worker services.
- **Custom metrics**: Business-specific (active users, processing jobs)

### Predictive Scaling
- AWS Predictive Scaling: ML-based, learns traffic patterns, pre-scales before anticipated load
- GCP Autoscaler predictive mode: Forecasts based on historical CPU/LB metrics
- Best for: Recurring traffic patterns (daily, weekly)

### Scaling Configuration
```yaml
# Kubernetes HPA example
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-server
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-server
  minReplicas: 3
  maxReplicas: 50
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60    # Wait 60s before scaling up again
      policies:
        - type: Percent
          value: 100                     # Double capacity per scale-up
          periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300   # Wait 5 min before scaling down
      policies:
        - type: Percent
          value: 10                      # Remove 10% per scale-down
          periodSeconds: 60
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 65
    - type: Pods
      pods:
        metric:
          name: http_requests_per_second
        target:
          type: AverageValue
          averageValue: "1000"
```

## Profiling Tools by Language

| Language | CPU Profiler | Memory Profiler | Key Commands |
|----------|-------------|-----------------|--------------|
| Node.js | `clinic flame`, `0x`, `--prof` | `clinic heapprofiler`, `--inspect` (Chrome DevTools) | `node --prof app.js && node --prof-process isolate-*.log` |
| Python | `py-spy`, `cProfile`, `scalene` | `memray`, `memory_profiler`, `tracemalloc` | `py-spy record -o profile.svg -- python app.py` |
| Java | `async-profiler`, JFR, JProfiler | VisualVM, `jmap`, Eclipse MAT | `java -XX:StartFlightRecording=filename=rec.jfr -jar app.jar` |
| Go | `pprof` (built-in), `fgprof` | `pprof` (heap), `runtime.MemStats` | `go tool pprof http://localhost:6060/debug/pprof/profile` |
| .NET | `dotnet-trace`, `dotnet-counters` | `dotnet-dump`, `dotnet-gcdump` | `dotnet-trace collect --process-id <PID>` |
| Rust | `cargo flamegraph`, `perf` | `heaptrack`, `DHAT` (Valgrind) | `cargo flamegraph -- ./target/release/myapp` |

## Benchmarking Tools

| Tool | Type | Language | Best For |
|------|------|----------|----------|
| **k6** | Load testing | JavaScript (Go engine) | HTTP, WebSocket, gRPC, browser. CI/CD integration. Grafana ecosystem. |
| **wrk** | HTTP benchmarking | C + Lua scripting | Simple HTTP benchmarks, low overhead |
| **hey** | HTTP benchmarking | Go | Quick HTTP benchmarks, simple CLI |
| **Locust** | Load testing | Python | Python teams, distributed testing, web UI |
| **Gatling** | Load testing | Scala/Java | JVM teams, detailed reports, CI integration |
| **JMH** | Micro-benchmarking | Java | JVM method-level benchmarks, accurate (handles JIT, warmup) |
| **BenchmarkDotNet** | Micro-benchmarking | .NET | .NET method-level benchmarks, statistical analysis |
| **hyperfine** | CLI benchmarking | Rust | Comparing CLI command performance |

```javascript
// k6 load test example
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 100 },   // Ramp up to 100 VUs
    { duration: '5m', target: 100 },   // Stay at 100 VUs
    { duration: '2m', target: 0 },     // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(99)<500'],   // 99th percentile < 500ms
    http_req_failed: ['rate<0.01'],     // Error rate < 1%
  },
};

export default function () {
  const res = http.get('https://api.example.com/items');
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 200ms': (r) => r.timings.duration < 200,
  });
  sleep(1);
}
```

For detailed strategies, see [reference-strategies.md](reference-strategies.md).
