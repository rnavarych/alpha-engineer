---
name: domain-fintech:banking-apis
description: Guides banking API integration: Open Banking standards (PSD2, UK Open Banking, FDX), Plaid integration (Link, transactions, balance, identity), account aggregation, payment initiation (PISP), account information (AISP), BaaS platforms (Unit, Synapse, Column), and API security (mTLS, OAuth2, FAPI). Use when integrating with banking services.
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

## Reference Files
- `references/open-banking-standards.md` — PSD2 (Berlin Group, STET, PolishAPI), UK Open Banking, FDX, AISP consent management and data categories
- `references/plaid-integration.md` — Plaid Link flow, core products (transactions, balance, identity, auth), webhook handling, multi-provider aggregation patterns
- `references/payment-initiation.md` — payment types (ACH, SEPA, Faster Payments), ACH origination, payment status lifecycle, BaaS platform selection (Unit, Column)
- `references/api-security.md` — mTLS with eIDAS QWAC, OAuth 2.0 flows for banking, FAPI 1.0 Advanced requirements (JARM, PAR, DPoP, sender-constrained tokens)
