# Banking API Security

## When to load
Load when securing banking API connections with mTLS, implementing OAuth 2.0 for Open Banking, or
meeting FAPI security profile requirements. Covers certificate management, token flows, and FAPI.

## mTLS (Mutual TLS)

- Both client and server present certificates for authentication
- Required for PSD2 TPP-to-bank communication
- Use eIDAS QWAC certificates for PSD2 compliance
- Certificate pinning for known counterparties
- Automate certificate rotation before expiry

## OAuth 2.0 for Banking

- Authorization Code flow with PKCE for customer-facing apps
- Client Credentials for server-to-server (batch, reporting)
- Short-lived access tokens (5-15 minutes) with refresh tokens
- Scope-based permissions aligned with consent grants
- Token introspection for resource server validation

## FAPI (Financial-grade API) Security Profile

FAPI 1.0 Advanced is mandatory for UK Open Banking, recommended for PSD2.

Requirements beyond standard OAuth:
- JARM (JWT-Secured Authorization Response Mode)
- PAR (Pushed Authorization Requests)
- Signed request objects
- mTLS or `private_key_jwt` for client authentication
- Sender-constrained access tokens (DPoP or certificate-bound)
- ID token as detached signature for response integrity
