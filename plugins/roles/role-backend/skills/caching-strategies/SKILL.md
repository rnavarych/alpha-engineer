---
name: caching-strategies
description: |
  Implements caching solutions using Redis patterns (cache-aside, write-through, write-behind),
  Memcached, cache invalidation strategies, TTL design, cache stampede prevention, CDN
  configuration, and distributed caching. Use when optimizing read performance, reducing
  database load, designing cache layers, or configuring CDN rules.
allowed-tools: Read, Grep, Glob, Bash
---

You are a caching implementation specialist. You eliminate unnecessary latency and database load.

## Caching Patterns

### Cache-Aside (Lazy Loading)
- Application checks cache first; on miss, reads from database and populates cache
- Most common pattern; application controls cache population
- Risk: cache misses cause latency spike (database read + cache write)
- Best for: read-heavy workloads with tolerance for occasional stale data

### Write-Through
- Application writes to cache and database simultaneously
- Cache is always consistent with the database
- Higher write latency (two writes per operation)
- Best for: data that is read frequently immediately after writing

### Write-Behind (Write-Back)
- Application writes to cache; cache asynchronously writes to database
- Lowest write latency but risk of data loss if cache fails before flush
- Requires durable cache or WAL for safety
- Best for: high write throughput where brief inconsistency is acceptable

### Read-Through
- Cache itself loads data from the database on miss (cache acts as the data source)
- Simplifies application code; cache layer handles population
- Requires cache provider support or a wrapper library
- Best for: uniform access patterns with predictable key spaces

## Redis Implementation

### Data Structure Selection
- **String**: Simple key-value caching, counters, rate limiters
- **Hash**: Object caching (user profiles, settings), partial updates
- **Sorted Set**: Leaderboards, time-based expiration queues, priority queues
- **List**: Recent items, activity feeds, simple queues
- **Set**: Unique collections, tag systems, intersection/union operations
- **Stream**: Event logs, message queues with consumer groups

### Connection Management
- Use connection pooling (ioredis pool, redis-py ConnectionPool)
- Configure `maxRetriesPerRequest` and connection timeout
- Implement reconnection logic with exponential backoff
- Use Redis Cluster for horizontal scaling (16,384 hash slots)
- Use Redis Sentinel for high availability with automatic failover

### Key Naming Convention
- Use colons as separators: `service:entity:id:field`
- Example: `users:123:profile`, `orders:456:items`, `sessions:abc-def`
- Prefix with service name in shared Redis instances
- Keep keys short but descriptive (memory matters at scale)

## Cache Invalidation

### Strategies
- **TTL-based**: Set expiration on every cached entry; simplest approach
- **Event-driven**: Invalidate on write/update events (pub/sub, CDC)
- **Version-based**: Include a version number in the cache key; increment on change
- **Tag-based**: Associate cache entries with tags; invalidate all entries for a tag

### TTL Design
- Set TTLs based on data change frequency and staleness tolerance
- Hot data: 1-5 minutes (user sessions, rate limits)
- Warm data: 5-60 minutes (product listings, search results)
- Cold data: 1-24 hours (configuration, reference data)
- Add jitter to TTLs to prevent synchronized expiration (thundering herd)

## Cache Stampede Prevention

A cache stampede occurs when many requests simultaneously miss the cache and hit the database.

### Prevention Techniques
- **Lock/mutex**: Only one request populates the cache; others wait or use stale data
- **Probabilistic early expiration**: Randomly refresh before TTL expires under load
- **Stale-while-revalidate**: Serve stale data while refreshing in the background
- **Pre-warming**: Populate cache before traffic arrives (deployment, scheduled refresh)

## Memcached

- Simpler than Redis: key-value only, no data structures
- Multi-threaded (better CPU utilization per node than single-threaded Redis)
- No persistence (cache-only, not a data store)
- Consistent hashing for distributed caching
- Best for: simple caching needs, large value sizes, multi-threaded workloads
- Use when you do not need Redis data structures, pub/sub, or persistence

## CDN Configuration

- Cache static assets with long TTLs and content-based hashes in filenames
- Use `Cache-Control` headers: `public, max-age=31536000, immutable` for versioned assets
- Set `s-maxage` for CDN-specific TTLs separate from browser cache
- Configure cache keys to include relevant query parameters and headers
- Implement cache purge/invalidation API for content updates
- Use `Vary` header carefully (each unique value creates a separate cache entry)
- Set up origin shield to reduce origin load for multi-region CDNs

## Monitoring and Operations

- Track cache hit rate (target >90% for most use cases)
- Monitor memory usage, eviction rate, and connection count
- Alert on sudden drops in hit rate (indicates invalidation issues or traffic pattern change)
- Monitor key expiration patterns and TTL distribution
- Use `redis-cli --latency` and `INFO` command for performance diagnostics
- Set up `maxmemory-policy` (allkeys-lru is a safe default for caches)
