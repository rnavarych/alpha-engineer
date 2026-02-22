# Performance Optimization Strategies Reference

## Frontend Performance

### Core Web Vitals Optimization Techniques

#### LCP (Largest Contentful Paint) < 2.5s
- **Preload LCP resource**: `<link rel="preload" as="image" href="hero.webp" fetchpriority="high">`
- **Optimize server TTFB**: Target < 800ms. Use CDN, edge caching, server-side caching.
- **Eliminate render-blocking resources**: Inline critical CSS (< 14 KB), defer non-critical JS
- **Responsive images with modern formats**:
```html
<picture>
  <source srcset="hero-400.avif 400w, hero-800.avif 800w, hero-1200.avif 1200w" type="image/avif" sizes="100vw">
  <source srcset="hero-400.webp 400w, hero-800.webp 800w, hero-1200.webp 1200w" type="image/webp" sizes="100vw">
  <img src="hero-800.jpg" alt="Hero" width="1200" height="600" fetchpriority="high" decoding="async">
</picture>
```
- **Font optimization**: `font-display: swap`, preload critical font files, use `size-adjust` for fallback

#### INP (Interaction to Next Paint) < 200ms
- **Break long tasks** (>50ms) into smaller chunks:
```javascript
// Use scheduler.yield() (modern) or setTimeout for task chunking
async function processLargeList(items) {
  for (let i = 0; i < items.length; i++) {
    processItem(items[i]);
    if (i % 100 === 0) {
      await scheduler.yield();  // Yield to browser for rendering/input
    }
  }
}
```
- **Debounce input handlers**: 150-300ms for search, 16ms for scroll/resize (requestAnimationFrame)
- **Use Web Workers** for CPU-intensive operations (parsing, sorting, image processing)
- **Virtualize long lists**: `react-virtualized`, `@tanstack/react-virtual`, native `content-visibility: auto`

#### CLS (Cumulative Layout Shift) < 0.1
- **Set explicit dimensions**: `<img width="800" height="600">` or CSS `aspect-ratio: 16/9`
- **Reserve ad/embed space**: Use `min-height` on containers for dynamic content
- **Font loading**: `font-display: optional` (prevents layout shift entirely) or preload + `font-display: swap`
- **Avoid dynamically injected content** above the viewport fold

### Bundle Size Optimization
```bash
# Webpack bundle analysis
npx webpack-bundle-analyzer stats.json

# Vite bundle analysis
npx vite-bundle-visualizer

# Source map analysis
npx source-map-explorer dist/main.*.js

# Common wins:
# - Replace moment.js (330KB) with date-fns (tree-shakeable) or dayjs (2KB)
# - Replace lodash (71KB) with lodash-es (tree-shakeable) or native methods
# - Dynamic import() for route-level and heavy component code splitting
# - Use production builds (process.env.NODE_ENV === 'production')
# - Enable gzip/brotli compression at CDN/server level
```

### Code Splitting Patterns
```javascript
// React: Route-based splitting with React.lazy
const Dashboard = React.lazy(() => import('./pages/Dashboard'));
const Settings = React.lazy(() => import('./pages/Settings'));

// React: Component-level splitting for heavy features
const ChartComponent = React.lazy(() => import('./components/Chart'));
const RichTextEditor = React.lazy(() => import('./components/Editor'));

// Next.js: Dynamic imports with loading states
import dynamic from 'next/dynamic';
const Map = dynamic(() => import('./Map'), {
  loading: () => <MapSkeleton />,
  ssr: false,  // Client-only (e.g., Leaflet, Mapbox)
});

// Vue: Async components
const HeavyChart = defineAsyncComponent(() => import('./HeavyChart.vue'));
```

## Backend Performance by Language

### Node.js
```javascript
// Cluster mode for multi-core utilization
import cluster from 'node:cluster';
import { availableParallelism } from 'node:os';

if (cluster.isPrimary) {
  const numCPUs = availableParallelism();
  for (let i = 0; i < numCPUs; i++) cluster.fork();
  cluster.on('exit', (worker) => cluster.fork()); // Auto-restart
} else {
  startServer();
}

// Worker threads for CPU-intensive operations
import { Worker } from 'node:worker_threads';
import Piscina from 'piscina';

const pool = new Piscina({ filename: './worker.js', maxThreads: 4 });
const result = await pool.run({ data: heavyData });

// Streaming large responses (avoid buffering entire response)
app.get('/export', async (req, res) => {
  res.setHeader('Content-Type', 'text/csv');
  const cursor = db.query('SELECT * FROM large_table').stream();
  for await (const row of cursor) {
    res.write(formatCsvRow(row));
  }
  res.end();
});

// Limit concurrency for external API calls
import pLimit from 'p-limit';
const limit = pLimit(10);  // Max 10 concurrent requests
const results = await Promise.all(
  urls.map(url => limit(() => fetch(url)))
);
```

