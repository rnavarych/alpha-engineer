# OAuth, OIDC, and Advanced Auth Flows

## When to load
Load when implementing OAuth 2.0/2.1 flows, OIDC integration, DPoP, PAR, FAPI, CIBA, or decentralized identity (DIDs, Verifiable Credentials).

## OAuth 2.0 Flows

### Authorization Code + PKCE (Recommended for SPAs/Mobile)
1. Client generates `code_verifier` (43-128 char random string) + `code_challenge` = BASE64URL(SHA256(code_verifier))
2. Redirect to authorization server with `code_challenge` and `code_challenge_method=S256`
3. User authenticates, authorization server returns auth code to redirect URI
4. Client exchanges auth code + `code_verifier` for tokens (POST /token)
5. Use short-lived access token for API calls, refresh token for renewal
6. Rotate refresh tokens on each use (refresh token rotation)

### Client Credentials (Service-to-Service)
1. Service sends `client_id` + `client_secret` (or private_key_jwt assertion) to /token endpoint
2. Receives access token with configured scopes — no user context, machine-to-machine only
3. Prefer private_key_jwt over client_secret for higher assurance
4. Consider DPoP or mTLS to sender-constrain tokens

### Device Authorization (IoT/CLI) — RFC 8628
1. Device requests device_code + user_code from /device_authorization endpoint
2. Device displays user_code and verification_uri to user (or QR code)
3. User navigates to URI on separate device and authenticates
4. Device polls /token endpoint at specified interval until authorized or expired

### On-Behalf-Of Flow (OBO) — RFC 8693 Token Exchange
- Service A exchanges its access token for a new token scoped to Service B
- Used in Azure AD with service principal delegation chains

## OpenID Connect (OIDC)
- Identity layer on top of OAuth 2.0
- ID token (JWT) contains: sub, name, email, picture, iat, exp, iss, aud, nonce
- Discovery at `/.well-known/openid-configuration`; JWKS at `/.well-known/jwks.json`
- Standard scopes: `openid` (required), `profile`, `email`, `offline_access`
- Validate nonce to prevent replay attacks; validate `at_hash` to bind ID token to access token
- Use `acr_values` for step-up auth; Front-Channel and Back-Channel Logout for SSO

## OAuth 2.1 Key Changes
- PKCE required for all public AND confidential clients
- Implicit grant type removed; ROPC grant removed
- Refresh token rotation required for public clients; sender-constraining strongly recommended

## DPoP (Demonstrating Proof of Possession) — RFC 9449
```
Client generates asymmetric keypair (ES256 or RS256)
For each request:
  1. Create DPoP proof JWT:
     Header: { typ: "dpop+jwt", alg: "ES256", jwk: <public key> }
     Payload: { jti: <unique>, htm: "POST", htu: "https://as.example/token", iat: <now> }
     Signed with private key
  2. Include in header: DPoP: <proof JWT>
Authorization server binds token to client's public key (cnf.jkt claim)
Resource server validates DPoP proof on each request
```
Benefits: Access token theft is useless without the private key.

## PAR (Pushed Authorization Requests) — RFC 9126
Client POSTs authorization params to /par endpoint → receives `request_uri` → uses it in authorization redirect. Parameters not exposed in URL/browser history. Required for FAPI 2.0.

## FAPI 2.0 and RAR
- **FAPI 2.0**: OAuth 2.1 + PAR + DPoP or mTLS + JAR; required for Open Banking, PSD2 SCA
- **RAR (Rich Authorization Requests)**: Fine-grained consent via `authorization_details` parameter for specific resources (account IDs, transaction limits)

## CIBA (Client Initiated Backchannel Authentication)
- Decoupled flow: device initiating auth is separate from the authentication device
- Use cases: POS terminals, call centers, IoT, TV apps
- Token delivery: Poll (client polls), Ping (AS pings callback), Push (AS pushes tokens)

## Verifiable Credentials and Decentralized Identity
- **DIDs**: W3C standard, `did:method:id` format (did:web, did:ion, did:peer)
- **Verifiable Credentials (VCs)**: Tamper-evident JSON-LD with cryptographic proof; selective disclosure via ZKP (BBS+) or SD-JWT
- **SD-JWT**: Holder selectively discloses individual claims — suitable for mobile driver's licenses, KYC
