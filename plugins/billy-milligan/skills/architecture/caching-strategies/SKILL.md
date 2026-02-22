---
name: caching-strategies
description: |
  Caching patterns: cache-aside with TTL jitter, write-through, cache stampede prevention
  with distributed lock, CDN cache-control headers, multi-level L1/L2/L3 cache hierarchy,
  cache invalidation strategies, Redis TTL formulas. Use when adding caches, designing
  cache invalidation, preventing thundering herd, setting CDN headers.
allowed-tools: Read, Grep, Glob
---

# Caching Strategies

## When to Use This Skill
- Designing cache layers for high-traffic systems
- Choosing between cache-aside, write-through, write-behind
- Preventing cache stampede / thundering herd
- Setting correct CDN/HTTP cache headers
- Cache invalidation without stale data bugs

## Core Principles

1. **Cache-aside is the default** — application controls all cache interactions
2. **Always add jitter to TTL** — ±10% prevents synchronized expiry stampedes
3. **Cache invalidation is harder than caching** — design invalidation FIRST, then TTL
4. **Multi-level cache reduces latency multiplicatively** — L1 (in-memory) → L2 (Redis) → L3 (DB)
5. **A cache miss should never cascade to a DB overload** — use probabilistic or lock-based prevention

---

## Patterns ✅

### Cache-Aside with Jitter

```typescript
const BASE_TTL = 3600;  // 1 hour

function jitteredTTL(base: number, jitterPct = 0.1): number {
  const jitter = base * jitterPct;
  return Math.floor(base + (Math.random() * 2 - 1) * jitter);
  // Result: base ± 10% → avoids synchronized expiry
}

async function getProduct(id: string): Promise<Product> {
  const cacheKey = `product:${id}`;

  const cached = await redis.get(cacheKey);
  if (cached) {
    metrics.increment('cache.hit', { entity: 'product' });
    return JSON.parse(cached);
  }

  metrics.increment('cache.miss', { entity: 'product' });

  const product = await db.products.findUnique({ where: { id } });
  if (!product) throw new NotFoundError('Product not found');

  await redis.setex(cacheKey, jitteredTTL(BASE_TTL), JSON.stringify(product));
  return product;
}

// Invalidation on write — explicit delete, not waiting for TTL
async function updateProduct(id: string, data: Partial<Product>): Promise<Product> {
  const product = await db.products.update({ where: { id }, data });
  await redis.del(`product:${id}`);  // Invalidate immediately
  return product;
}
```

### Cache Stampede Prevention (Distributed Lock)

**Problem**: 10,000 requests arrive simultaneously, cache expires, all hit the DB. DB overloads.

```typescript
async function getProductWithStampedeProtection(id: string): Promise<Product> {
  const cacheKey = `product:${id}`;
  const lockKey = `lock:product:${id}`;
  const lockId = crypto.randomUUID();

  // Fast path — cache hit
  const cached = await redis.get(cacheKey);
  if (cached) return JSON.parse(cached);

  // Try to acquire lock — only ONE request gets to fetch from DB
  const acquired = await redis.set(lockKey, lockId, 'NX', 'PX', 5000);

  if (!acquired) {
    // Another request is fetching — wait briefly and retry from cache
    await sleep(50);
    const retried = await redis.get(cacheKey);
    if (retried) return JSON.parse(retried);
    // If still no cache after wait, fall through to DB (lock expired)
  }

  try {
    const product = await db.products.findUnique({ where: { id } });
    if (!product) throw new NotFoundError();
    await redis.setex(cacheKey, jitteredTTL(BASE_TTL), JSON.stringify(product));
    return product;
  } finally {
    // Release lock only if we own it (use Lua script via redis.sendCommand for atomicity)
    // Script: if GET key == lockId then DEL key end
    const current = await redis.get(lockKey);
    if (current === lockId) await redis.del(lockKey);
  }
}
```

### Write-Through Cache

Synchronously write to cache AND DB in the same operation.

```typescript
async function setUserPreferences(userId: string, prefs: UserPreferences): Promise<void> {
  const cacheKey = `prefs:${userId}`;

  // Write-through: update both in parallel
  await Promise.all([
    db.userPreferences.upsert({
      where: { userId },
      create: { userId, ...prefs },
      update: prefs,
    }),
    redis.setex(cacheKey, jitteredTTL(86400), JSON.stringify(prefs)),  // 24h TTL
  ]);
}

async function getUserPreferences(userId: string): Promise<UserPreferences> {
  const cached = await redis.get(`prefs:${userId}`);
  if (cached) return JSON.parse(cached);

  const prefs = await db.userPreferences.findUnique({ where: { userId } });
  if (prefs) {
    await redis.setex(`prefs:${userId}`, jitteredTTL(86400), JSON.stringify(prefs));
  }
  return prefs ?? defaultPreferences;
}
```

