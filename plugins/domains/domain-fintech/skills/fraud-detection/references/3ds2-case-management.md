# 3DS2, Case Management, and Chargeback Prevention

## When to load
Load when implementing 3-D Secure 2.0 authentication flows, building fraud analyst review queues,
or designing chargeback prevention and dispute resolution workflows.

## 3DS2 (3-D Secure 2.0)

### Frictionless vs Challenge Flow
- Frictionless: issuer approves based on risk assessment (no user interaction)
- Challenge: additional authentication required (OTP, biometric, app approval)
- Send rich data to issuer for better risk assessment (device, behavior, history)
- Optimize for frictionless approval rate while maintaining security

### Implementation
- Integrate via payment processor SDK (Stripe 3DS, Adyen 3DS2)
- Collect browser data for device fingerprinting (3DS Method)
- Handle authentication response: Y (authenticated), N (not authenticated), A (attempted), U (unavailable)
- Liability shift: successful 3DS shifts chargeback liability to issuer

## Case Management

### Review Workflow
- Queue management: prioritize by risk score, amount, SLA deadline
- Analyst workspace: transaction details, customer history, device info, linked accounts
- Decision options: approve, block, escalate, request information
- Decision documentation: mandatory reason code and free-text notes
- Four-eyes principle: high-value cases require independent second review

### Feedback Loop
Case outcomes (confirmed fraud vs false positive) feed into:
- Rule threshold tuning
- ML model retraining datasets
- Customer risk profile updates
- Device reputation database

## Chargeback Prevention

- Compelling evidence collection: delivery proof, IP logs, device fingerprint, 3DS result
- Descriptor clarity: ensure statement descriptor matches what customer expects
- Pre-dispute alerts: Verifi CDRN, Ethoca alerts for early resolution
- Refund automation: auto-refund for known dispute patterns when cheaper than fighting
- Chargeback ratio monitoring: stay below card network thresholds (Visa: 0.9%, Mastercard: 1.0%)
