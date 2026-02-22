# Authentication & Authorization Reference

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
2. Receives access token with configured scopes
3. Use access token for API calls — no user context, machine-to-machine only
4. Prefer private_key_jwt over client_secret for higher assurance
5. Consider DPoP or mTLS to sender-constrain tokens

### Device Authorization (IoT/CLI) — RFC 8628
1. Device requests device_code + user_code from /device_authorization endpoint
2. Device displays user_code and verification_uri to user (or QR code)
3. User navigates to URI on separate device and authenticates
4. Device polls /token endpoint at specified interval until authorized or expired
5. Device receives access token + refresh token upon user approval

### On-Behalf-Of Flow (OBO) — RFC 8693 Token Exchange
- Service A receives token for user, wants to call Service B as that user
- Service A exchanges its access token for a new token scoped to Service B
- Used in Azure AD with service principal delegation chains

## OpenID Connect (OIDC)

- Identity layer on top of OAuth 2.0
- ID token (JWT) contains user identity claims: sub, name, email, picture, iat, exp, iss, aud, nonce
- UserInfo endpoint for additional profile data (requires access token)
- Discovery document at `/.well-known/openid-configuration` — auto-discovery of endpoints and keys
- JWKS endpoint for public key retrieval: `/.well-known/jwks.json`
- Standard scopes: `openid` (required), `profile`, `email`, `address`, `phone`, `offline_access`
- Validate nonce to prevent replay attacks in implicit/hybrid flows
- Validate `at_hash` claim in ID token to bind it to access token
- Use `acr_values` to request specific authentication context (MFA, step-up)
- Front-Channel Logout and Back-Channel Logout for SSO logout propagation

## OAuth 2.1 Key Changes

- PKCE required for all public AND confidential clients (not just public)
- Implicit grant type removed entirely (use Authorization Code + PKCE for SPAs)
- Resource Owner Password Credentials (ROPC) grant removed
- Refresh token rotation required for public clients
- Sender-constraining tokens (DPoP or mTLS) strongly recommended
- Redirect URI exact string matching required (no pattern matching)
- `response_type=token` removed from authorization endpoint

## DPoP (Demonstrating Proof of Possession) — RFC 9449

```
Client generates asymmetric keypair (ES256 or RS256)
For each request:
  1. Create DPoP proof JWT:
     Header: { typ: "dpop+jwt", alg: "ES256", jwk: <public key> }
     Payload: { jti: <unique>, htm: "POST", htu: "https://as.example/token", iat: <now> }
     Signed with private key
  2. Include in header: DPoP: <proof JWT>
Authorization server:
  - Binds issued access token to client's public key (cnf.jkt claim)
Resource server:
  - Validates DPoP proof on each request
  - Verifies token's cnf.jkt matches DPoP proof's JWK thumbprint
```

Benefits: Access token theft is useless without the private key. Stops bearer token attacks.

## PAR (Pushed Authorization Requests) — RFC 9126

```http
POST /par HTTP/1.1
Host: as.example.com
Content-Type: application/x-www-form-urlencoded

response_type=code
&client_id=s6BhdRkqt3
&redirect_uri=https://client.example.com/callback
&scope=openid%20profile
&state=af0ifjsldkj
&code_challenge=E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM
&code_challenge_method=S256

Response: { "request_uri": "urn:ietf:params:oauth:request_uri:xyz", "expires_in": 90 }

Client then redirects to:
GET /authorize?request_uri=urn:ietf:params:oauth:request_uri:xyz&client_id=s6BhdRkqt3
```

Benefits: Parameters not visible in browser history/referrer logs. Required for FAPI 2.0.

## JAR (JWT Secured Authorization Requests) — RFC 9101

- Authorization request parameters packed into a signed JWT (`request` parameter)
- Prevents parameter tampering in the redirect
- JWT signed by client, verified by authorization server
- Can be combined with PAR for maximum security

## FAPI 2.0 (Financial-grade API Security Profile)

- Baseline: OAuth 2.1 + PAR + PKCE + redirect URI exact matching
- Advanced: Add DPoP or mTLS sender-constraining + JAR + authorization_details (RAR)
- Required for Open Banking (UK, Brazil, Australia), PSD2 SCA compliance
- `authorization_details` parameter for fine-grained consent (specific accounts, limits)
- JARM (JWT Secured Authorization Response Mode) for signed/encrypted responses

## RAR (Rich Authorization Requests) — RFC 9396

```json
{
  "authorization_details": [
    {
      "type": "payment_initiation",
      "locations": ["https://example.com/payments"],
      "instructedAmount": { "currency": "EUR", "amount": "123.50" },
      "creditorName": "Merchant A",
      "creditorAccount": { "iban": "DE02100100109307118603" }
    }
  ]
}
```

