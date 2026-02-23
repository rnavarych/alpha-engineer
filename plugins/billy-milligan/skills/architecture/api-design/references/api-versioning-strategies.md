# API Versioning Strategies

## When to load
Load when deciding how to version APIs or planning breaking changes.

## Patterns ✅

### URL path versioning
```
GET /api/v1/orders
GET /api/v2/orders
```
- Pros: explicit, easy to route, easy to document, cacheable
- Cons: URL pollution, clients must update URLs for new version
- Best for: public APIs, large-scale APIs with many consumers

### Header versioning
```
GET /api/orders
Accept: application/vnd.myapi.v2+json
```
- Pros: clean URLs, version is metadata not resource identity
- Cons: harder to test (can't just paste URL), not visible in logs by default
- Best for: internal APIs, APIs with sophisticated clients

### Content negotiation
```
GET /api/orders
Accept: application/json; version=2
```
Similar to header versioning but uses standard Accept header parameters.

### Query parameter versioning
```
GET /api/orders?version=2
```
- Pros: simple, works everywhere
- Cons: optional parameter = version ambiguity, breaks caching
- Best for: quick prototypes, not production APIs

## Decision criteria

| Factor | URL Path | Header | Query Param |
|--------|----------|--------|-------------|
| Explicitness | ✓✓✓ | ✓✓ | ✓ |
| Cache-friendly | ✓✓✓ | ✓✓ | ✗ |
| API gateway routing | ✓✓✓ | ✓✓ | ✓ |
| Client simplicity | ✓✓✓ | ✓ | ✓✓ |
| URL cleanliness | ✗ | ✓✓✓ | ✓✓ |

**Recommendation**: URL path versioning for most teams. It's explicit, well-understood, and works with every tool.

### Breaking vs non-breaking changes
Non-breaking (no new version needed):
- Adding new optional fields to response
- Adding new endpoints
- Adding optional query parameters

Breaking (requires new version):
- Removing or renaming fields
- Changing field types
- Changing URL structure
- Changing authentication method
- Changing error format

### Sunset strategy
```
Sunset: Sat, 01 Mar 2025 00:00:00 GMT
Deprecation: true
Link: <https://api.example.com/docs/migration>; rel="sunset"
```
Timeline: announce deprecation → 6 month sunset period → return 410 Gone.

## Quick reference
```
Default choice: URL path versioning (/api/v1/)
Non-breaking: new optional fields, new endpoints
Breaking: removed fields, changed types, changed auth
Sunset period: minimum 6 months with deprecation headers
Max supported versions: 2 (current + previous)
```
