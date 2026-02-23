# Cache Stampede Prevention, CDN, Memcached, and Monitoring

## When to load
Load when preventing thundering herd / cache stampede, configuring CDN cache headers, evaluating Memcached vs Redis, or setting up cache observability.

## Cache Stampede Prevention

A cache stampede occurs when many requests simultaneously miss the cache and hammer the database.

### Prevention Techniques

- **Lock/mutex**: Only one request populates the cache; others wait or serve stale data
- **Probabilistic early expiration**: Randomly refresh before TTL expires under load
- **Stale-while-revalidate**: Serve stale data while refreshing in the background
- **Pre-warming**: Populate cache before traffic arrives (deployment hooks, scheduled refresh)

### Mutex Pattern (Node.js)

```typescript
async function getWithLock<T>(key: string, fetch: () => Promise<T>, ttl: number): Promise<T> {
  const cached = await redis.get(key)
  if (cached) return JSON.parse(cached)

  const lockKey = `lock:${key}`
  const acquired = await redis.set(lockKey, '1', 'NX', 'PX', 5000)

  if (!acquired) {
    // Another process is populating — wait briefly and retry
    await new Promise(r => setTimeout(r, 100))
    return getWithLock(key, fetch, ttl)
  }

  try {
    const value = await fetch()
    await redis.setex(key, ttl, JSON.stringify(value))
    return value
  } finally {
    await redis.del(lockKey)
  }
}
```

### Stale-While-Revalidate Pattern

```typescript
async function getStale<T>(key: string, fetch: () => Promise<T>, ttl: number, staleTtl: number): Promise<T> {
  const staleKey = `stale:${key}`
  const cached = await redis.get(key)

  if (cached) return JSON.parse(cached)

  const stale = await redis.get(staleKey)
  if (stale) {
    // Return stale immediately, refresh in background
    fetch().then(v => {
      redis.setex(key, ttl, JSON.stringify(v))
      redis.setex(staleKey, staleTtl, JSON.stringify(v))
    })
    return JSON.parse(stale)
  }

  const value = await fetch()
  await Promise.all([
    redis.setex(key, ttl, JSON.stringify(value)),
    redis.setex(staleKey, staleTtl, JSON.stringify(value)),
  ])
  return value
}
```

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
- Use `Vary` header carefully — each unique value creates a separate cache entry
- Set up origin shield to reduce origin load for multi-region CDNs

## Monitoring and Operations

- Track cache hit rate (target >90% for most use cases)
- Monitor memory usage, eviction rate, and connection count
- Alert on sudden drops in hit rate (indicates invalidation issues or traffic pattern change)
- Monitor key expiration patterns and TTL distribution
- Use `redis-cli --latency` and `INFO` command for performance diagnostics
- Set `maxmemory-policy allkeys-lru` as safe default for caches
