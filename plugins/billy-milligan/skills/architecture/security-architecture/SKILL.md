---
name: security-architecture
description: |
  Security architecture: JWT rotation, OAuth2/OIDC, encryption, OWASP top 10,
  zero-trust patterns, mTLS, RLS multi-tenancy. Use when designing auth or security.
allowed-tools: Read, Grep, Glob
---

# Security Architecture

## When to use
- Designing authentication/authorization for a new service
- Implementing encryption (at-rest, in-transit, field-level)
- Reviewing security posture against OWASP or zero-trust principles

## Core principles
1. **Defense in depth** — no single security layer; combine auth + encryption + validation + monitoring
2. **Principle of least privilege** — request only permissions actually needed
3. **Secrets never in code** — environment variables, vault, KMS — no exceptions
4. **Validate all external input** — every boundary is a trust boundary
5. **Security is a feature** — design it in, don't bolt it on

## References available
- `references/auth-patterns.md` — JWT rotation, sessions, OAuth2/OIDC, API keys, mTLS decision tree
- `references/encryption-reference.md` — at-rest, in-transit, field-level, KMS/Vault key management
- `references/owasp-top-10.md` — A01–A05: broken access control, crypto failures, injection, insecure design, misconfiguration
- `references/owasp-extended.md` — A06–A10: vulnerable components, auth failures, integrity, security logging, SSRF
- `references/zero-trust-patterns.md` — service mesh, mTLS, SPIFFE/SPIRE, network policies

## Assets available
- `assets/security-review-template.md` — threat model template: assets, threats, mitigations
