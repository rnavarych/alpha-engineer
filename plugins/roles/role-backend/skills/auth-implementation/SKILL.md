---
name: auth-implementation
description: |
  Implements authentication and authorization systems including JWT token management,
  session handling, OAuth2 flows, OpenID Connect, RBAC/ABAC enforcement, API key management,
  multi-tenancy auth isolation, SSO integration, and refresh token rotation.
  Use when building login flows, protecting endpoints, implementing permissions, or integrating identity providers.
allowed-tools: Read, Grep, Glob, Bash
---

# Auth Implementation

## When to use
- Building login, logout, and token refresh flows
- Choosing between JWT and server-side sessions
- Implementing OAuth2 authorization code flow with PKCE for SPAs or mobile
- Setting up RBAC or ABAC permission enforcement on API endpoints
- Managing API keys with hashing, rotation, and scoping
- Enforcing tenant isolation in a multi-tenant system
- Integrating enterprise SSO (SAML 2.0, OIDC) with JIT provisioning

## Core principles
1. **Tokens contain minimal claims** — `sub`, roles, tenant only; nothing sensitive in JWT payload
2. **Rotate refresh tokens on every use** — reuse of an invalidated token signals theft; revoke the family
3. **Enforce server-side at every layer** — middleware, service, and data layer; frontend checks are UX only
4. **Hash everything at rest** — API keys, refresh tokens; never store plaintext secrets
5. **Deprecated flows stay deprecated** — Implicit and ROPC are gone; PKCE is the only option for public clients

## Reference Files

- `references/jwt-sessions-oauth.md` — JWT structure and token validation checklist, refresh token rotation rules, server-side session cookie flags, OAuth2 flow selection table, Authorization Code + PKCE implementation steps, and OIDC identity verification
- `references/rbac-apikeys-multitenancy-sso.md` — RBAC role/permission model, ABAC with policy engines (Casbin, OPA, Cedar), enforcement point hierarchy, API key generation and hashing, multi-tenancy query isolation, and SSO integration (SAML 2.0, OIDC, JIT provisioning)
