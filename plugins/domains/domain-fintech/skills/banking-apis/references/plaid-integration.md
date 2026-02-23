# Plaid Integration

## When to load
Load when integrating Plaid Link, syncing transactions, checking balances, verifying identity, or
handling Plaid webhooks. Covers all core Plaid products and webhook processing patterns.

## Plaid Link

Client-side component for bank account connection. Handles institution selection, credential input,
MFA challenges. Returns a `public_token`; exchange for `access_token` server-side. Never expose
`access_token` to the client.

```
Client: Plaid Link -> public_token
Server: POST /item/public_token/exchange -> access_token (store encrypted)
```

## Core Plaid Products

### Transactions
- `GET /transactions/sync` (webhook-based incremental sync)
- Historical data: up to 24 months
- Categorization: Plaid's ML-based transaction categorization
- Sync cursor pattern: track last sync position for incremental updates

### Balance
- `GET /accounts/balance/get` (real-time balance check)
- Available balance vs current balance distinction
- Rate limits apply: cache balances with appropriate TTL

### Identity
- `GET /identity/get` (account holder name, address, email, phone)
- Use for KYC identity verification
- Match against user-provided information

### Auth
- `GET /auth/get` (account and routing numbers for ACH)
- Micro-deposit verification alternative
- Instant account verification where supported

## Plaid Webhook Handling

Event types:
- `TRANSACTIONS: SYNC_UPDATES_AVAILABLE, DEFAULT_UPDATE`
- `ITEM: ERROR, PENDING_EXPIRATION, USER_PERMISSION_REVOKED`

Processing rules:
- Verify webhook signatures using Plaid's public key
- Idempotent webhook processing — webhooks may be delivered multiple times

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
