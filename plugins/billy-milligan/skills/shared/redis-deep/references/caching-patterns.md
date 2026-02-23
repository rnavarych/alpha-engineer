# Redis Caching Patterns

## When to load
Load when implementing cache layers, cache invalidation, or cache-aside patterns.

## Cache-Aside (Lazy Loading)

```typescript
async function getUser(userId: string): Promise<User> {
  const cacheKey = `user:${userId}`;

  // 1. Check cache
  const cached = await redis.get(cacheKey);
  if (cached) return JSON.parse(cached);

  // 2. Cache miss — load from DB
  const user = await db.users.findById(userId);
  if (!user) return null;

  // 3. Populate cache with TTL
  await redis.set(cacheKey, JSON.stringify(user), 'EX', 3600);

  return user;
}

// Invalidation: delete on write
async function updateUser(userId: string, data: Partial<User>) {
  await db.users.update(userId, data);
  await redis.del(`user:${userId}`);  // invalidate cache
}
```

## Write-Through

```typescript
async function updateUser(userId: string, data: Partial<User>) {
  // Write to DB
  const user = await db.users.update(userId, data);

  // Write to cache synchronously
  await redis.set(`user:${userId}`, JSON.stringify(user), 'EX', 3600);

  return user;
}
// Pro: cache always consistent
// Con: write latency increased
```

## Write-Behind (Write-Back)

```typescript
async function updateUserFast(userId: string, data: Partial<User>) {
  // Write to cache immediately
  await redis.set(`user:${userId}`, JSON.stringify(data), 'EX', 3600);

  // Queue async DB write
  await redis.lpush('db:write:queue', JSON.stringify({
    table: 'users', id: userId, data, timestamp: Date.now()
  }));
}

// Background worker processes queue
async function processWriteQueue() {
  while (true) {
    const item = await redis.brpop('db:write:queue', 5);
    if (item) {
      const { table, id, data } = JSON.parse(item[1]);
      await db[table].update(id, data);
    }
  }
}
// Pro: fast writes
// Con: data loss risk on crash, eventual consistency
```

## Cache Stampede Prevention

```typescript
// Problem: cache expires, 100 requests hit DB simultaneously

// Solution 1: Mutex lock
async function getUserWithLock(userId: string): Promise<User> {
  const cacheKey = `user:${userId}`;
  const lockKey = `lock:${cacheKey}`;

  const cached = await redis.get(cacheKey);
  if (cached) return JSON.parse(cached);

  // Try to acquire lock
  const acquired = await redis.set(lockKey, '1', 'NX', 'EX', 10);
  if (acquired) {
    try {
      const user = await db.users.findById(userId);
      await redis.set(cacheKey, JSON.stringify(user), 'EX', 3600);
      return user;
    } finally {
      await redis.del(lockKey);
    }
  }

  // Lock not acquired — wait and retry
  await sleep(100);
  return getUserWithLock(userId);
}

// Solution 2: Stale-while-revalidate
async function getUserStaleOk(userId: string): Promise<User> {
  const cacheKey = `user:${userId}`;
  const cached = await redis.get(cacheKey);

  if (cached) {
    const { data, expiresAt } = JSON.parse(cached);
    if (Date.now() > expiresAt) {
      // Expired but return stale, refresh in background
      refreshUserCache(userId).catch(() => {});
    }
    return data;
  }

  return refreshUserCache(userId);
}
```

## Multi-Layer Cache

```
Request → L1 (in-process, Map/LRU, ~1ms)
        → L2 (Redis, ~2-5ms)
        → L3 (Database, ~20-100ms)

L1: 1000 items, 30s TTL, per-process
L2: unlimited, 1h TTL, shared across processes
L3: source of truth
```

```typescript
import { LRUCache } from 'lru-cache';

const l1 = new LRUCache<string, User>({ max: 1000, ttl: 30_000 });

async function getUser(userId: string): Promise<User> {
  const key = `user:${userId}`;

  // L1: in-process
  const l1Hit = l1.get(key);
  if (l1Hit) return l1Hit;

  // L2: Redis
  const l2Hit = await redis.get(key);
  if (l2Hit) {
    const user = JSON.parse(l2Hit);
    l1.set(key, user);
    return user;
  }

  // L3: Database
  const user = await db.users.findById(userId);
  l1.set(key, user);
  await redis.set(key, JSON.stringify(user), 'EX', 3600);
  return user;
}
```

## Anti-patterns
- No TTL on cache entries → memory grows forever, stale data
- Caching null results without short TTL → miss storms for non-existent keys
- Serializing entire ORM objects → cache bloat, use DTOs
- Cache invalidation without pub/sub → stale L1 caches in multi-process

## Quick reference
```
Cache-aside: read from cache, miss → load DB → populate cache
Write-through: write DB + cache synchronously (consistent, slower)
Write-behind: write cache first, queue DB write (fast, risk)
Stampede prevention: mutex lock or stale-while-revalidate
Multi-layer: L1 in-process (30s) → L2 Redis (1h) → L3 DB
TTL strategy: hot data 1-5min, warm 1h, cold 24h
Invalidation: delete on write (cache-aside), overwrite (write-through)
Null caching: cache misses with short TTL (30-60s)
```
