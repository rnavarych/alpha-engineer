# Caching Patterns

## When to load
Load when discussing cache-aside, write-through, write-behind, or multi-level caching strategies.

## Patterns

### Cache-aside with jitter (most common)
```typescript
async function getUser(userId: string, cache: Redis, db: Database): Promise<User> {
  const cached = await cache.get(`user:${userId}`);
  if (cached) return JSON.parse(cached);

  const user = await db.query('SELECT * FROM users WHERE id = $1', [userId]);
  const baseTTL = 300; // 5 minutes
  const jitter = Math.floor(Math.random() * 60); // 0-60s jitter
  await cache.set(`user:${userId}`, JSON.stringify(user), 'EX', baseTTL + jitter);
  return user;
}
```
Jitter prevents thundering herd when many keys expire at the same time.

### Write-through (strong consistency)
```typescript
async function updateUser(userId: string, data: Partial<User>, cache: Redis, db: Database) {
  const user = await db.query(
    'UPDATE users SET name=$1, email=$2 WHERE id=$3 RETURNING *',
    [data.name, data.email, userId]
  );
  await cache.set(`user:${userId}`, JSON.stringify(user), 'EX', 300);
  return user;
}
```
Write hits both DB and cache. Higher write latency but reads are always fresh.

### Write-behind (async write, lower latency)
```typescript
async function updateUserAsync(userId: string, data: Partial<User>, cache: Redis, queue: Queue) {
  await cache.set(`user:${userId}`, JSON.stringify(data), 'EX', 300);
  await queue.add('db-sync', { table: 'users', id: userId, data });
  // Worker persists to DB asynchronously
}
```
Risk: data loss if cache fails before DB write. Use only for non-critical data.

### Multi-level caching (L1/L2/L3)
```typescript
import { LRUCache } from 'lru-cache';

const l1 = new LRUCache<string, User>({ max: 1000, ttl: 30_000 }); // 30s in-process
const l2Redis = redis; // 5min in Redis
// L3 = CDN for public data

async function getWithMultiLevel(key: string): Promise<User | null> {
  const l1Hit = l1.get(key);
  if (l1Hit) return l1Hit; // ~0.01ms

  const l2Hit = await l2Redis.get(key);
  if (l2Hit) {
    const parsed = JSON.parse(l2Hit);
    l1.set(key, parsed); // Backfill L1
    return parsed; // ~1ms
  }

  return null; // Cache miss - fetch from DB (~5-50ms)
}
```

## Anti-patterns
- No jitter on TTL -> cache stampede when keys expire together
- Write-behind for financial data -> data loss risk on cache failure
- L1 cache without size limit -> memory leak, OOM in production
- Caching errors/null -> "negative caching" persists failures for TTL duration

## Decision criteria
- **Cache-aside**: default choice, simple, works for read-heavy workloads
- **Write-through**: need strong consistency, can tolerate higher write latency
- **Write-behind**: high write throughput, can tolerate eventual consistency and rare data loss
- **Multi-level**: high read throughput (>10k RPM), latency-sensitive, willing to manage complexity

## Quick reference
```
Cache-aside: read -> cache miss -> DB -> fill cache (most common)
Write-through: write -> DB + cache simultaneously
Write-behind: write -> cache -> async queue -> DB
L1 in-process: ~0.01ms, 1k items max, 30s TTL
L2 Redis: ~1ms, unlimited, 5min TTL
L3 CDN: ~10ms, public data only, 1hr+ TTL
Always add jitter: baseTTL + random(0, baseTTL * 0.2)
```
