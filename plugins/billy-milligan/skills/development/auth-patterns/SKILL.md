---
name: auth-patterns
description: Authentication patterns — JWT, OAuth/OIDC, sessions, multi-tenant auth, RBAC/ABAC
allowed-tools: Read, Grep, Glob, Bash
---

# Auth Patterns Skill

## Core Principles
- **Prevent user enumeration**: Login errors must be identical for "user not found" and "wrong password".
- **Constant-time comparison**: Always use `crypto.timingSafeEqual` for token comparison.
- **Short-lived access tokens**: 15 minutes max; refresh tokens rotate on use.
- **RBAC at middleware level**: Authorization check before business logic, not inside it.
- **Never trust the client**: Re-verify permissions on every request, not just at login.

## References
- `references/jwt-implementation.md` — Access/refresh tokens, rotation, httpOnly cookies, revocation
- `references/oauth-oidc.md` — Authorization code + PKCE, token exchange, provider integration
- `references/session-implementation.md` — Redis sessions, session fixation, CSRF protection
- `references/multi-tenant-auth.md` — Tenant context middleware, RLS, RBAC permission matrix
- `references/tenant-data-isolation.md` — Schema-per-tenant, database-per-tenant, hybrid tier routing, ABAC, org-level permissions
