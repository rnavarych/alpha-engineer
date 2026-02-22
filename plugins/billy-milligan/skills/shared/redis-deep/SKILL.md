---
name: redis-deep
description: |
  Redis deep-dive: 8 data structures with use cases, Redlock distributed locking algorithm,
  sliding window rate limiter with sorted sets, pub/sub patterns, streams for event log,
  pipeline batching, keyspace notifications, memory eviction policies, Redis Cluster vs Sentinel.
  Use when implementing caching, distributed locks, rate limiting, real-time features.
allowed-tools: Read, Grep, Glob
---

# Redis Deep Dive

## When to Use This Skill
- Implementing distributed locking (Redlock)
- Building rate limiters with sliding windows
- Designing pub/sub for real-time features
- Using Redis Streams for event log
- Choosing memory eviction policy

## Core Principles

1. **Redis is not a database for data you cannot afford to lose** — AOF/RDB persistence is best-effort; design for Redis to be empty
2. **One connection per operation is wasteful** — use pipelining for batch operations (10× throughput improvement)
3. **Key naming convention is critical** — `resource:id:field` prevents collisions and enables pattern scanning
4. **TTL everything** — unbounded keys accumulate until OOM; if no TTL makes sense, use a large one (7 days)
5. **Redlock requires majority quorum** — N/2+1 nodes must confirm; never use single-node lock for distributed coordination

---

## Patterns ✅

### 8 Data Structures and Use Cases

```typescript
// 1. STRING — counters, simple cache, distributed locks
await redis.set('user:123:profile', JSON.stringify(profile), 'EX', 3600);
await redis.incr('stats:daily_signups');
await redis.incrby('cart:user:123:item_count', 3);

// 2. HASH — structured objects, frequent partial updates
await redis.hset('user:123', { name: 'Alice', plan: 'pro', loginCount: '42' });
await redis.hincrby('user:123', 'loginCount', 1);
const user = await redis.hgetall('user:123');

// 3. LIST — queues, activity feeds (ordered by insertion)
await redis.lpush('notifications:user:123', JSON.stringify(notification));  // prepend
const notifications = await redis.lrange('notifications:user:123', 0, 9);  // last 10
await redis.ltrim('notifications:user:123', 0, 99);  // keep only last 100

// 4. SET — unique collections, membership checks, set operations
await redis.sadd('online_users', userId);
await redis.srem('online_users', userId);
const isOnline = await redis.sismember('online_users', userId);
const mutualFollowers = await redis.sinter(`followers:${a}`, `followers:${b}`);

// 5. SORTED SET — leaderboards, delayed queues, sliding window
await redis.zadd('leaderboard', { score: 9500, member: userId });
const top10 = await redis.zrevrange('leaderboard', 0, 9, 'WITHSCORES');
// Scheduled jobs: score = Unix timestamp to execute at
await redis.zadd('scheduled_jobs', { score: executeAt, member: JSON.stringify(job) });

// 6. STREAM — append-only log, consumer groups (Kafka-lite)
await redis.xadd('order_events', '*', {
  type: 'OrderPlaced',
  orderId: '123',
  userId: '456',
});
const events = await redis.xread({ COUNT: 10, STREAMS: [{ key: 'order_events', id: '0' }] });

// 7. BITFIELD — compact boolean arrays, feature flags for user cohorts
await redis.setbit(`feature:dark_mode:users`, parseInt(userId), 1);
const hasFeature = await redis.getbit(`feature:dark_mode:users`, parseInt(userId));

// 8. HyperLogLog — approximate unique count, very low memory
await redis.pfadd('unique_visitors:2024-01-15', visitorId);
const approximateCount = await redis.pfcount('unique_visitors:2024-01-15');
// ~0.81% error, uses max 12KB regardless of set size
```

### Redlock — Distributed Locking

```typescript
// Redlock requires ≥3 independent Redis nodes for safety
// Single-node lock is NOT safe for distributed coordination

import Redlock from 'redlock';

const redlock = new Redlock([redis1, redis2, redis3], {
  driftFactor: 0.01,    // 1% clock drift compensation
  retryCount: 10,
  retryDelay: 200,      // ms between retries
  retryJitter: 100,     // random jitter to prevent thundering herd
});

async function processOrderExclusively(orderId: string): Promise<void> {
  const lockKey = `lock:order:${orderId}`;
  const ttl = 30_000;  // 30 seconds — longer than expected operation

  let lock;
  try {
    lock = await redlock.acquire([lockKey], ttl);

    // Critical section — only one process runs this at a time
    await processOrder(orderId);

  } finally {
    // Always release — even if operation failed
    if (lock) {
      await lock.release();
    }
  }
}

// If operation takes longer than TTL, lock expires automatically
// Extend lock before TTL if needed: lock = await lock.extend(ttl)
```

### Sliding Window Rate Limiter with Sorted Sets

