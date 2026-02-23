# JWT, Sessions, and OAuth2 Flows

## When to load
Load when implementing JWT token lifecycle, session management, OAuth2 authorization flows, or OpenID Connect identity verification.

## JWT Implementation

### Token Structure
- **Access token**: Short-lived (15 minutes), contains minimal claims (`sub`, `roles`, `tenant`)
- **Refresh token**: Longer-lived (7-30 days), stored securely, used only to obtain new access tokens
- Use RS256 (asymmetric) for distributed systems; HS256 only for single-service setups
- Never store sensitive data in JWT payload — it is base64-encoded, not encrypted

### Token Validation Checklist
1. Verify signature against the public key or secret
2. Check `exp` (expiration) — reject expired tokens
3. Check `iat` (issued at) — reject tokens issued in the future
4. Validate `iss` (issuer) — must match expected issuer
5. Validate `aud` (audience) — must match the current service
6. Check token blacklist/revocation list for logged-out sessions

### Refresh Token Rotation
- Issue a new refresh token with every access token refresh
- Invalidate the old refresh token immediately after use
- Detect reuse of an invalidated refresh token (indicates theft) and revoke the entire family
- Store refresh tokens hashed in the database (never plaintext)
- Implement absolute expiration (max lifetime regardless of rotation frequency)

## Session Management

- Use server-side sessions for traditional web apps (Redis or database-backed)
- Regenerate session ID after authentication state changes (login, privilege escalation)
- Set cookie flags: `Secure`, `HttpOnly`, `SameSite=Strict` (or `Lax` for OAuth redirects)
- Implement absolute timeout (max session lifetime) and idle timeout
- Store minimal data in sessions; use session ID as reference to server-side state
- Clear session data completely on logout (server-side and cookie)

## OAuth2 Flows

| Flow | Use Case | Security Level |
|------|----------|----------------|
| Authorization Code + PKCE | SPAs, mobile apps, server-side apps | Highest |
| Client Credentials | Service-to-service (machine-to-machine) | High (no user context) |
| Device Authorization | Smart TVs, CLI tools, IoT devices | Medium |
| ~~Implicit~~ | **Deprecated** — do not use | Low |
| ~~ROPC~~ | **Deprecated** — do not use | Low |

### Authorization Code + PKCE — Implementation Steps
1. Generate `code_verifier` (random 43-128 chars) and `code_challenge` (SHA256 hash)
2. Redirect user to authorization server with `code_challenge`
3. Receive authorization code at callback URL
4. Exchange code + `code_verifier` for tokens at token endpoint
5. Validate ID token (if OIDC) and store tokens securely

## OpenID Connect (OIDC)

- Layer on top of OAuth2 for identity verification
- Use the ID token for authentication, access token for authorization
- Validate ID token signature, issuer, audience, and expiration
- Use the `userinfo` endpoint for additional profile claims
- Implement discovery via `.well-known/openid-configuration`
- Support standard scopes: `openid`, `profile`, `email`
