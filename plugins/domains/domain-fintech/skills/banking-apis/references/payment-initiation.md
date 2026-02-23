# Payment Initiation

## When to load
Load when implementing PISP flows, ACH origination, SEPA payments, or tracking payment status.
Covers payment types, ACH integration, BaaS platforms, and status lifecycle.

## Payment Types

- **Domestic**: ACH (US), Faster Payments (UK), SEPA Credit Transfer (EU)
- **International**: SWIFT, SEPA Cross-Border
- **Instant**: SEPA Instant, Faster Payments, RTP (US)
- **Scheduled**: future-dated payments with cancellation support
- **Standing Orders**: recurring payments with fixed amount and frequency

## ACH Integration (US)

- Origination: submit NACHA files to ODFI (Originating Depository Financial Institution)
- Settlement: T+1 for same-day ACH, T+2 for standard ACH
- Return codes: R01 (insufficient funds), R02 (account closed), R10 (unauthorized)
- Prenote: zero-dollar test transaction to verify account before real payment
- Use Modern Treasury, Dwolla, or bank API for ACH origination

## Payment Status Lifecycle

```
INITIATED -> PENDING -> PROCESSING -> SETTLED -> COMPLETED
                            |
                            v
                         FAILED -> RETRY (if retryable) or RETURNED
```

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