Enables consent for specific resources/actions rather than broad scopes.

## CIBA (Client Initiated Backchannel Authentication)

- Decoupled flow: the device initiating authentication is separate from the authentication device
- Use cases: POS terminals, call centers, IoT, TV apps
- Client POSTs to /bc-authorize with login_hint (email/phone) or id_token_hint
- Authorization server notifies user's authenticator app (push notification)
- Token delivery modes: Poll (client polls), Ping (AS pings client callback), Push (AS pushes tokens)

## Verifiable Credentials and Decentralized Identity

### Decentralized Identifiers (DIDs)
- W3C standard: globally unique identifier controlled by the subject (not a registry)
- Format: `did:method:method-specific-id` (e.g., `did:web:example.com`, `did:key:z6Mk...`)
- DID Document: JSON-LD doc with public keys, service endpoints
- Methods: did:web (web-hosted), did:ion (Bitcoin-anchored), did:peer (P2P), did:ethr (Ethereum)

### Verifiable Credentials (VCs) — W3C Standard
- Tamper-evident credentials with cryptographic proof
- Credential: JSON-LD with issuer DID, subject DID, claims, proof
- Verifiable Presentation: holder bundles VCs to present to verifier
- Selective disclosure: ZKP-based (BBS+ signatures) or SD-JWT
- Use cases: digital identity documents, education credentials, age verification, professional licenses

### SD-JWT (Selective Disclosure JWT)
- Holder can selectively disclose individual claims
- Issuer includes hashed claims; holder reveals only chosen claims with disclosure values
- Suitable for mobile driver's licenses, health credentials, KYC without full disclosure

## Passkeys / WebAuthn Detailed Flows

### Registration Flow
```javascript
// 1. Server generates challenge
const options = await generateRegistrationOptions({
  rpName: "Example App",
  rpID: "example.com",
  userName: user.email,
  attestationType: "none", // or "direct", "indirect", "enterprise"
  authenticatorSelection: {
    residentKey: "required",  // enables passkey (discoverable credential)
    userVerification: "required",  // biometric or PIN
    authenticatorAttachment: "platform"  // or "cross-platform" for security keys
  }
});

// 2. Browser calls WebAuthn API
const credential = await navigator.credentials.create({ publicKey: options });

// 3. Server verifies and stores credential
// Stores: credentialID, publicKey, signCount, deviceType, transports
await verifyRegistrationResponse({ response: credential, expectedChallenge, expectedOrigin });
```

### Authentication Flow
```javascript
// 1. Server generates challenge (for conditional UI, allowCredentials can be empty)
const options = await generateAuthenticationOptions({
  rpID: "example.com",
  allowCredentials: [],  // empty = discoverable credential / passkey autofill
  userVerification: "required"
});

// 2. Conditional UI (passkey autofill in input field)
const credential = await navigator.credentials.get({
  publicKey: options,
  mediation: "conditional"  // enables autofill UI
});

// 3. Server verifies signature
await verifyAuthenticationResponse({ response: credential, expectedChallenge, authenticator });
```

### Passkey Syncing
- **iCloud Keychain**: Syncs passkeys across Apple devices (macOS, iOS, iPadOS) via E2EE iCloud
- **Google Password Manager**: Syncs across Android/Chrome; per-device export to adjacent devices
- **Windows Hello**: Device-bound by default; Microsoft account sync in progress
- **1Password / Bitwarden / Dashlane**: Cross-platform passkey sync via password manager vault
- **CTAP2.2 Hybrid Transport**: Cross-device auth — scan QR code on desktop, authenticate on phone via BLE proximity check

### Security Considerations
- Passkeys are phishing-resistant: cryptographically bound to the relying party origin
- `rpID` must be the effective domain — prevents subdomain abuse
- `signCount` increment validation — detect cloned authenticators (optional for synced passkeys)
- Backup eligibility + backup state flags in authenticatorData — know if passkey is synced
- Store multiple credentials per user (different devices)
- Provide fallback: email magic link or SMS OTP for account recovery

## Identity Provider Integration Patterns

### Auth0
```javascript
// Next.js integration with Auth0 SDK
import { withApiAuthRequired, getSession } from '@auth0/nextjs-auth0';

// Actions (formerly Rules) for custom claims
exports.onExecutePostLogin = async (event, api) => {
  api.idToken.setCustomClaim('https://myapp.com/roles', event.user.app_metadata.roles);
  api.accessToken.setCustomClaim('https://myapp.com/permissions', event.user.app_metadata.permissions);
};
```

