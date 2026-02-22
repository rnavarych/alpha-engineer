---
name: banking-apis
description: |
  Guides banking API integration: Open Banking standards (PSD2, UK Open Banking, FDX),
  Plaid integration (Link, transactions, balance, identity), account aggregation,
  payment initiation (PISP), account information (AISP), BaaS platforms (Unit, Synapse,
  Column), and API security (mTLS, OAuth2, FAPI). Use when integrating with banking services.
allowed-tools: Read, Grep, Glob, Bash
---

You are a banking API integration specialist. Every integration must handle security, error handling, and data consistency rigorously.

## Open Banking Standards

### PSD2 APIs (Europe)
- **Berlin Group NextGenPSD2**: most widely adopted in continental Europe
  - Account Information: GET /v1/accounts, GET /v1/accounts/{id}/transactions
  - Payment Initiation: POST /v1/payments/{payment-product}
  - Consent management: POST /v1/consents with access scope and validity period
- **STET**: French banking standard, similar scope to Berlin Group
- **Polish API (PolishAPI)**: KIR-managed standard for Polish banks
- Versioning: support multiple API versions during transition periods

### UK Open Banking
- CMA-mandated standard for the CMA9 (nine largest UK banks)
- Account and Transaction API: GET /accounts, GET /accounts/{id}/transactions
- Payment Initiation API: POST /domestic-payments, POST /international-payments
- Confirmation of Funds API: POST /funds-confirmations
- Dynamic Client Registration for TPP onboarding
- Uses FAPI (Financial-grade API) security profile

### FDX (Financial Data Exchange) - North America
- Successor to screen scraping for US/Canada financial data
- Core API: accounts, transactions, statements, tax documents
- Consent management with granular data sharing permissions
- API certification program for data providers and recipients
- Transitioning from Plaid/Yodlee screen scraping to tokenized API access

## Plaid Integration

### Plaid Link
- Client-side component for bank account connection
- Handles institution selection, credential input, MFA challenges
- Returns a public_token; exchange for access_token server-side
- Never expose access_token to the client
```
Client: Plaid Link -> public_token
Server: POST /item/public_token/exchange -> access_token (store encrypted)
```

### Core Plaid Products
- **Transactions**: GET /transactions/sync (webhook-based incremental sync)
  - Historical data: up to 24 months
  - Categorization: Plaid's ML-based transaction categorization
  - Sync cursor pattern: track last sync position for incremental updates
- **Balance**: GET /accounts/balance/get (real-time balance check)
  - Available balance vs current balance distinction
  - Rate limits apply: cache balances with appropriate TTL
- **Identity**: GET /identity/get (account holder name, address, email, phone)
  - Use for KYC identity verification
  - Match against user-provided information
- **Auth**: GET /auth/get (account and routing numbers for ACH)
  - Micro-deposit verification alternative
  - Instant account verification where supported

### Plaid Webhook Handling
- TRANSACTIONS: SYNC_UPDATES_AVAILABLE, DEFAULT_UPDATE
- ITEM: ERROR, PENDING_EXPIRATION, USER_PERMISSION_REVOKED
- Verify webhook signatures using Plaid's public key
- Idempotent webhook processing (webhooks may be delivered multiple times)

## Account Aggregation Patterns

### Data Synchronization
- Initial sync: fetch full transaction history (paginated)
- Incremental sync: use cursors or timestamps for delta updates
- Conflict resolution: provider data is source of truth
- Stale data handling: display "last updated" timestamp to users

### Multi-Provider Strategy
- Primary: Plaid for US/Canada
- Europe: Tink, TrueLayer, or direct bank API integration
- Fallback: secondary provider for institutions not covered by primary
- Unified data model: normalize across providers into internal schema

### Error Handling
- Institution downtime: queue retries with exponential backoff
- Credential expiration: prompt user to re-authenticate via Link
- Rate limiting: implement client-side rate limiter per provider
- Partial failures: process available data, flag missing institutions

## Payment Initiation (PISP)

### Payment Types
- **Domestic**: ACH (US), Faster Payments (UK), SEPA Credit Transfer (EU)
- **International**: SWIFT, SEPA Cross-Border
- **Instant**: SEPA Instant, Faster Payments, RTP (US)
- **Scheduled**: future-dated payments with cancellation support
- **Standing Orders**: recurring payments with fixed amount and frequency

### ACH Integration (US)
- Origination: submit NACHA files to ODFI (Originating Depository Financial Institution)
- Settlement: T+1 for same-day ACH, T+2 for standard ACH
- Return codes: R01 (insufficient funds), R02 (account closed), R10 (unauthorized)
- Prenote: zero-dollar test transaction to verify account before real payment
- Use Modern Treasury, Dwolla, or bank API for ACH origination

### Payment Status Tracking
```
INITIATED -> PENDING -> PROCESSING -> SETTLED -> COMPLETED
                            |
                            v
                         FAILED -> RETRY (if retryable) or RETURNED
```

## Account Information (AISP)

### Consent Management
- Granular consent: specify which accounts and data types to access
- Time-limited: consent expires after specified duration (max 90 days for PSD2)
- Revocable: customer can revoke consent at any time
- Consent receipts: provide customer with record of granted permissions
- Re-authentication: required when consent expires or for sensitive operations

### Data Categories
- Account details: account number, type, currency, status
- Balances: available, current, pending, credit line
- Transactions: date, amount, currency, merchant, category, status
- Beneficiaries: saved payee details
- Direct debits and standing orders

## BaaS (Banking as a Service) Platforms

### Unit
- Full-stack banking platform: accounts, cards, payments, lending
- FDIC-insured accounts via partner banks
- API-first: RESTful APIs with webhooks for event notifications
- Features: ACH, wire, card issuing (Visa/Mastercard), check deposits

### Column (formerly Synapse successor)
- Direct bank charter partnership model
- Real-time ledger with double-entry bookkeeping
- ACH origination, wire transfers, card issuing
- Compliance tools: KYC/AML, transaction monitoring

### Choosing a BaaS Provider
- Evaluate: bank partner stability, regulatory coverage, API maturity
- Understand: who holds the banking license and regulatory liability
- Check: historical uptime, incident response, data portability
- Consider: vendor lock-in risk, exit strategy, data ownership

## API Security

### mTLS (Mutual TLS)
- Both client and server present certificates for authentication
- Required for PSD2 TPP-to-bank communication
- Use eIDAS QWAC certificates for PSD2 compliance
- Certificate pinning for known counterparties
- Automate certificate rotation before expiry

### OAuth 2.0 for Banking
- Authorization Code flow with PKCE for customer-facing apps
- Client Credentials for server-to-server (batch, reporting)
- Short-lived access tokens (5-15 minutes) with refresh tokens
- Scope-based permissions aligned with consent grants
- Token introspection for resource server validation

### FAPI (Financial-grade API) Security Profile
- FAPI 1.0 Advanced: mandatory for UK Open Banking, recommended for PSD2
- Requirements beyond standard OAuth: JARM, PAR, signed request objects
- MTLS or private_key_jwt for client authentication
- Sender-constrained access tokens (DPoP or certificate-bound)
- ID token as detached signature for response integrity
