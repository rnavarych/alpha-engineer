# Authentication & Authorization Reference

## OAuth 2.0 Flows

### Authorization Code + PKCE (Recommended for SPAs/Mobile)
1. Client generates code_verifier + code_challenge
2. Redirect to authorization server with code_challenge
3. User authenticates, authorization server returns auth code
4. Client exchanges auth code + code_verifier for tokens
5. Use access token for API calls

### Client Credentials (Service-to-Service)
1. Service sends client_id + client_secret to token endpoint
2. Receives access token
3. Use access token for API calls
4. No user context — machine-to-machine only

### Device Authorization (IoT/CLI)
1. Device requests device code + user code
2. User enters user code at verification URL
3. Device polls token endpoint until authorized

## OpenID Connect (OIDC)
- Identity layer on top of OAuth 2.0
- ID token (JWT) contains user identity claims
- UserInfo endpoint for additional profile data
- Discovery document at `/.well-known/openid-configuration`

## Multi-Factor Authentication (MFA)
- TOTP (Google Authenticator, Authy) — most common
- WebAuthn/FIDO2 (hardware keys, biometrics) — most secure
- SMS OTP — least secure (SIM swap attacks), use as fallback only
- Recovery codes — generate on MFA setup, store hashed

## Session Security
- Use cryptographically random session IDs (128+ bits entropy)
- Store sessions server-side (Redis, database)
- Set cookie flags: `Secure; HttpOnly; SameSite=Lax; Path=/`
- Rotate session ID on privilege change (login, role change)
- Implement absolute timeout (24h) and idle timeout (30min)

## API Key Security
- Prefix keys for identification (e.g., `sk_live_`, `pk_test_`)
- Hash keys for storage (SHA-256), show only on creation
- Implement scoping (read-only, admin, per-resource)
- Rate limit per key
- Support key rotation without downtime
