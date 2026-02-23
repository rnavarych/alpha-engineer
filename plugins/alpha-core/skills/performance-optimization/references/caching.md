# Caching Layers

## When to load
Load when choosing CDN caching headers, implementing Redis cache-aside patterns, or selecting in-memory cache libraries.

## CDN (Edge Caching)

### CDN Providers
| Provider | Strengths | Edge Locations | Key Features |
|----------|-----------|----------------|--------------|
| **CloudFront** (AWS) | AWS integration, Lambda@Edge | 450+ | Origin Shield, signed URLs, real-time logs |
| **Fastly** (Varnish-based) | Instant purge (<150ms), VCL | 90+ | Real-time logging, edge compute (Wasm) |
| **Cloudflare** | Free tier, Workers, DDoS protection | 310+ | Workers (JS/Wasm), R2 storage, Cache Rules |
| **Akamai** | Enterprise, largest network | 4000+ | Edge computing, security suite |

### Cache-Control Headers
```
# Hashed static assets (fingerprinted filenames)
Cache-Control: public, max-age=31536000, immutable

# HTML pages (mutable content)
Cache-Control: public, max-age=0, must-revalidate

# API responses (dynamic but cacheable)
Cache-Control: public, max-age=30, s-maxage=60, stale-while-revalidate=300

# Private data (user-specific)
Cache-Control: private, max-age=0, no-store

# ETag-based validation
ETag: "abc123"
# Client sends: If-None-Match: "abc123" -> 304 Not Modified
```

- `stale-while-revalidate`: Serves stale content immediately while revalidating in background
- `stale-if-error`: Serve stale content if origin is down
- `s-maxage`: CDN-specific max-age (overrides max-age for shared caches)

## Application In-Memory Caches
| Language | Library | Features |
|----------|---------|----------|
| Node.js | `lru-cache` | LRU eviction, TTL, size-based limits, stale-while-revalidate |
| Python | `cachetools` | LRU, LFU, TTL, RR policies, thread-safe |
| Python | `functools.lru_cache` | Built-in, decorator, maxsize, typed |
| Java | Caffeine | Near-optimal hit rate, async loading, size/time eviction, stats |
| Go | `ristretto` | Contention-free, high hit ratio, metrics |
| .NET | `IMemoryCache` | Built-in, size limits, sliding/absolute expiration |

## Redis Cache Patterns

### Cache-Aside (Python)
```python
import redis, json

r = redis.Redis(host='localhost', port=6379, decode_responses=True)

def get_user(user_id):
    cache_key = f"user:{user_id}"
    cached = r.get(cache_key)
    if cached:
        return json.loads(cached)
    user = db.query("SELECT * FROM users WHERE id = %s", user_id)
    r.setex(cache_key, 3600, json.dumps(user))  # TTL: 1 hour
    return user
```

### Cache-Aside (Node.js with ioredis)
```javascript
async function getUser(userId) {
  const cacheKey = `user:${userId}`;
  const cached = await redis.get(cacheKey);
  if (cached) return JSON.parse(cached);
  const user = await db.query('SELECT * FROM users WHERE id = $1', [userId]);
  await redis.setex(cacheKey, 3600, JSON.stringify(user));
  return user;
}

async function updateUser(userId, data) {
  await db.query('UPDATE users SET name = $1 WHERE id = $2', [data.name, userId]);
  await redis.del(`user:${userId}`);  // Invalidate on write
}
```

### Write-Through (Python)
```python
def save_product(product_id, product_data):
    db.execute("INSERT INTO products (id, data) VALUES (%s, %s) ON CONFLICT (id) DO UPDATE SET data = %s",
               (product_id, json.dumps(product_data), json.dumps(product_data)))
    r.setex(f"product:{product_id}", 7200, json.dumps(product_data))
```

## Cache Stampede Prevention
- **Locking**: Only one request recomputes; others wait or serve stale
- **Probabilistic early expiration (XFetch)**: Refresh before TTL expires with increasing probability
- **stale-while-revalidate**: Serve stale value immediately, refresh asynchronously
- **Cache warming**: Pre-populate cache on deployment or schedule

## Cache Invalidation Strategies
- **TTL-based**: Simple, eventual consistency. Best for infrequently-changing data.
- **Event-based**: Invalidate on write events (CDC, pub/sub). Near real-time consistency.
- **Version-based**: Cache key includes data version or hash. Instant invalidation via key change.
- **Write-through**: Update cache synchronously on every write. Strong consistency, slower writes.
- **Write-behind**: Update cache immediately, write to DB asynchronously. Fast writes, risk of data loss.
- **Tag-based purge**: Group related entries with tags, purge all by tag (Fastly surrogate keys, CloudFront cache policies)
