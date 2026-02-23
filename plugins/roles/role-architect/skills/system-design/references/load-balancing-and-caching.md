# Load Balancing and Caching Architectures

## When to load
Load when designing traffic distribution strategies, selecting load balancing algorithms, architecting multi-layer caching, or solving cache stampede and hot-key problems.

## Load Balancing Algorithms

### Round-Robin
- Distribute requests sequentially across all healthy backends. Backend 1, 2, 3, 1, 2, 3...
- Best for: homogeneous backends with similar request costs and similar capacity.
- Limitation: does not account for request weight or backend load. A slow request can cause queue buildup on one backend while others are idle.
- **Weighted Round-Robin**: Assign weights to backends based on capacity. A backend with weight 3 receives 3x the traffic of a backend with weight 1. Use for heterogeneous instance types.

### Least Connections
- Route each new request to the backend with the fewest active connections.
- Best for: long-lived connections (WebSockets, gRPC streams, database connections) where request duration varies significantly.
- Limitation: does not account for request weight (a cheap request and an expensive request both count as 1 connection).
- **Least Response Time**: Combine least connections with lowest average response time. More accurate but requires tracking response times. Used by Nginx Plus, HAProxy.

### Consistent Hashing
- Map both requests and backends onto a ring (by hashing). Route each request to the first backend clockwise from the request's hash position.
- Key property: when a backend is added or removed, only K/n keys are remapped (K = number of keys, n = number of backends). Traditional hashing remaps almost all keys on topology changes.
- **Virtual nodes**: Each physical backend is represented by multiple positions on the ring (virtual nodes). Improves distribution uniformity. Cassandra uses 256 virtual nodes per physical node.
- Use for: distributed caches (Memcached, Redis Cluster), object storage routing, and any stateful routing where session affinity or data locality matters.

### Maglev Hashing
- Google's consistent hashing algorithm used in their load balancers (GFE). Produces a lookup table that maps connection 5-tuples to backends.
- Key property: minimal disruption on backend changes (near-minimal movement compared to Rendezvous hashing). Near-perfect load distribution.
- Faster than ring-based consistent hashing for lookup (O(1) table lookup vs. O(log n) ring traversal).
- Use for: high-throughput Layer 4 load balancers where lookup performance matters.

### Random with Power of Two Choices
- For each request, randomly select 2 backends, then route to the less loaded one.
- Achieves near-optimal load distribution with O(1) lookup. Significantly better than pure random.
- Reduces max load on any backend from O(log n / log log n) to O(log log n) compared to random.

## Caching Architectures

### Cache-Aside (Lazy Loading)
- Application checks cache first. On miss: read from database, populate cache, return result.
- Cache contains only requested data. Resilient to cache failure (falls back to database).
- Risk: cache stampede on cold start. Mitigate with mutex locks or probabilistic early expiration.

### Write-Through
- On every write, update both the cache and the database synchronously before returning success.
- Guarantees cache-database consistency. Cache is always warm.
- Adds write latency. Cache may hold data that is never read (write-heavy, read-light patterns waste cache space).

### Write-Behind (Write-Back)
- On write, update cache immediately and acknowledge. Persist to database asynchronously (in the background).
- Reduces write latency significantly. Excellent for write-heavy workloads.
- Risk: data loss if the cache fails before background write completes. Use only when occasional data loss is acceptable or with durable cache (Redis with AOF persistence).

### Read-Through
- Application always reads from cache. On miss, the cache itself fetches from database and populates.
- Transparent to the application — no cache logic in application code.
- Use with: Ehcache, Guava LoadingCache, or any cache library with loader support.

### Multi-Layer Caching
- Layer 1: In-process / L1 cache (Guava, Caffeine, node-lru-cache). Nanosecond latency. Size: MB. Per-instance, no sharing.
- Layer 2: Distributed cache (Redis, Memcached). Microsecond latency. Size: GB-TB. Shared across instances.
- Layer 3: CDN edge cache (CloudFront, Fastly, Cloudflare). Millisecond latency globally. Size: unlimited. Serves static and cacheable dynamic content.
- Layer 4: Database query cache / materialized views. Seconds to build. Amortized over many reads.
- Design cache key hierarchies that align with cache invalidation granularity. Fine-grained keys enable surgical invalidation; coarse-grained keys enable bulk invalidation.

### Distributed Cache Patterns
- **Redis Cluster**: Hash-slot-based sharding across 3-16383 hash slots. Use for shared session state, pub/sub, rate limiting, and distributed locks (Redlock).
- **Memcached**: Simpler, multi-threaded, no persistence. Use for pure caching where data loss on restart is acceptable. Slightly better raw throughput than Redis for simple get/set.
- **Cache Stampede Prevention**: Probabilistic early expiration (recalculate before expiry with probability proportional to time-to-expire). XFetch algorithm. Mutex/singleflight for concurrent cache misses.
- **Hot Key Problem**: A single highly popular key overwhelms a single cache node. Solutions: local in-process cache layer for hot keys, read replicas per hot key, key-level sharding (append a random suffix and merge on read).
