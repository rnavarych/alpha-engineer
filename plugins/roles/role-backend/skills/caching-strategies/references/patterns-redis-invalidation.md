# Caching Patterns, Redis Implementation, and Cache Invalidation

## When to load
Load when choosing a caching pattern, implementing Redis data structures, designing key naming conventions, or building cache invalidation logic.

## Caching Patterns

### Cache-Aside (Lazy Loading)
- Application checks cache first; on miss, reads from database and populates cache
- Most common pattern; application controls cache population
- Risk: cache misses cause latency spikes (database read + cache write)
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

## Redis — Data Structure Selection

- **String**: Simple key-value caching, counters, rate limiters
- **Hash**: Object caching (user profiles, settings), partial updates
- **Sorted Set**: Leaderboards, time-based expiration queues, priority queues
- **List**: Recent items, activity feeds, simple queues
- **Set**: Unique collections, tag systems, intersection/union operations
- **Stream**: Event logs, message queues with consumer groups

## Redis — Connection Management

- Use connection pooling (ioredis pool, redis-py ConnectionPool)
- Configure `maxRetriesPerRequest` and connection timeout
- Implement reconnection logic with exponential backoff
- Use Redis Cluster for horizontal scaling (16,384 hash slots)
- Use Redis Sentinel for high availability with automatic failover

## Key Naming Convention

- Use colons as separators: `service:entity:id:field`
- Examples: `users:123:profile`, `orders:456:items`, `sessions:abc-def`
- Prefix with service name in shared Redis instances
- Keep keys short but descriptive (memory matters at scale)

## Cache Invalidation

### Strategies
- **TTL-based**: Set expiration on every cached entry; simplest approach
- **Event-driven**: Invalidate on write/update events (pub/sub, CDC)
- **Version-based**: Include a version number in the cache key; increment on change
- **Tag-based**: Associate cache entries with tags; invalidate all entries for a tag

### TTL Design
- Hot data: 1-5 minutes (user sessions, rate limits)
- Warm data: 5-60 minutes (product listings, search results)
- Cold data: 1-24 hours (configuration, reference data)
- Add jitter to TTLs to prevent synchronized expiration (thundering herd)
