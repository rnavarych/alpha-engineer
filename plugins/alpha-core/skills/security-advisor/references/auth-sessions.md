# Passkeys, MFA, Sessions, and IdP Integration Patterns

## When to load
Load when implementing passkeys/WebAuthn, MFA flows, session security, API key management, or integrating with specific identity providers (Auth0, Keycloak, Okta, Clerk, Ory, WorkOS).

## Passkeys / WebAuthn Detailed Flows

### Registration Flow
```javascript
// 1. Server generates challenge
const options = await generateRegistrationOptions({
  rpName: "Example App", rpID: "example.com", userName: user.email,
  attestationType: "none",
  authenticatorSelection: {
    residentKey: "required",       // enables passkey (discoverable credential)
    userVerification: "required",  // biometric or PIN
    authenticatorAttachment: "platform"
  }
});
// 2. Browser calls WebAuthn API
const credential = await navigator.credentials.create({ publicKey: options });
// 3. Server verifies and stores: credentialID, publicKey, signCount, deviceType, transports
await verifyRegistrationResponse({ response: credential, expectedChallenge, expectedOrigin });
```

### Authentication Flow
```javascript
const options = await generateAuthenticationOptions({
  rpID: "example.com", allowCredentials: [],  // empty = discoverable passkey autofill
  userVerification: "required"
});
const credential = await navigator.credentials.get({ publicKey: options, mediation: "conditional" });
await verifyAuthenticationResponse({ response: credential, expectedChallenge, authenticator });
```

### Passkey Syncing and Security
- iCloud Keychain, Google Password Manager, Windows Hello, 1Password — cross-platform
- CTAP2.2 Hybrid Transport: scan QR on desktop, authenticate on phone via BLE
- `rpID` cryptographically bound to origin — prevents subdomain abuse and phishing
- Store multiple credentials per user (different devices); provide fallback for recovery

## Multi-Factor Authentication (MFA)

### Authenticator Options (strongest to weakest)
1. **Passkeys/FIDO2 hardware keys**: YubiKey 5, Google Titan — phishing-resistant, strongest
2. **Platform passkeys**: Touch ID, Face ID, Windows Hello — phishing-resistant, convenient
3. **TOTP**: Google Authenticator, Authy, 1Password, Bitwarden — most common
4. **Push notifications**: Okta Verify, Duo — vulnerable to MFA fatigue attacks
5. **SMS/Email OTP**: Fallback only — SIM swapping, SS7 attacks, phishing risk

### MFA Fatigue Prevention
- Number matching: user must enter the number displayed in app
- Additional context in push: show IP, geolocation, device
- Rate limit MFA push requests; alert on excessive push activity

## Session Security
- Cryptographically random session IDs: 128+ bits from CSPRNG
- Store sessions server-side: Redis with encrypted payload or database
- Cookie attributes: `Secure; HttpOnly; SameSite=Lax; Path=/; Max-Age=86400`
- Rotate session ID on login, role change, privilege escalation
- Absolute timeout (24h) and idle timeout (30min)
- Re-authentication for sensitive operations (payment, email change, 2FA setup)

## API Key Security
- Prefix keys for identification: `sk_live_`, `pk_test_`, `whsec_`
- Hash for storage: SHA-256 with salt; show full key only on creation
- Implement scoping: read-only, write, admin, per-resource
- Rate limit per API key with differentiated tiers
- Support key rotation without downtime: accept multiple valid keys during transition
- Audit log all API key operations: creation, rotation, deletion, failed auth

## IdP Integration Patterns

### Auth0
```javascript
// Actions for custom claims
exports.onExecutePostLogin = async (event, api) => {
  api.idToken.setCustomClaim('https://myapp.com/roles', event.user.app_metadata.roles);
  api.accessToken.setCustomClaim('https://myapp.com/permissions', event.user.app_metadata.permissions);
};
```

### Keycloak
- Realm: isolated auth domain; Client: application with specific grant types
- Fine-grained Authorization: resource server, policies (role, time, JS, aggregate), permissions
- User Federation: LDAP/AD sync; Themes: FreeMarker templates for login UI

### Clerk (Next.js App Router)
```javascript
import { auth, currentUser } from '@clerk/nextjs';
export default async function Page() {
  const { userId, orgId, orgRole } = auth();
  // Webhooks for user.created, session.created; Organizations for multi-tenancy
}
```

### Ory Stack
- **Ory Kratos**: Self-service flows (registration, login, recovery, verification)
- **Ory Hydra**: OAuth2/OIDC authorization server
- **Ory Keto**: Permission service based on Google Zanzibar

### WorkOS
- Enterprise SSO (SAML, OIDC): one integration covers all IdPs
- Directory Sync (SCIM): user/group provisioning from Okta/Azure AD/Google
- Admin Portal: self-service SSO config for enterprise customers