### Python
```python
# Async I/O with FastAPI + httpx for concurrent external calls
import httpx
from fastapi import FastAPI

app = FastAPI()

@app.get("/aggregate")
async def aggregate():
    async with httpx.AsyncClient() as client:
        results = await asyncio.gather(
            client.get("https://api1.example.com/data"),
            client.get("https://api2.example.com/data"),
            client.get("https://api3.example.com/data"),
        )
    return {"data": [r.json() for r in results]}

# Multiprocessing for CPU-bound tasks
from concurrent.futures import ProcessPoolExecutor
import multiprocessing

def cpu_intensive_task(data):
    return heavy_computation(data)

with ProcessPoolExecutor(max_workers=multiprocessing.cpu_count()) as executor:
    results = list(executor.map(cpu_intensive_task, data_chunks))

# Cython/NumPy for numerical performance
# Use NumPy vectorized operations instead of Python loops
import numpy as np
# Slow: [x**2 for x in range(1000000)]
# Fast: np.arange(1000000) ** 2

# GIL note: Python 3.13+ has experimental free-threaded mode (--disable-gil)
# Until then, use multiprocessing for CPU-bound, asyncio for I/O-bound
```

### Java
```java
// Virtual threads (Java 21+) for high-concurrency I/O
// Replace thread pools with virtual threads for I/O-bound work
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    List<Future<Response>> futures = urls.stream()
        .map(url -> executor.submit(() -> httpClient.send(
            HttpRequest.newBuilder(URI.create(url)).build(),
            HttpResponse.BodyHandlers.ofString()
        )))
        .toList();
    // Each virtual thread costs ~1KB (vs ~1MB for platform threads)
}

// Spring Boot: Enable virtual threads
// application.properties: spring.threads.virtual.enabled=true

// JVM tuning flags
// -Xms2g -Xmx2g                    # Set heap (min=max to avoid resize)
// -XX:+UseZGC                       # Low-latency GC (sub-ms pauses)
// -XX:+UseG1GC                      # Default, good balance (< 200ms pauses)
// -XX:MaxGCPauseMillis=100          # G1GC target pause time
// -XX:+UseStringDeduplication       # Reduce memory for duplicate strings
// -XX:+UseCompressedOops            # Compress object pointers (< 32GB heap)

// Connection pooling with HikariCP (fastest JDBC pool)
// Formula: pool_size = (cpu_cores * 2) + effective_spindle_count
// For most apps: 10-20 connections is optimal
```

### Go
```go
// Goroutine concurrency with errgroup
import "golang.org/x/sync/errgroup"

func fetchAll(ctx context.Context, urls []string) ([]Response, error) {
    g, ctx := errgroup.WithContext(ctx)
    results := make([]Response, len(urls))

    for i, url := range urls {
        i, url := i, url  // capture loop vars
        g.Go(func() error {
            resp, err := httpClient.Get(url)
            if err != nil { return err }
            results[i] = parseResponse(resp)
            return nil
        })
    }
    return results, g.Wait()
}

// Limit goroutine concurrency with semaphore
sem := make(chan struct{}, 10)  // max 10 concurrent
for _, item := range items {
    sem <- struct{}{}  // acquire
    go func(item Item) {
        defer func() { <-sem }()  // release
        process(item)
    }(item)
}

// sync.Pool for reducing GC pressure on hot-path allocations
var bufPool = sync.Pool{
    New: func() any { return new(bytes.Buffer) },
}
buf := bufPool.Get().(*bytes.Buffer)
buf.Reset()
defer bufPool.Put(buf)

// GOGC tuning: GOGC=200 (less frequent GC, more memory)
// GOMEMLIMIT: Set soft memory limit (Go 1.19+)
```

