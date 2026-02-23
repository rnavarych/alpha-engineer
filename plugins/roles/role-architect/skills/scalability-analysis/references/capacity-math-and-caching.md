# Back-of-Envelope Calculations and Caching Layers

## When to load
Load when performing QPS, storage, bandwidth, or memory estimations, or when designing application-level, database, and CDN caching layers with invalidation strategies.

## Back-of-Envelope Calculations

### QPS Estimation
- DAU (Daily Active Users) x actions_per_user / 86,400 = average QPS.
- Peak QPS = average QPS x peak_multiplier (2x-5x for most applications, 10x-100x for event-driven spikes).

### Storage Estimation
- Per-record size (bytes) x records_per_day x retention_days = raw storage.
- Multiply by replication factor (typically 3x for distributed databases).
- Add index overhead (20-50% of raw data size).
- Add backup storage (full daily + incremental hourly = roughly 2x raw).

### Bandwidth Estimation
- Average response size (KB) x QPS = bandwidth (KB/s). Convert to Mbps or Gbps.
- Include both inbound (request payloads, file uploads) and outbound (responses, downloads).
- CDN offloads static content bandwidth. Estimate CDN-served vs. origin-served traffic ratio.

### Memory Estimation
- Cache hit ratio target (e.g., 95%). Calculate working set size: unique items accessed in a time window x item size.
- Connection memory: each database connection consumes 5-10 MB. 1000 connections = 5-10 GB.
- Application memory: per-request allocation x concurrent requests. Profile to get accurate numbers.

## Caching Layers for Scale

### Application-Level Cache
- In-process cache (local memory). Fastest, but not shared across instances. Use for hot configuration and small reference data.
- Distributed cache (Redis, Memcached). Shared across all application instances. Use for session data, computed results, and rate limiting.

### Database Query Cache
- Materialized views for expensive aggregations. Refresh on a schedule or trigger.
- Query result caching at the ORM or query layer. Invalidate on writes to the underlying tables.

### CDN and Edge Cache
- Cache static assets (images, CSS, JS) at the CDN edge. Set long TTLs with content hashing for cache busting.
- Cache API responses at the edge for read-heavy public APIs. Use `Cache-Control` and `ETag` headers for invalidation.

### Cache Invalidation
- TTL-based: simple but risks serving stale data for the TTL duration.
- Event-based: publish cache invalidation events on writes. More complex but ensures fresher data.
- Write-through: update the cache synchronously on every write. Ensures consistency but adds write latency.
- Cache-aside: application reads from cache first; on miss, reads from database and populates cache. Most common pattern.
