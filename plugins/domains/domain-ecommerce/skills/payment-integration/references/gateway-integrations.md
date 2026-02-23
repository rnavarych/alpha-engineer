# Gateway Integrations

## When to load
Load when integrating Stripe, PayPal, Adyen, Square, Mollie, Razorpay, or Checkout.com.

## Stripe
- **PaymentIntents**: create server-side with amount/currency/metadata; confirm client-side with Payment Element. Handle `requires_action` for 3DS. Use `automatic_payment_methods` for dynamic method display.
- **SetupIntents**: collect and save payment methods without immediate charge. Attach to Customer for off-session or subscription reuse.
- **Webhooks**: listen for `payment_intent.succeeded`, `payment_intent.payment_failed`, `charge.dispute.created`. Verify `stripe-signature`. Process idempotently by event ID. Return 200 fast; queue heavy work.
- **Stripe Elements / Checkout**: Payment Element for cards + wallets + BNPL. Stripe Checkout for fully hosted SAQ A. Customize with Appearance API.
- **Stripe Connect**: Standard (full Dashboard), Express (simplified onboarding), Custom (fully white-labeled). Direct, destination, or separate charges+transfers. `application_fee_amount` for platform commission.
- **Stripe Billing**: Products/Prices for subscription plans (fixed, metered, tiered). Smart Retries for dunning. Customer Portal for self-serve management. Proration on plan changes.

## PayPal
- Orders API v2: create with `intent: CAPTURE` or `intent: AUTHORIZE`; render PayPal Buttons via JS SDK; capture server-side after approval.
- Advanced: hosted fields for custom card form. Venmo (US), Pay Later (BNPL), Vault for recurring. Payouts API for mass disbursements.
- Webhooks: `PAYMENT.CAPTURE.COMPLETED`, `PAYMENT.CAPTURE.DENIED`, `BILLING.SUBSCRIPTION.*`. Verify with PayPal verification endpoint.

## Adyen
- Drop-in for all-in-one form; Components for custom layouts. Handle `additionalAction` for 3DS2 or redirects. HMAC signature verification on notifications.
- Adyen for Platforms: split payments, sub-merchant KYC onboarding, fund transfers, payout scheduling.
- Local methods: iDEAL, Bancontact, Giropay, Sofort, SEPA, Boleto, OXXO, Konbini, PIX, UPI, WeChat Pay, Alipay.

## Square
- Payments API: card, Apple Pay, Google Pay, ACH, gift cards. Web Payments SDK for tokenization. Delayed capture for pre-orders.
- Ecosystem: Invoices, Subscriptions, Square Terminal (POS), Catalog + Inventory, Loyalty, Locations, OAuth for platforms.

## Mollie
- Payments API (redirect-based) or Orders API (line-item-aware, partial capture/refund). Components for SAQ A-EP card fields.
- European methods: iDEAL, Bancontact, SEPA, Sofort, EPS, Przelewy24, Blik, Giropay, KBC, Klarna, in3.
- Mollie Connect: OAuth for marketplace sellers, application fees, payment routing.

## Razorpay
- Orders API + Standard Checkout modal or Custom Checkout (hosted fields). Payment Links for no-code collection.
- India methods: UPI (QR + intent), Net Banking (50+ banks), Paytm/PhonePe wallets, EMI, eMandate (NACH/UPI AutoPay), Cardless EMI.
- Ecosystem: Route (marketplace splits), Subscriptions, Smart Collect (virtual accounts for B2B), RazorpayX business banking.

## Checkout.com
- Unified Payments API for cards, wallets, APMs. Flow (hosted page) or Frames (hosted fields). Network tokenization for improved auth rates.
- Intelligent Retry, customizable risk rules, Apple/Google Pay, dispute management API, reconciliation API.
- APMs: Alipay, WeChat Pay, Boleto, OXXO, Fawry, Benefitpay.