### .NET
```csharp
// Async/await with proper cancellation
public async Task<IActionResult> GetDataAsync(CancellationToken ct)
{
    var task1 = _httpClient.GetAsync("https://api1.example.com", ct);
    var task2 = _httpClient.GetAsync("https://api2.example.com", ct);
    await Task.WhenAll(task1, task2);
    return Ok(new { Data1 = task1.Result, Data2 = task2.Result });
}

// Use ValueTask for hot paths that often complete synchronously
public ValueTask<CacheItem> GetCachedAsync(string key)
{
    if (_cache.TryGetValue(key, out var item))
        return ValueTask.FromResult(item);  // No allocation
    return new ValueTask<CacheItem>(LoadFromDbAsync(key));
}

// Channel<T> for producer-consumer (high-perf bounded queue)
var channel = Channel.CreateBounded<WorkItem>(new BoundedChannelOptions(1000)
{
    FullMode = BoundedChannelFullMode.Wait,
    SingleReader = true,
});

// Object pooling with ObjectPool<T>
var pool = new DefaultObjectPool<StringBuilder>(
    new StringBuilderPooledObjectPolicy { MaximumRetainedCapacity = 4096 });
var sb = pool.Get();
try { /* use sb */ }
finally { pool.Return(sb); }

// .NET GC modes:
// Server GC: Higher throughput, more memory (default for ASP.NET Core)
// Workstation GC: Lower latency, less memory
// <GarbageCollectionSettings> in .csproj or runtimeconfig.json
```

## Database Optimization with EXPLAIN Examples

### PostgreSQL
```sql
-- Before optimization: Sequential scan, 2.3 seconds
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE customer_id = 42 AND created_at > '2025-01-01';
-- Seq Scan on orders  (rows=50000)  actual time=0.01..2300.00
-- Buffers: shared read=125000

-- Add composite index matching query pattern
CREATE INDEX idx_orders_customer_date ON orders(customer_id, created_at DESC);

-- After optimization: Index scan, 2ms
-- Index Scan using idx_orders_customer_date  (rows=150)  actual time=0.02..1.80
-- Buffers: shared hit=12

-- Covering index to avoid table lookup
CREATE INDEX idx_orders_cover ON orders(customer_id, created_at DESC)
  INCLUDE (total, status);

-- Partial index for common filter
CREATE INDEX idx_orders_pending ON orders(created_at DESC)
  WHERE status = 'pending';

-- Index for JSONB queries
CREATE INDEX idx_metadata_gin ON orders USING gin(metadata jsonb_path_ops);
-- Supports: metadata @> '{"priority": "high"}'

-- Update statistics for accurate query plans
ANALYZE orders;
```

### MySQL
```sql
-- Check index usage and query performance
EXPLAIN FORMAT=TREE
SELECT o.id, o.total, c.name
FROM orders o
FORCE INDEX (idx_customer_date)
JOIN customers c ON c.id = o.customer_id
WHERE o.customer_id = 42
  AND o.created_at > '2025-01-01'
ORDER BY o.created_at DESC
LIMIT 20;

-- Show index statistics
SELECT * FROM sys.schema_index_statistics
WHERE table_name = 'orders'
ORDER BY rows_selected DESC;

-- Find slow queries
SELECT * FROM sys.statements_with_runtimes_in_95th_percentile
ORDER BY avg_latency DESC LIMIT 10;

-- Unused indexes (candidates for removal)
SELECT * FROM sys.schema_unused_indexes;
```

## Profiling Tools with Usage Examples

### Node.js Profiling
```bash
# CPU flame graph with 0x
npx 0x app.js
# Opens flame graph in browser after Ctrl+C

# Clinic.js suite (flame, doctor, bubbleprof)
npx clinic flame -- node app.js
# Generates flame graph HTML report

# Built-in V8 profiler
node --prof app.js
# Generate human-readable output:
node --prof-process isolate-0x*.log > profile.txt

# Heap snapshot for memory leaks
node --inspect app.js
# Open chrome://inspect -> Memory tab -> Take heap snapshot
# Compare snapshots to find growing objects
```

### Python Profiling
```bash
# py-spy: Sampling profiler (no code changes, attach to running process)
py-spy record -o profile.svg --pid 12345
py-spy record -o profile.svg -- python app.py
py-spy top --pid 12345  # Live top-like view

# Scalene: CPU + memory + GPU profiler
pip install scalene
scalene app.py  # Generates HTML report with line-level CPU/memory

# memray: Memory profiler (tracks every allocation)
pip install memray
memray run app.py
memray flamegraph memray-app.bin -o flamegraph.html
memray summary memray-app.bin  # Top allocators

# cProfile with snakeviz visualization
python -m cProfile -o profile.prof app.py
snakeviz profile.prof  # Interactive sunburst visualization
```

