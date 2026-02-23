# Fraud Prevention, 3DS2, Security, and Reliability

## When to load
Load when implementing 3DS2/SCA, fraud prevention tools, subscription billing, refunds, chargebacks, multi-currency, or idempotency patterns.

## 3D Secure 2 (3DS2) and SCA

### PSD2 / SCA Compliance
- Strong Customer Authentication required for EU/UK online card payments.
- Frictionless flow: issuer authenticates via risk signals without customer interruption.
- Challenge flow: customer completes OTP, banking app approval, or biometric.
- Liability shift: successful 3DS authentication moves fraud liability to issuer.

### Data Enrichment for Frictionless Rate
- Browser data: user agent, screen dimensions, timezone, language, Java/JS enabled.
- Device data: IP address, device fingerprint, account age, purchase history.
- More data = higher frictionless approval rate. Use 3DS SDKs from gateway or orchestrator.

### Exemptions
- Low-value under 30 EUR (cumulative limits apply).
- Merchant-initiated transactions (MIT): recurring subscriptions, merchant-triggered.
- Trusted beneficiaries: customer allowlists merchant with issuer.
- Transaction Risk Analysis (TRA): low-fraud merchants can request exemption up to 500 EUR.
- Secure corporate payments with dedicated corporate cards.

## Fraud Prevention

### Gateway-Native Tools
- Stripe Radar: ML-based scoring, custom rules (block/review/allow per risk level).
- Adyen RevenueProtect: risk rules, device fingerprinting, velocity checks.
- PayPal Seller Protection: automatic coverage for eligible transactions.

### Third-Party Tools
- **Sift**: real-time ML for payments, account takeover, content abuse. Review queue automation.
- **Riskified**: guaranteed protection (chargeback liability shifts to Riskified on approved fraud).
- **Signifyd**: guaranteed fraud decisions + chargeback recovery.
- **Forter**: real-time decisioning across account, payment, and return journey.
- Integration: pre-auth (block before charge) or post-auth (review and void if fraudulent).

### Fraud Best Practices
- AVS: match billing address with issuer. CVV required for every CNP transaction.
- Velocity checks: flag multiple failed attempts, unusual amounts, rapid successive orders.
- Device fingerprinting, IP geolocation, email risk scoring (domain age, disposable addresses, breach DBs).
- Shipping-billing mismatch, proxy/VPN detection.
- Manual review queue for high-value, first-time, or flagged international orders.

## Subscription Billing

### Recurring Models
- Fixed recurring, metered/usage-based, per-seat, tiered, hybrid (base + overage).

### Lifecycle Management
- Trial periods with automatic conversion. Plan upgrades/downgrades with proration.
- Dunning: retry schedule (day 0, 1, 3, 5, 7, 14), customer notifications, grace periods.
- Cancellation: immediate vs. end-of-period; collect reason; offer win-back.
- Pause: skip cycles or pause for a period with auto-resume.
- Platforms: Stripe Billing, Chargebee, Recurly, Paddle (merchant of record), or custom.

## Refunds and Disputes

### Refund Processing
- Full or partial refunds via gateway API. Track refund reasons.
- Refund to original method or store credit. Timing: card 5-10 days, BNPL varies, ACH 3-5 days.
- Multi-tender refunds: refund to the correct method when order used multiple payment types.

### Chargeback Management
- Submit evidence: tracking numbers, communication logs, refund policy.
- Clear billing descriptors prevent "I don't recognize this charge" disputes.
- Chargeback alert services (Verifi, Ethoca): notified before dispute becomes chargeback.
- Visa CE 3.0: submit prior transaction evidence against fraud chargebacks.
- Monitor thresholds: Visa 0.9%, Mastercard 1.0% — exceed and enter monitoring programs.

## Multi-Currency
- Present prices in customer's local currency (IP geolocation or preference).
- Gateway automatic conversion or self-managed exchange rates.
- Minimum charge amounts per currency (Stripe: ~50 cents USD equivalent).
- Multi-currency pricing: explicit prices per currency preferred over auto-convert.
- Dynamic Currency Conversion (DCC): let international cardholders pay in home currency.
- Multi-region merchant accounts settle in local currency to reduce FX costs.

## Idempotency and Reliability
- `Idempotency-Key` on every payment creation and capture. Generate deterministic keys (`order_{id}_payment`).
- Store idempotency key alongside payment record. Retry with same key on network timeout.
- Webhook handlers must be idempotent: deduplicate by event ID.
- Database transactions: payment captured AND order updated atomically.
- Payment state machine: `created` → `authorized` → `captured` → `settled` (or `voided`/`refunded`).
- Dead letter queue for webhook events that exhaust retries.
- Daily reconciliation: automated matching of gateway transactions to internal records. Alert on discrepancies.