### Keycloak
- Realm: isolated auth domain with own users, clients, and policies
- Client: application registered in realm with specific grant types
- Client Scopes: reusable scope configurations mapped to claims
- User Federation: LDAP/AD sync, custom user storage providers
- Fine-grained Authorization: resource server, policies (role, time, JS, aggregate), permissions
- Themes: FreeMarker templates for login UI customization
- Events: login, admin, token exchange events via SPI or webhook

### Okta
- Application types: SPA (PKCE), Web (client secret), Machine (client credentials), Native
- Authorization Server: custom domain, custom scopes, custom claims, access policies
- Groups and Mappings: AD group sync, group rules, profile mappings
- Inline Hooks: synchronous external call during authentication flows
- Event Hooks: async webhook for events (user.session.start, user.account.update)

### Clerk
```javascript
// Next.js App Router integration
import { auth, currentUser } from '@clerk/nextjs';

export default async function Page() {
  const { userId, orgId, orgRole } = auth();
  const user = await currentUser();
  // Clerk provides UserButton, SignIn, SignUp, OrganizationSwitcher components
}
// Webhooks for user.created, user.updated, session.created events
// Organizations for multi-tenancy with roles and permissions
```

### Ory Stack
- **Ory Kratos**: Self-service flows (registration, login, recovery, verification, settings) via REST API
- **Ory Hydra**: OAuth2/OIDC authorization server, integrates with any identity provider
- **Ory Oathkeeper**: Identity and access proxy, decision API, JWT transformation rules
- **Ory Keto**: Permission and authorization service based on Google Zanzibar

### WorkOS
- Enterprise SSO (SAML, OIDC): one integration covers all IdPs
- Directory Sync (SCIM): user/group provisioning from Okta/Azure AD/Google
- Admin Portal: self-service SSO configuration for enterprise customers
- Audit Log: structured event stream for compliance, forward to SIEM

## Multi-Factor Authentication (MFA)

### Authenticator Options (strongest to weakest)
1. **Passkeys/FIDO2 hardware keys**: YubiKey 5, Google Titan — phishing-resistant, strongest
2. **Platform passkeys**: Touch ID, Face ID, Windows Hello — phishing-resistant, convenient
3. **TOTP (OATH-HOTP/TOTP)**: Google Authenticator, Authy, 1Password, Bitwarden — most common
4. **Push notifications**: Okta Verify, Duo, Microsoft Authenticator — vulnerable to MFA fatigue
5. **SMS/Email OTP**: Fallback only — SIM swapping, SS7 attacks, phishing risk
6. **Recovery codes**: Generate 10-16 one-time codes at MFA setup, store hashed (bcrypt/Argon2)

### MFA Fatigue Prevention
- Number matching: user must enter the number displayed in app, not just approve
- Additional context in push: show IP address, geolocation, device in notification
- Rate limit MFA push requests
- Alert on excessive MFA push requests

## Session Security

- Use cryptographically random session IDs: 128+ bits from CSPRNG (crypto.randomBytes, secrets.token_urlsafe)
- Store sessions server-side: Redis with encrypted payload, database
- Set cookie attributes: `Secure; HttpOnly; SameSite=Lax; Path=/; Max-Age=86400`
- Rotate session ID on login, role change, privilege escalation
- Implement absolute timeout (24h) and idle timeout (30min)
- Device fingerprinting as supplementary signal (not sole authentication factor)
- Concurrent session management: limit sessions per user, show active sessions, allow revocation
- Re-authentication for sensitive operations (payment, email change, 2FA setup)

## API Key Security

- Prefix keys for identification and scanning: `sk_live_`, `pk_test_`, `whsec_` (webhook secret)
- Hash for storage: SHA-256 with salt, show full key only on creation
- Implement scoping: read-only, write, admin, per-resource, per-endpoint
- Rate limit per API key with differentiated tiers
- Support key rotation without downtime: accept multiple valid keys during transition
- API key metadata: name, created date, last used, IP restrictions, expiry
- Audit log all API key operations: creation, rotation, deletion, excessive failed auth

## Token Binding and Sender-Constraining

### mTLS-Constrained Tokens (RFC 8705)
- Client presents TLS client certificate; server extracts certificate thumbprint
- Token includes `cnf.x5t#S256` claim binding it to the certificate
- Resource server verifies token's certificate claim matches presented certificate
- Supported by Azure AD, many Open Banking implementations

### DPoP vs mTLS Comparison
| Aspect | DPoP | mTLS |
|--------|------|------|
| Setup complexity | Lower (no PKI needed) | Higher (certificate management) |
| Transport | Application layer | TLS layer |
| Revocation | JWT expiry | Certificate revocation (CRL/OCSP) |
| Intermediary support | Works through proxies | May need TLS passthrough |
| Browser support | Native JavaScript | Requires special handling |
