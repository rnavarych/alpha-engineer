---
name: domain-ecommerce:payment-integration
description: |
  Payment gateway integration patterns for e-commerce: Stripe, PayPal, Adyen, Square, Mollie,
  Razorpay, Checkout.com, BNPL (Klarna, Affirm, Afterpay), crypto payments (BitPay, BTCPay),
  payment orchestration (Primer, Spreedly), 3DS2 authentication, fraud prevention (Sift, Riskified),
  subscription billing, refunds/disputes, multi-currency, and idempotency.
allowed-tools: Read, Grep, Glob, Bash
---

# Payment Integration

## When to use
- Integrating any payment gateway (Stripe, PayPal, Adyen, Square, Mollie, Razorpay, Checkout.com)
- Adding BNPL options (Klarna, Affirm, Afterpay) or crypto payments (BitPay, BTCPay)
- Building multi-PSP routing with orchestration layers (Primer, Spreedly)
- Implementing 3DS2/SCA compliance for EU/UK payments
- Setting up fraud prevention (Stripe Radar, Sift, Riskified, Signifyd)
- Building subscription billing with dunning and lifecycle management
- Handling refunds, chargebacks, multi-currency, and idempotency

## Core principles
1. **Idempotency-Key on every payment request** — network timeouts happen; without it you double-charge customers
2. **Never touch raw card data** — tokenize client-side, send only tokens server-side; SAQ A or SAQ A-EP always
3. **Webhook handlers must be idempotent** — deduplicate by event ID; Stripe retries; you will receive duplicates
4. **Liability shift via 3DS2** — pass browser + device data; frictionless approval rate rises dramatically with richer context
5. **Reconcile daily** — gateway transactions vs. internal records; silent discrepancies become audits

## Reference Files
- `references/gateway-integrations.md` — Stripe (PaymentIntents, Connect, Billing), PayPal, Adyen, Square, Mollie, Razorpay, Checkout.com — integration patterns and key APIs
- `references/bnpl-crypto-orchestration.md` — Klarna, Affirm, Afterpay integration; BitPay and BTCPay crypto; Primer and Spreedly orchestration strategy
- `references/fraud-security-reliability.md` — 3DS2/SCA implementation, exemptions, fraud tools (Sift/Riskified/Signifyd), subscription lifecycle, refunds, chargebacks, multi-currency, idempotency
