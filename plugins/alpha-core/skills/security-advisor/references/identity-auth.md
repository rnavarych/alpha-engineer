# Identity Providers, Zero Trust, and Auth Patterns

## When to load
Load when implementing authentication, selecting an identity provider, designing Zero Trust architecture, or working with passkeys, OAuth 2.1, or advanced authorization models.

## Identity Providers (IdP)

### Enterprise / Workforce Identity
- **Auth0 (Okta CIC)**: Hosted, Actions pipeline, Organizations, SCIM, MFA, passwordless
- **Okta Workforce Identity**: SSO, Universal Directory, Lifecycle Management, Workflows, AMFA
- **Keycloak**: Open-source, self-hosted, OIDC/SAML, realm management, extensions, fine-grained authz
- **Microsoft Entra ID (Azure AD)**: Enterprise SSO, Conditional Access, PIM, B2B/B2C
- **Ping Identity**: Enterprise IAM, PingFederate, PingAccess, PingOne

### Developer-Focused Auth
- **Clerk**: Next.js/React first, components, organizations, webhooks, user management UI
- **Ory Hydra/Kratos**: OAuth2/OIDC server + self-service identity flows, cloud-native, headless
- **WorkOS**: Enterprise SSO (SAML, OIDC), Directory Sync, Admin Portal, audit log
- **Stytch**: Passwordless-first, passkeys, magic links, SMS, embeddable UI
- **Descope**: No-code auth flows, drag-and-drop, passkeys, SCIM, RBAC
- **FusionAuth**: Self-hosted or cloud, themes, advanced MFA; **Zitadel**: Open-source, cloud-native
- **Supabase Auth**: Postgres-based, RLS integration; **Firebase Auth**: social/phone/email, App Check

## Zero Trust Architecture

### Principles
- Never trust, always verify — authenticate and authorize every request
- Assume breach — segment everything, least privilege access
- Verify explicitly — use all available signals (identity, location, device, service)
- Microsegmentation: isolate workloads, limit blast radius

### Tools
- **Cloudflare Access / ZTNA**: Identity-aware proxy, no VPN, SSO integration
- **Tailscale**: WireGuard-based mesh VPN, identity-driven ACLs, MagicDNS
- **HashiCorp Boundary**: Identity-based access to infrastructure, session recording
- **Zscaler ZPA**: Cloud-native ZTNA; **Palo Alto Prisma Access**: SASE platform
- **mTLS via Istio/Linkerd**: Automatic mTLS between pods; SPIFFE/SPIRE for workload identity

## Passkeys / WebAuthn / FIDO2
- **WebAuthn**: W3C standard for passwordless auth using public-key cryptography
- **FIDO2**: Combines WebAuthn (browser API) + CTAP2 (authenticator protocol)
- **Passkeys**: Synced FIDO credentials — iCloud Keychain, Google Password Manager, Windows Hello, 1Password
- Registration: `navigator.credentials.create()` → store public key on server
- Authentication: `navigator.credentials.get()` → verify signature with stored public key
- Conditional UI: `autofill="webauthn"` for seamless passkey autofill
- Phishing-resistant: cryptographic binding to origin, no passwords to steal

## Authorization Models
- **RBAC**: Role-based (admin, editor, viewer) — simple, fits most apps
- **ABAC**: Attribute-based (department, clearance, time, location) — flexible, complex policy evaluation
- **ReBAC**: Relationship-based (Google Zanzibar / SpiceDB / OpenFGA) — for complex object graphs
- **Policy-as-Code**: OPA (Rego), Cedar (AWS Verified Permissions) — version-controlled authz policies
- Always enforce authorization server-side; log all authorization decisions for audit

## OAuth 2.1 Changes (from 2.0)
- PKCE required for all clients (not just public)
- Implicit flow and Resource Owner Password Credentials flow removed
- Refresh token rotation required, sender-constrained recommended
- Redirect URI exact matching required

## JWT Best Practices
- Short expiration: 15 min access tokens, 7 day refresh tokens (with rotation)
- Use RS256 or ES256 (asymmetric) over HS256 for distributed systems
- Always validate: signature, exp, nbf, iss, aud claims
- Store minimal claims — avoid PII in payload (only base64-encoded, not encrypted)
- Use JWE when payload contains sensitive data
- Token revocation via short TTL + Redis blocklist or introspection endpoint
