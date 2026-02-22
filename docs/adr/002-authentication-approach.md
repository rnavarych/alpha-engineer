# ADR-002: Authentication Approach

## Status
ACCEPTED

## Date
2025-02-20

## Context
The application requires user authentication for a B2B SaaS dashboard.
Key requirements:
- Multi-device support (web today, mobile clients planned within 6 months)
- Session persistence ("remember me" capability — planned for v2)
- Stateless horizontal scaling on Vercel Edge
- Compatibility with future mobile clients without re-architecting auth

## Options Considered

### Option A: Server-side sessions with cookies
- **Pros:** Simple implementation, built-in CSRF protection via SameSite cookies, easy session revocation by deleting server-side record
- **Cons:** Requires session store (Redis or database table), harder to scale horizontally on Vercel Edge functions, not suitable for mobile clients without additional adapter layer

### Option B: JWT with refresh tokens
- **Pros:** Stateless access tokens work on Edge without session store, platform-agnostic (web and mobile use the same tokens), horizontal scaling friendly
- **Cons:** Access token revocation requires token blocklist or short TTL, refresh token storage adds complexity, larger payload than a session cookie

### Option C: OAuth 2.0 with external provider (Auth0, Clerk)
- **Pros:** Delegated authentication reduces security surface, SSO capability for B2B enterprise customers, built-in MFA, social login
- **Cons:** External service dependency, per-seat pricing becomes significant at scale, less control over token format and storage, integration complexity

## Decision
**Option B: JWT with refresh tokens.**

Access tokens: 15-minute TTL, stored in memory (not localStorage).
Refresh tokens: stored in PostgreSQL with device fingerprint, rotation on each use.

## Rationale
- Vercel Edge functions are stateless by design — server-side sessions would require a Redis layer (additional infrastructure, cost, operational overhead)
- Mobile clients are planned within 6 months; JWT is platform-agnostic and avoids re-architecting auth when mobile ships
- Short-lived access tokens (15 minutes) mitigate the revocation complexity for typical use cases
- Refresh token rotation (new refresh token issued on each use) prevents token replay attacks
- PostgreSQL (already the primary database per ADR-001) handles refresh token storage without adding infrastructure
- External auth provider introduces vendor dependency and per-seat cost that is inappropriate at current scale (5 beta clients)

## Consequences
- Token refresh middleware required on both client and server
- Must handle concurrent refresh requests gracefully (race condition when multiple tabs refresh simultaneously)
- Client must store access tokens in memory only — not localStorage or sessionStorage — to prevent XSS token theft
- Dashboard UI must handle token expiry gracefully without losing user-entered data
- Token revocation on logout requires deleting the refresh token record in PostgreSQL (access tokens expire naturally)
- "Remember me" (extended refresh token TTL) deferred to v2; current TTL TBD pending threat model review

## Related
- Depends on: ADR-001 (PostgreSQL as refresh token store)
- Informs: Future ADR on API rate limiting and token validation middleware
- Open: Token rotation TTL (15 minutes vs 1 hour) — under review, decision pending