```typescript
// Sliding window: count requests in last N seconds
// More accurate than fixed window (no burst at window boundaries)

async function slidingWindowRateLimit(
  userId: string,
  endpoint: string,
  limitPerHour: number,
): Promise<{ allowed: boolean; remaining: number; resetIn: number }> {
  const key = `ratelimit:${userId}:${endpoint}`;
  const now = Date.now();
  const windowMs = 3_600_000;  // 1 hour in ms
  const windowStart = now - windowMs;

  // Remove expired entries, add current, count window, refresh TTL
  // These are sent as a batch (pipeline/multi) in production for atomicity
  await redis.zremrangebyscore(key, 0, windowStart);
  await redis.zadd(key, { score: now, member: `${now}-${Math.random()}` });
  const [currentCount] = await Promise.all([
    redis.zcard(key),
    redis.expire(key, 3600),
  ]);

  const allowed = currentCount <= limitPerHour;
  const remaining = Math.max(0, limitPerHour - currentCount);

  // Oldest entry determines when the window frees up
  const oldest = await redis.zrange(key, 0, 0, 'WITHSCORES');
  const oldestScore = oldest[1] ? Number(oldest[1]) : now;
  const resetIn = Math.ceil((oldestScore + windowMs - now) / 1000);

  if (!allowed) {
    // Remove the entry we just added — don't count rejected requests
    await redis.zremrangebyscore(key, now, now);
  }

  return { allowed, remaining, resetIn };
}
```

### Pub/Sub for Real-Time Notifications

```typescript
// Pub/Sub: fan-out to all subscribers
// NOT for guaranteed delivery — use Streams for that

// Publisher (after order status changes)
export class NotificationPublisher {
  async publishOrderUpdate(orderId: string, status: string): Promise<void> {
    const channel = `order_updates:${orderId}`;
    const message = JSON.stringify({ orderId, status, timestamp: Date.now() });
    await redis.publish(channel, message);
  }
}

// Subscriber (WebSocket server)
export class NotificationSubscriber {
  private subscriber: ReturnType<typeof createClient>;

  constructor() {
    // IMPORTANT: subscribe requires a dedicated connection — cannot share with commands
    this.subscriber = createClient({ url: process.env.REDIS_URL });
  }

  async subscribeToOrder(orderId: string, callback: (msg: string) => void): Promise<void> {
    await this.subscriber.subscribe(`order_updates:${orderId}`, callback);
  }

  async unsubscribeFromOrder(orderId: string): Promise<void> {
    await this.subscriber.unsubscribe(`order_updates:${orderId}`);
  }
}
```

### Memory Eviction Policies

```
Choose based on your use case:

noeviction (default): return error when memory limit reached
  Use: never (you want eviction, not errors)

allkeys-lru: evict least recently used keys from all keys
  Use: general-purpose cache where all keys are equally valuable

allkeys-lfu: evict least frequently used keys
  Use: when some keys are accessed much more often (hot vs cold cache)

volatile-lru: evict LRU keys that have TTL set
  Use: mixed workload — some keys are persistent, some are cache

volatile-ttl: evict keys closest to expiry
  Use: when you want to keep fresh data and discard stale first

allkeys-random: evict random keys
  Use: never (worse than LRU for almost all cases)

Recommendation: allkeys-lfu for cache, volatile-lru for mixed
```

---

## Anti-Patterns ❌

### Using Individual Awaits in a Loop (No Pipelining)
**What it is**: Calling `await redis.get(key)` in a for loop, 100 times.
**What breaks**: 100 round-trips × 0.1ms RTT = 10ms minimum; with 1ms RTT = 100ms. Synchronous calls serialize everything.
**Fix**: Use `mget`/`mset` for bulk key access. Use `redis.multi()` to batch commands and send them in one round-trip. Pipeline sends all commands at once, collects results in bulk.

### Pub/Sub for Guaranteed Delivery
**What it is**: Using PUBLISH/SUBSCRIBE for important events expecting all subscribers to receive them.
**What breaks**: If subscriber disconnects for 100ms, it misses all messages published during that time. No persistence, no replay, no consumer groups.
**Fix**: Use Redis Streams (`XADD`/`XREADGROUP`) for guaranteed delivery with consumer groups and message acknowledgment.

### No Key Naming Convention
**What it is**: Keys like `user_data`, `userData`, `User123`, `orders:123:items` all mixed.
**What breaks**: Impossible to manage, delete by pattern, or understand what data is stored where.
**Fix**: `resource:id:field` convention. Examples: `session:abc123`, `rate:user:456:api`, `cache:product:789`.

---

## Quick Reference

```
Key naming: resource:id:field — e.g., session:abc123, rate:user:456:api
TTL: always set; use 3600 (1h) for cache, 86400 (24h) for sessions
Redlock: ≥3 nodes, N/2+1 quorum, TTL > operation duration
Rate limit: sorted set + ZREMRANGEBYSCORE + ZADD + ZCARD + EXPIRE in batch
Pub/Sub: fire-and-forget fan-out; use Streams for guaranteed delivery
Eviction: allkeys-lfu for cache, volatile-lru for mixed
Batch commands: use redis.multi() to pipeline multiple commands in one round-trip
Subscribe: requires dedicated connection (cannot share with command connection)
Persistence: AOF for stronger durability; RDB for backups; neither = data loss on restart
```