Best for: Data read frequently, written infrequently (preferences, config).
Not for: High-write data (metrics, events) — too many cache writes, no benefit.

### Multi-Level Cache (L1 → L2 → DB)

```typescript
// L1: In-process memory (0ms, per-instance, limited size)
// L2: Redis (0.5–2ms, shared across instances, large)
// L3: Database (5–50ms, source of truth)

const l1Cache = new LRUCache<string, Product>({
  max: 1000,        // Max 1000 items in memory
  ttl: 60_000,      // 60 seconds — short, stale risk with multiple instances
});

async function getProduct(id: string): Promise<Product> {
  // L1 — in-process, 0ms
  const l1Hit = l1Cache.get(`product:${id}`);
  if (l1Hit) return l1Hit;

  // L2 — Redis, 0.5-2ms
  const l2Raw = await redis.get(`product:${id}`);
  if (l2Raw) {
    const product = JSON.parse(l2Raw);
    l1Cache.set(`product:${id}`, product);  // Backfill L1
    return product;
  }

  // L3 — Database, 5-50ms
  const product = await db.products.findUnique({ where: { id } });
  if (!product) throw new NotFoundError();

  // Backfill both levels
  await redis.setex(`product:${id}`, jitteredTTL(3600), JSON.stringify(product));
  l1Cache.set(`product:${id}`, product);

  return product;
}
```

**L1 TTL**: Short (30–120s) — multiple instances will have different data after writes.
**L1 invalidation**: Cannot reliably invalidate across all instances. Accept short staleness via TTL.

### CDN and HTTP Cache Headers

```typescript
// Static assets — cache 1 year (content-addressed with hash in filename)
res.set({
  'Cache-Control': 'public, max-age=31536000, immutable',
});

// User-specific API responses — never cache
res.set({
  'Cache-Control': 'no-store',
});

// Public API responses (same for all users)
res.set({
  'Cache-Control': 'public, max-age=60, s-maxage=300, stale-while-revalidate=600',
  // Browser: 60s fresh | CDN edge: 5min fresh | CDN serves stale 10min while revalidating
  'Vary': 'Accept-Language',
});

// Authenticated API — private cache, must revalidate
res.set({
  'Cache-Control': 'private, no-cache',
  'ETag': etag(responseBody),  // Client can use If-None-Match for 304
});
```

---

## Anti-Patterns ❌

### No TTL Jitter
**What it is**: All cache entries set to exactly 3600 seconds.
**What breaks**: Everything cached at startup → all expires simultaneously → thundering herd → DB overloads exactly 1 hour later.
**Fix**: `jitteredTTL(3600)` — spreads expiry across ±360 seconds.

### Cache Invalidation via TTL Only
**What it is**: Relying on expiry to "eventually" fix stale data.
**What breaks**: Admin updates product price → customers see old price for up to 1 hour → revenue loss, support tickets.
**Fix**: Explicit `redis.del(cacheKey)` on every write. TTL is a safety net, not the primary invalidation mechanism.

### Public CDN Cache for User-Specific Data
**What it is**: `Cache-Control: public` on `/api/cart` or `/api/profile`.
**What breaks**: CDN serves User A's cart to User B. Immediate security incident.
**Rule**: `private` or `no-store` for any user-specific response.

### No TTL on Redis Keys
**What it is**: `redis.set(key, value)` without expiry.
**What breaks**: Redis memory fills over time. Keys accumulate forever. Stale data never clears.
**Rule**: Every cache entry must have a TTL. Max TTL: 24 hours for most data.

---

## Quick Reference

```
Jitter formula: base ± (base × 0.1) — avoids thundering herd on synchronized expiry
Cache-aside: default — app controls read and write
Write-through: sync write to cache + DB — low-write, high-read data only
Stampede: acquire lock, let one request fetch, others wait 50ms and retry
L1 TTL: 30–120s (staleness risk with multiple instances)
L2 TTL: 1h–24h with jitter
CDN public: s-maxage=300, stale-while-revalidate=600
Never: Cache-Control: public for user-specific responses
```
