# Cache Invalidation

## When to load
Load when discussing cache invalidation strategies, stampede prevention, event-driven invalidation, or versioned cache keys.

## Patterns

### Explicit invalidation on write
```typescript
async function updateProduct(id: string, data: UpdateProductDTO) {
  const product = await db.products.update(id, data);

  // Invalidate specific key
  await cache.del(`product:${id}`);
  // Invalidate related collections
  await cache.del(`products:category:${product.categoryId}`);
  await cache.del('products:featured');

  return product;
}
```
Simple but requires knowing all affected cache keys. Misses -> stale data.

### Stampede prevention with distributed lock
```typescript
async function getWithStampedeProtection(key: string, fetchFn: () => Promise<any>, ttl: number) {
  const cached = await cache.get(key);
  if (cached) return JSON.parse(cached);

  const lockKey = `lock:${key}`;
  const acquired = await cache.set(lockKey, '1', 'NX', 'EX', 10); // 10s lock

  if (acquired) {
    try {
      const data = await fetchFn();
      await cache.set(key, JSON.stringify(data), 'EX', ttl);
      return data;
    } finally {
      await cache.del(lockKey);
    }
  }

  // Another process is fetching - wait and retry
  await sleep(100);
  return getWithStampedeProtection(key, fetchFn, ttl);
}
```

### Probabilistic early expiration (XFetch)
```typescript
async function xfetch(key: string, fetchFn: () => Promise<any>, ttl: number, beta = 1) {
  const entry = await cache.get(key);
  if (entry) {
    const { data, expiry, delta } = JSON.parse(entry);
    const now = Date.now();
    // Probabilistically recompute before expiry
    const shouldRecompute = now - delta * beta * Math.log(Math.random()) >= expiry;
    if (!shouldRecompute) return data;
  }

  const start = Date.now();
  const data = await fetchFn();
  const delta = Date.now() - start; // computation time
  const expiry = Date.now() + ttl * 1000;

  await cache.set(key, JSON.stringify({ data, expiry, delta }), 'EX', ttl);
  return data;
}
```
Higher `beta` -> earlier recomputation. Expensive queries benefit from beta=2.

### Event-driven invalidation
```typescript
// Producer: emit event on data change
async function updateProduct(id: string, data: UpdateProductDTO) {
  const product = await db.products.update(id, data);
  await eventBus.publish('product.updated', {
    productId: id,
    categoryId: product.categoryId,
    timestamp: Date.now(),
  });
  return product;
}

// Consumer: invalidate cache on event
eventBus.subscribe('product.updated', async (event) => {
  const keys = [
    `product:${event.productId}`,
    `products:category:${event.categoryId}`,
    'products:featured',
    'products:search:*', // pattern-based invalidation
  ];
  await Promise.all(keys.map(k =>
    k.includes('*') ? scanAndDelete(k) : cache.del(k)
  ));
});
```
Decouples write path from cache logic. Works across services.

### Versioned cache keys
```typescript
// Store version counter per entity type
async function getProductsV(categoryId: string) {
  const version = await cache.get('products:version') || '1';
  const key = `products:cat:${categoryId}:v${version}`;

  const cached = await cache.get(key);
  if (cached) return JSON.parse(cached);

  const products = await db.products.findByCategory(categoryId);
  await cache.set(key, JSON.stringify(products), 'EX', 3600);
  return products;
}

// On any product write, bump version (old keys expire via TTL)
async function invalidateProducts() {
  await cache.incr('products:version');
  // Old versioned keys auto-expire - no explicit deletion needed
}
```
Pros: no stampede, no explicit key tracking. Cons: temporary memory increase during version transition.

### TTL as safety net
Every cache key must have a TTL, even with active invalidation. TTL prevents permanent stale data when invalidation fails.

```
User profiles:     300s (5min)
Product listings:  60s  (1min)
Config/settings:   3600s (1hr)
Session data:      86400s (24hr)
Search results:    30s
Feature flags:     10s
```

## Anti-patterns
- Invalidation without TTL backup -> permanent stale data on missed invalidation
- `KEYS pattern*` for bulk invalidation -> blocks Redis; use SCAN with COUNT 100
- Invalidating cache inside DB transaction -> transaction rolls back, cache already cleared
- Cascading invalidation across all services synchronously -> single cache miss takes down system

## Decision criteria
- **Explicit delete**: simple apps, few cache keys per entity, strong consistency needed
- **Event-driven**: microservices, cross-service cache, eventual consistency OK
- **Versioned keys**: high-traffic, many related keys, can tolerate brief memory spike
- **XFetch/probabilistic**: expensive computations (>100ms), high concurrency

## Quick reference
```
Always set TTL (safety net): user=5min, product=1min, config=1hr
Stampede prevention: distributed lock OR probabilistic early expiry
Event-driven: decouple write from invalidation, eventual consistency
Versioned keys: bump version counter, old keys auto-expire via TTL
Invalidate AFTER successful DB commit, never inside transaction
SCAN (not KEYS) for pattern-based invalidation: COUNT 100 per iteration
```
