---
name: payment-integration
description: |
  Payment gateway integration patterns for e-commerce: Stripe (PaymentIntents, SetupIntents,
  webhooks, Elements, Checkout), PayPal (Orders API, Buttons), Adyen (drop-in, components),
  subscription billing, refunds/disputes, multi-currency, and idempotency.
allowed-tools: Read, Grep, Glob, Bash
---

# Payment Integration

## Stripe Integration

### PaymentIntents (One-Time Payments)
- Create a PaymentIntent server-side with amount, currency, and metadata.
- Confirm on the client using Stripe.js `confirmCardPayment()` or the Payment Element.
- Handle `requires_action` status for 3D Secure authentication.
- Capture funds immediately (`capture_method: automatic`) or later (`capture_method: manual`).

### SetupIntents (Saving Cards)
- Use SetupIntents to collect and save payment methods without an immediate charge.
- Attach the resulting PaymentMethod to a Customer for future use.
- Combine with off-session payments for subscription renewals or one-click checkout.

### Webhooks
- Listen for `payment_intent.succeeded`, `payment_intent.payment_failed`, `charge.dispute.created`.
- Verify webhook signatures using the `stripe-signature` header and your endpoint secret.
- Process webhooks idempotently -- deduplicate by event ID to handle redeliveries.
- Return `200` quickly; perform heavy processing asynchronously.

### Stripe Elements and Checkout
- Use the Payment Element for a single, adaptive UI that supports cards, wallets, and BNPL.
- Use Stripe Checkout for a fully hosted payment page (simplest PCI compliance -- SAQ A).
- Customize appearance with the Appearance API to match your brand.

## PayPal Integration

### Orders API v2
- Create an order with `intent: CAPTURE` or `intent: AUTHORIZE`.
- Render PayPal Buttons on the client using the JavaScript SDK.
- Capture the order server-side after buyer approval.
- Handle `COMPLETED`, `VOIDED`, and error states.

### Webhook Handling
- Subscribe to `PAYMENT.CAPTURE.COMPLETED`, `PAYMENT.CAPTURE.DENIED` events.
- Verify webhook signatures using the PayPal verification endpoint or certificate chain.

## Adyen Integration

### Drop-in and Components
- Use the Adyen Drop-in for an all-in-one payment form.
- Use individual Components (Card, iDEAL, Klarna) for custom layouts.
- Handle `additionalAction` responses for 3DS2 or redirect-based methods.
- Process Adyen notifications (webhooks) with HMAC signature verification.

## Subscription Billing

### Recurring Models
- Fixed recurring: charge the same amount on a regular interval.
- Metered/usage-based: report usage, calculate charges at billing cycle end.
- Per-seat: adjust charge based on active user count.
- Tiered: graduated pricing based on usage bands.

### Lifecycle Management
- Implement trial periods with automatic conversion to paid.
- Handle plan upgrades/downgrades with proration.
- Dunning: retry failed payments with exponential backoff, notify the customer, enforce grace periods.
- Track subscription events: `created`, `renewed`, `past_due`, `cancelled`, `expired`.

## Refunds and Disputes

- Issue full or partial refunds via the gateway API.
- Track refund reasons for analytics (customer request, defective, wrong item).
- Respond to chargebacks by submitting evidence (tracking numbers, communication logs, refund policy).
- Prevent disputes with clear billing descriptors and proactive customer communication.

## Multi-Currency

- Present prices in the customer's local currency.
- Use the gateway's automatic currency conversion or manage exchange rates yourself.
- Be aware of minimum charge amounts per currency (e.g., Stripe's 50 cents USD equivalent).
- Display and settle in appropriate currencies based on your merchant account configuration.

## Idempotency

- Always include an `Idempotency-Key` header on payment creation and capture requests.
- Generate deterministic keys (e.g., `order_{orderId}_payment`) to prevent duplicate charges on retries.
- Store the idempotency key alongside the payment record for traceability.
- Retry with the same key on network timeouts to guarantee exactly-once semantics.