### Java Profiling
```bash
# Java Flight Recorder (built-in, production-safe)
java -XX:StartFlightRecording=duration=60s,filename=recording.jfr -jar app.jar
# Analyze with JDK Mission Control (jmc)

# async-profiler (low-overhead, flame graphs)
./asprof -d 30 -f profile.html <pid>
# Supports: cpu, alloc, lock, wall-clock profiling
# Output: flame graph HTML, JFR format, collapsed stacks

# GC analysis
java -Xlog:gc*:file=gc.log:time,level,tags -jar app.jar
# Analyze with GCViewer or gceasy.io
```

### Go Profiling
```bash
# Built-in pprof (add to any Go HTTP server)
import _ "net/http/pprof"  # Registers /debug/pprof/ endpoints

# CPU profile (30-second capture)
go tool pprof http://localhost:6060/debug/pprof/profile?seconds=30

# Heap profile (memory allocations)
go tool pprof http://localhost:6060/debug/pprof/heap

# Interactive pprof commands:
# (pprof) top 20           # Top 20 functions by CPU/memory
# (pprof) web              # Open graph in browser
# (pprof) list funcName    # Line-level annotation
# (pprof) flamegraph       # Open flame graph (Go 1.22+)

# Benchmark testing
go test -bench=. -benchmem -cpuprofile=cpu.prof -memprofile=mem.prof
go tool pprof -http=:8080 cpu.prof  # Interactive web UI
```

## Caching Pattern Code Examples

### Cache-Aside (Lazy Loading)
```javascript
// Node.js with ioredis
const Redis = require('ioredis');
const redis = new Redis();

async function getUser(userId) {
  const cacheKey = `user:${userId}`;

  // 1. Check cache
  const cached = await redis.get(cacheKey);
  if (cached) return JSON.parse(cached);

  // 2. Cache miss: query database
  const user = await db.query('SELECT * FROM users WHERE id = $1', [userId]);

  // 3. Populate cache with TTL
  await redis.setex(cacheKey, 3600, JSON.stringify(user));

  return user;
}

// Invalidation on write
async function updateUser(userId, data) {
  await db.query('UPDATE users SET name = $1 WHERE id = $2', [data.name, userId]);
  await redis.del(`user:${userId}`);  // Delete cache entry
}
```

### Write-Through Cache
```python
# Python with redis-py
import redis
import json

r = redis.Redis()

def save_product(product_id, product_data):
    # Write to both cache and database atomically
    db.execute("INSERT INTO products (id, data) VALUES (%s, %s) ON CONFLICT (id) DO UPDATE SET data = %s",
               (product_id, json.dumps(product_data), json.dumps(product_data)))
    r.setex(f"product:{product_id}", 7200, json.dumps(product_data))
```

### Cache Stampede Prevention (Probabilistic Early Expiration)
```go
// Go implementation of XFetch algorithm
func xfetch(key string, ttl time.Duration, recompute func() (string, error)) (string, error) {
    val, expiry, delta, err := cache.GetWithMeta(key)
    if err == nil {
        // Probabilistic early recomputation
        // As expiry approaches, probability of recompute increases
        now := time.Now().Unix()
        if float64(now)-delta*math.Log(rand.Float64()) < float64(expiry) {
            return val, nil  // Use cached value
        }
    }
    // Recompute value
    newVal, err := recompute()
    if err != nil { return "", err }
    cache.Set(key, newVal, ttl)
    return newVal, nil
}
```

## Load Testing Tool Comparison

| Feature | k6 | Locust | Gatling | wrk | Artillery |
|---------|-----|--------|---------|-----|-----------|
| **Language** | JavaScript | Python | Scala/Java | C + Lua | YAML + JS |
| **Protocol** | HTTP, WS, gRPC, browser | HTTP, custom | HTTP, WS, MQTT | HTTP only | HTTP, WS, Socket.io |
| **Distributed** | k6 Cloud, k6-operator (K8s) | Built-in (workers) | Enterprise | No | Artillery Cloud |
| **Scripting** | Full JS (ES6+) | Full Python | Scala DSL | Lua | YAML + JS hooks |
| **Metrics output** | JSON, CSV, Prometheus, Grafana Cloud | Web UI, CSV | HTML reports | stdout | JSON, Datadog, CloudWatch |
| **CI/CD** | Excellent (thresholds, exit codes) | Good | Good | Basic | Good |
| **Resource usage** | Low (Go engine) | Medium (Python) | Medium (JVM) | Very low | Low (Node.js) |
| **Best for** | DevOps teams, Grafana users | Python teams, custom protocols | JVM teams, enterprise | Quick HTTP benchmarks | Serverless, quick tests |

