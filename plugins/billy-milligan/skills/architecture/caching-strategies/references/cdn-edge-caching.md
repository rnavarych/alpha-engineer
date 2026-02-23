# CDN & Edge Caching

## When to load
Load when discussing Cache-Control headers, CDN configuration, edge caching with Cloudflare or Vercel, or cache purge strategies.

## Patterns

### Cache-Control headers
```typescript
// Static assets (immutable with content hash in filename)
res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
// e.g., /assets/bundle.a1b2c3.js

// API responses (short-lived, revalidate)
res.setHeader('Cache-Control', 'public, s-maxage=60, stale-while-revalidate=300');
// CDN caches 60s, serves stale up to 5min while revalidating in background

// Private user data (never cache on CDN)
res.setHeader('Cache-Control', 'private, no-store');

// HTML pages (revalidate every request)
res.setHeader('Cache-Control', 'public, max-age=0, must-revalidate');
res.setHeader('ETag', contentHash);
```

### Header breakdown
| Directive | Meaning |
|-----------|---------|
| `public` | CDN and browser can cache |
| `private` | Browser only, no CDN |
| `s-maxage=60` | CDN caches for 60s (overrides max-age for shared caches) |
| `max-age=300` | Browser caches for 5min |
| `stale-while-revalidate=300` | Serve stale for 5min while fetching fresh in background |
| `stale-if-error=86400` | Serve stale for 24h if origin is down |
| `immutable` | Never revalidate (use with hashed filenames only) |
| `no-store` | Never cache anywhere |

### Cloudflare edge config
```toml
# cloudflare page rules or _headers file
[[headers]]
  for = "/api/*"
  [headers.values]
    Cache-Control = "public, s-maxage=30, stale-while-revalidate=60"

[[headers]]
  for = "/assets/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"
```

### Vercel edge config
```typescript
// Next.js API route
export async function GET(request: Request) {
  const data = await fetchProducts();
  return Response.json(data, {
    headers: {
      'Cache-Control': 'public, s-maxage=60, stale-while-revalidate=300',
      'CDN-Cache-Control': 'max-age=60',  // Vercel-specific override
      'Vercel-CDN-Cache-Control': 'max-age=300',  // Vercel edge network
    },
  });
}

// Next.js page-level revalidation
export const revalidate = 60; // ISR: regenerate every 60s
```

### Cache purge strategies
```typescript
// 1. Tag-based purge (Cloudflare)
// Set: Cache-Tag: product-123, category-electronics
// Purge: POST /zones/{zone}/purge_cache { "tags": ["product-123"] }

// 2. Path-based purge
// Purge: POST /zones/{zone}/purge_cache { "files": ["https://example.com/api/products/123"] }

// 3. Surrogate keys (Fastly/Varnish)
res.setHeader('Surrogate-Key', 'product-123 category-electronics');
// Purge: POST /service/{id}/purge/product-123

// 4. Versioned URLs (no purge needed)
// /api/v2/products?_v=1708700000
// Cache key includes version parameter
```

### Vary header (cache segmentation)
```typescript
// Cache different versions per Accept-Encoding and Authorization state
res.setHeader('Vary', 'Accept-Encoding');
// WARNING: Vary: Cookie or Vary: Authorization destroys CDN hit rate
// Instead, use separate endpoints for authenticated vs public data
```

## Anti-patterns
- `Vary: Cookie` on CDN-cached responses -> unique cache entry per user, 0% hit rate
- Caching responses with `Set-Cookie` -> leaking sessions between users
- No `s-maxage` -> browser and CDN use same TTL (usually want different)
- Purging entire CDN on every deploy -> cache is cold, origin gets hammered
- Long `max-age` without hashed filenames -> users stuck with stale JS/CSS

## Decision criteria
- **Static assets**: `immutable` + content hash, 1 year max-age
- **API responses**: `s-maxage=30-60` + `stale-while-revalidate=300`
- **HTML pages**: `max-age=0, must-revalidate` + ETag
- **Private data**: `private, no-store` (never put on CDN)
- **ISR/SSG pages**: `s-maxage=60` + on-demand revalidation

## Quick reference
```
Static assets: public, max-age=31536000, immutable
API (public): public, s-maxage=60, stale-while-revalidate=300
HTML: public, max-age=0, must-revalidate + ETag
Private: private, no-store
Purge strategy: tag-based > path-based > full purge
CDN hit rate target: >90% for static, >60% for API
Average edge latency: 10-50ms vs 100-500ms origin
```
