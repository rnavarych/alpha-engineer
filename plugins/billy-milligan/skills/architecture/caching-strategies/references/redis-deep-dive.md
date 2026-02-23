# Redis Deep Dive

## When to load
Load when discussing Redis data structures for caching, eviction policies, cluster mode, or Lua scripting for atomic operations.

## Patterns

### Data structures for caching
```bash
# String - simple key-value (most common)
SET user:123 '{"name":"Alice"}' EX 300

# Hash - partial updates without full serialization
HSET user:123 name "Alice" email "alice@example.com"
HGET user:123 name
EXPIRE user:123 300

# Sorted Set - leaderboards, rate limiting windows
ZADD rate:ip:10.0.0.1 1708700000 "req1"
ZRANGEBYSCORE rate:ip:10.0.0.1 1708699940 +inf  # last 60s
ZREMRANGEBYSCORE rate:ip:10.0.0.1 -inf 1708699940  # cleanup

# HyperLogLog - cardinality estimation (12KB per key)
PFADD unique:visitors:2024-02-23 "user123" "user456"
PFCOUNT unique:visitors:2024-02-23  # approximate unique count
```

### Eviction policies
| Policy | Use case |
|--------|----------|
| `allkeys-lru` | General cache, evict least recently used (recommended default) |
| `volatile-lru` | Only evict keys with TTL set |
| `allkeys-lfu` | Frequency-based, good for hot/cold data |
| `volatile-ttl` | Evict keys closest to expiration |
| `noeviction` | Return error on OOM (use for queues/sessions) |

Set via: `maxmemory-policy allkeys-lru` and `maxmemory 2gb`

### Cluster mode
```
# 16384 hash slots distributed across nodes
# Minimum 3 masters + 3 replicas for production
# Key routing: CRC16(key) mod 16384

# Force keys to same slot with hash tags
SET {user:123}:profile '...'
SET {user:123}:prefs '...'
# Both route to slot for "user:123"
```
Cross-slot operations (MGET across slots) fail in cluster mode. Use hash tags or pipeline per slot.

### Lua scripting for atomic operations
```lua
-- Rate limiter: sliding window (atomic)
local key = KEYS[1]
local window = tonumber(ARGV[1])  -- 60 seconds
local limit = tonumber(ARGV[2])   -- 100 requests
local now = tonumber(ARGV[3])

redis.call('ZREMRANGEBYSCORE', key, 0, now - window)
local count = redis.call('ZCARD', key)
if count < limit then
  redis.call('ZADD', key, now, now .. ':' .. math.random())
  redis.call('EXPIRE', key, window)
  return 1  -- allowed
end
return 0  -- rate limited
```
```typescript
// Execute Lua script via ioredis
const result = await redis.call('EVALSHA', scriptSha, 1, rateLimitKey, 60, 100, Date.now());
```

### Connection pooling
```typescript
import Redis from 'ioredis';

const redis = new Redis({
  host: process.env.REDIS_HOST,
  port: 6379,
  maxRetriesPerRequest: 3,
  retryStrategy: (times) => Math.min(times * 100, 3000),
  lazyConnect: true,
  enableReadyCheck: true,
});
```

## Anti-patterns
- Storing objects >1MB in Redis -> use S3 + Redis as pointer
- No maxmemory set -> Redis uses all RAM, OOM killer strikes
- Using KEYS in production -> O(N) scan blocks single-threaded Redis; use SCAN instead
- No TTL on cache keys -> unbounded memory growth

## Decision criteria
- **String vs Hash**: string for full-object reads; hash when updating individual fields
- **LRU vs LFU**: LRU for recency-based access; LFU for frequency-based (popular items stay)
- **Single vs Cluster**: single node handles ~100k ops/sec; cluster for >100k or >25GB dataset

## Quick reference
```
Max recommended value size: 512KB (ideal <10KB)
Single node throughput: ~100k ops/sec
Cluster minimum: 3 masters + 3 replicas
Lua script max execution: 5s default (BUSY error after)
Pipeline: batch 50-100 commands per round trip
Memory overhead: ~90 bytes per key + value size
```
