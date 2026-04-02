---
name: banking-apis
description: "Guides banking API integration: Open Banking standards (PSD2, UK Open Banking, FDX), Plaid integration (Link, transactions, balance, identity), account aggregation, payment initiation (PISP), account information (AISP), BaaS platforms (Unit, Synapse, Column), and API security (mTLS, OAuth2, FAPI). Use when integrating with banking services, implementing Open Banking compliance, or securing financial API connections."
allowed-tools: Read, Grep, Glob, Bash
---

# Banking APIs

## When to use
- Integrating with PSD2, UK Open Banking, or FDX APIs
- Setting up Plaid Link, transaction sync, or webhook processing
- Implementing payment initiation (ACH, SEPA, Faster Payments)
- Choosing or evaluating a BaaS provider (Unit, Column)
- Securing bank API connections with mTLS, OAuth2, or FAPI
- Building account aggregation with multi-provider fallback

## Core principles
1. **Never expose access tokens client-side** — exchange public_token server-side, store encrypted
2. **Idempotent webhook processing** — banking events are delivered at-least-once; deduplicate always
3. **Consent is time-limited and revocable** — model consent lifecycle explicitly, not as a boolean flag
4. **Multi-provider normalization** — abstract provider differences behind a unified internal schema
5. **FAPI > plain OAuth2** — financial-grade APIs require sender-constrained tokens and signed requests

## Workflow

### Step 1: Identify integration type
Determine the banking integration pattern needed:
- **AISP** (Account Information): Read-only access to accounts, balances, transactions
- **PISP** (Payment Initiation): Initiate payments on behalf of the user
- **BaaS** (Banking-as-a-Service): Embed banking features via platforms like Unit or Column

### Step 2: Implement secure token exchange
```
# Server-side Plaid token exchange (never client-side)
POST /api/plaid/exchange
  Body: { public_token: "public-sandbox-..." }
  → Exchange for access_token
  → Encrypt and store access_token in vault
  → Return item_id to client (not the token)
```

### Step 3: Set up idempotent webhook processing
```
# Webhook deduplication pattern
1. Receive webhook with webhook_id
2. Check idempotency store: IF webhook_id EXISTS → return 200 (skip)
3. Process webhook payload
4. Store webhook_id with TTL (e.g., 7 days)
5. Return 200
```

### Step 4: Validate and go live
- Verify consent lifecycle handles expiry and revocation
- Confirm multi-provider normalization maps all fields
- Test FAPI sender-constrained token flow end-to-end

## Reference Files
- `references/open-banking-standards.md` — PSD2 (Berlin Group, STET, PolishAPI), UK Open Banking, FDX, AISP consent management and data categories
- `references/plaid-integration.md` — Plaid Link flow, core products (transactions, balance, identity, auth), webhook handling, multi-provider aggregation patterns
- `references/payment-initiation.md` — payment types (ACH, SEPA, Faster Payments), ACH origination, payment status lifecycle, BaaS platform selection (Unit, Column)
- `references/api-security.md` — mTLS with eIDAS QWAC, OAuth 2.0 flows for banking, FAPI 1.0 Advanced requirements (JARM, PAR, DPoP, sender-constrained tokens)