## Auto-Scaling Configuration Examples

### AWS Auto Scaling (Target Tracking)
```json
{
  "TargetTrackingScalingPolicyConfiguration": {
    "TargetValue": 65.0,
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ASGAverageCPUUtilization"
    },
    "ScaleInCooldown": 300,
    "ScaleOutCooldown": 60,
    "DisableScaleIn": false
  }
}
```

### GCP Managed Instance Group Autoscaler
```yaml
# Terraform: GCP autoscaler
resource "google_compute_autoscaler" "api" {
  name   = "api-autoscaler"
  target = google_compute_instance_group_manager.api.id

  autoscaling_policy {
    max_replicas    = 20
    min_replicas    = 3
    cooldown_period = 60

    cpu_utilization {
      target = 0.65
    }

    scaling_schedules {
      name                  = "business-hours"
      min_required_replicas = 5
      schedule              = "0 8 * * MON-FRI"
      duration_sec          = 36000  # 10 hours
      time_zone             = "America/New_York"
    }
  }
}
```

### Kubernetes KEDA (Event-Driven Autoscaling)
```yaml
# Scale based on queue depth (RabbitMQ example)
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: order-processor
spec:
  scaleTargetRef:
    name: order-processor
  pollingInterval: 15
  cooldownPeriod: 60
  minReplicaCount: 1
  maxReplicaCount: 50
  triggers:
    - type: rabbitmq
      metadata:
        queueName: orders
        host: amqp://rabbitmq.default.svc.cluster.local
        queueLength: "10"  # 1 pod per 10 messages
    - type: prometheus
      metadata:
        serverAddress: http://prometheus:9090
        metricName: http_requests_per_second
        threshold: "500"
        query: sum(rate(http_requests_total{service="order-processor"}[1m]))
```

## Memory Optimization Patterns

### Identify Memory Leaks
- **Node.js**: Heap snapshots via `--inspect` + Chrome DevTools. Compare 3 snapshots over time. Look for growing retained size.
- **Python**: `tracemalloc.start()` + `tracemalloc.take_snapshot()`. Compare snapshots with `compare_to()`.
- **Java**: `jmap -dump:live,format=b,file=heap.hprof <pid>`. Analyze with Eclipse MAT or VisualVM.
- **Go**: `go tool pprof http://localhost:6060/debug/pprof/heap`. Look at `inuse_space` vs `alloc_space`.

### Common Memory Leak Sources
- Event listeners not removed (Node.js, browser)
- Unbounded caches without eviction (all languages)
- Closures capturing large objects (JavaScript, Python)
- Static collections growing indefinitely (Java, .NET)
- Goroutine leaks from missing context cancellation (Go)
- String interning/concatenation in hot paths (Java, .NET)

### Object Pooling
```java
// Java: Apache Commons Pool 2
GenericObjectPool<ExpensiveObject> pool = new GenericObjectPool<>(
    new BasePooledObjectFactory<>() {
        @Override
        public ExpensiveObject create() { return new ExpensiveObject(); }
        @Override
        public PooledObject<ExpensiveObject> wrap(ExpensiveObject obj) {
            return new DefaultPooledObject<>(obj);
        }
    }
);
pool.setMaxTotal(20);
pool.setMaxIdle(10);
pool.setMinIdle(2);

ExpensiveObject obj = pool.borrowObject();
try { /* use obj */ }
finally { pool.returnObject(obj); }
```

### GC Tuning Guidelines
| Runtime | Default GC | Low-Latency GC | Tuning Flags |
|---------|-----------|----------------|--------------|
| Java 21+ | G1GC | ZGC (`-XX:+UseZGC`) | `-Xms` = `-Xmx`, `-XX:MaxGCPauseMillis` |
| Go 1.19+ | Concurrent mark-sweep | N/A (already low-pause) | `GOGC=100` (default), `GOMEMLIMIT` |
| .NET 8+ | Server GC | DATAS (`<GarbageCollectionAdaptationMode>1</GarbageCollectionAdaptationMode>`) | `ServerGarbageCollection`, `ConcurrentGarbageCollection` |
| Node.js | V8 Orinoco (generational) | N/A | `--max-old-space-size=4096`, `--optimize-for-size` |
