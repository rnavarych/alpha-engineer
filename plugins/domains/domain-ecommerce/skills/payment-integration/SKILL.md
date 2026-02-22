---
name: payment-integration
description: |
  Payment gateway integration patterns for e-commerce: Stripe, PayPal, Adyen, Square, Mollie,
  Razorpay, Checkout.com, BNPL (Klarna, Affirm, Afterpay), crypto payments (BitPay, BTCPay),
  payment orchestration (Primer, Spreedly), 3DS2 authentication, fraud prevention (Sift, Riskified),
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
- Attach metadata (order ID, customer ID, cart ID) for reconciliation and reporting.
- Use `automatic_payment_methods` to let Stripe dynamically show relevant payment methods.

### SetupIntents (Saving Cards)
- Use SetupIntents to collect and save payment methods without an immediate charge.
- Attach the resulting PaymentMethod to a Customer for future use.
- Combine with off-session payments for subscription renewals or one-click checkout.
- Handle `requires_action` for 3DS authentication during card setup.
- Mandate collection for SEPA Direct Debit and BACS setup flows.

### Webhooks
- Listen for `payment_intent.succeeded`, `payment_intent.payment_failed`, `charge.dispute.created`.
- Verify webhook signatures using the `stripe-signature` header and your endpoint secret.
- Process webhooks idempotently -- deduplicate by event ID to handle redeliveries.
- Return `200` quickly; perform heavy processing asynchronously (queue the event).
- Monitor webhook delivery failures in the Stripe Dashboard; configure retry behavior.
- Use webhook event types for subscription lifecycle: `invoice.paid`, `invoice.payment_failed`, `customer.subscription.updated`.

### Stripe Elements and Checkout
- Use the Payment Element for a single, adaptive UI that supports cards, wallets, and BNPL.
- Use Stripe Checkout for a fully hosted payment page (simplest PCI compliance -- SAQ A).
- Customize appearance with the Appearance API to match your brand.
- Link by Stripe: one-click checkout for returning Stripe users across merchants.
- Address Element for collecting and validating shipping/billing addresses.

### Stripe Connect (Marketplaces)
- **Standard accounts**: full Stripe Dashboard for connected sellers; lowest integration effort.
- **Express accounts**: simplified onboarding flow; limited Dashboard access.
- **Custom accounts**: fully white-labeled; you build the entire onboarding and Dashboard experience.
- Payment flows: direct charges (charge on connected account), destination charges (charge on platform, transfer to connected account), separate charges and transfers.
- `application_fee_amount` for platform commission on each transaction.
- Payouts: automatic or manual payout schedules per connected account.
- Account onboarding: Stripe-hosted onboarding (Account Links) or custom (Account Sessions).

### Stripe Billing (Subscriptions)
- Products and Prices: define subscription plans with recurring pricing (fixed, metered, tiered).
- Subscription lifecycle: trialing -> active -> past_due -> canceled -> unpaid.
- Customer Portal: Stripe-hosted page for customers to manage subscriptions, update payment methods, view invoices.
- Smart Retries: ML-optimized dunning for failed subscription payments (retry at optimal times).
- Proration: automatic proration on plan upgrades/downgrades.
- Usage records: report metered usage for usage-based billing; invoice at cycle end.
- Coupons and promotion codes: percentage or fixed-amount discounts on subscriptions.
- Invoice customization: add line items, apply credits, adjust tax behavior.

## PayPal Integration

### Orders API v2
- Create an order with `intent: CAPTURE` or `intent: AUTHORIZE`.
- Render PayPal Buttons on the client using the JavaScript SDK.
- Capture the order server-side after buyer approval.
- Handle `COMPLETED`, `VOIDED`, and error states.
- Include line items, shipping, and tax details in the order for buyer transparency.

### Advanced Integration
- Advanced Credit and Debit Card Payments: hosted fields for custom card form on your domain.
- Venmo: add as payment method via PayPal SDK (US only; significant mobile user base).
- PayPal Pay Later: BNPL messaging and payment options (Pay in 4, Pay Monthly).
- PayPal Vault: save payment methods for returning customers and recurring billing.
- PayPal Commerce Platform: multi-party payments for marketplaces with partner referrals.
- Payouts API: mass disbursements to vendors, affiliates, or sellers.

### Webhook Handling
- Subscribe to `PAYMENT.CAPTURE.COMPLETED`, `PAYMENT.CAPTURE.DENIED`, `BILLING.SUBSCRIPTION.*` events.
- Verify webhook signatures using the PayPal verification endpoint or certificate chain.
- Handle dispute events: `CUSTOMER.DISPUTE.CREATED`, `CUSTOMER.DISPUTE.RESOLVED`.

## Adyen Integration

### Drop-in and Components
- Use the Adyen Drop-in for an all-in-one payment form.
- Use individual Components (Card, iDEAL, Klarna, SEPA) for custom layouts.
- Handle `additionalAction` responses for 3DS2 or redirect-based methods.
- Process Adyen notifications (webhooks) with HMAC signature verification.
- Tokenization: `shopperReference` + `recurringDetailReference` for returning customers.

### Adyen for Platforms
- Split payments: define split rules to distribute funds across multiple balance accounts.
- Onboard sub-merchants with KYC verification via the Account Holder API.
- Fund transfers between platform and sub-merchant accounts.
- Payout scheduling per sub-merchant (daily, weekly, on-demand).
- Commission management: deduct platform fees from each transaction automatically.

### Local Payment Methods
- iDEAL (Netherlands), Bancontact (Belgium), Giropay (Germany), Sofort (DACH).
- SEPA Direct Debit for recurring EUR payments.
- Boleto Bancario (Brazil), OXXO (Mexico), Konbini (Japan).
- PIX (Brazil) for instant payments.
- UPI and net banking for India.
- WeChat Pay and Alipay for China.
- Dynamic payment method selection based on shopper country and currency.

## Square Integration

### Payments API
- Process card, digital wallet (Apple Pay, Google Pay), ACH, and gift card payments.
- Web Payments SDK for client-side payment form with tokenization.
- Square Checkout API for hosted payment pages.
- Cards on File: store tokenized cards for returning customers.
- Delayed capture: authorize and capture separately for pre-orders or custom fulfillment.

### Square Ecosystem
- Invoices API: create and send invoices with payment links, track payment status.
- Subscriptions API: recurring billing plans with automatic charge and dunning.
- Square Terminal: in-person payments with pre-certified hardware.
- Catalog + Inventory APIs: product and stock management (unified with payments).
- Loyalty API: points-based loyalty programs integrated with payment flow.
- Locations API: multi-location support with location-specific settings.
- OAuth for platform/marketplace integrations connecting third-party seller accounts.

## Mollie Integration

### Payments and Orders API
- Payments API: simple payment creation with redirect-based flow (customer redirected to Mollie Checkout).
- Orders API: order-aware payments with line items, enabling partial captures and refunds per line.
- Components: embedded payment form (card fields) hosted by Mollie for SAQ A-EP compliance.
- Mollie Checkout: hosted payment page for SAQ A compliance (simplest integration).

### European Payment Methods
- iDEAL (Netherlands), Bancontact (Belgium), SEPA Direct Debit, Sofort (Germany/Austria).
- EPS (Austria), Przelewy24 (Poland), Blik (Poland), Giropay (Germany).
- KBC/CBC (Belgium), Belfius (Belgium).
- Credit/debit cards (Visa, Mastercard, Amex).
- PayPal, Apple Pay, Klarna, in3 (Dutch BNPL).

### Mollie Connect (Platforms)
- OAuth-based onboarding for marketplace sellers.
- Application fees: deduct platform commission from each payment.
- Routing: split payments across multiple connected accounts.
- Multi-currency support with automatic settlement conversion.
- Mollie Dashboard for connected account management.

## Razorpay Integration

### Core Integration
- Orders API: create an order with amount, currency, receipt, and notes.
- Standard Checkout: Razorpay-hosted modal overlay for payment collection.
- Custom Checkout: hosted fields for card input; full control over payment form UX.
- Payment Links: no-code payment collection via shareable links.
- Webhook notifications with signature verification for payment events.

### India-Specific Payment Methods
- UPI (Unified Payments Interface): QR code and intent-based payments.
- Net Banking: 50+ Indian banks supported.
- Wallets: Paytm, PhonePe, Amazon Pay, FreeCharge.
- EMI: card-based installments with bank partnerships.
- eMandate: recurring NACH/UPI AutoPay debits for subscriptions.
- Cardless EMI: installments without a credit card (ZestMoney, FlexiPay).

### Razorpay Ecosystem
- Route: payment splitting for marketplaces (linked accounts with automatic settlement).
- Subscriptions API: recurring billing with plan management and dunning.
- Smart Collect: virtual bank accounts for automated B2B payment reconciliation.
- RazorpayX: business banking (payouts, vendor payments, tax payments).
- POS: in-person card and QR code payments.

## Checkout.com Integration

### Core Integration
- Unified Payments API: create and manage payments across card, wallet, and APM methods.
- Flow: hosted payment page (redirect-based, simplest integration).
- Frames: hosted fields for custom card form (card data stays on Checkout.com servers).
- Standalone Vault: tokenize and store cards for recurring and returning customer payments.
- Network tokenization: store network tokens for improved authorization rates and reduced fraud.

### Advanced Features
- Intelligent Retry: automatically retry declined transactions at optimal times.
- Risk management: customizable rules engine with ML-based fraud scoring.
- Apple Pay and Google Pay with direct integration support.
- Dispute management API: programmatic evidence submission for chargebacks.
- Reconciliation API: match gateway transactions to settlement records.
- Alternative payment methods: Alipay, WeChat Pay, Boleto, OXXO, Fawry, Benefitpay.

## BNPL (Buy Now Pay Later)

### Klarna
- Klarna Payments API: Pay in 4 (interest-free installments), Pay in 30 days, Financing (6-36 months).
- Klarna Checkout: full hosted checkout experience (one-page checkout managed by Klarna).
- On-site messaging widgets: "Pay in 4 installments of $X" on product and cart pages.
- Order Management API: capture, refund, extend due dates, add shipping info.
- Risk handled by Klarna: merchant receives full payment upfront minus fees.
- Integration via direct API or through Stripe, Adyen, Braintree, Mollie.
- Settlement reports and payouts via Klarna Merchant Portal or API.
- Strong in Europe (Sweden, Germany, UK, Netherlands); growing in US and AU.

### Affirm
- Affirm.js: client-side SDK for prequalification and checkout integration.
- Promotional messaging: "As low as $X/month" banners on product and cart pages.
- Adaptive Checkout: Affirm dynamically selects Pay in 4 or monthly installments based on amount.
- Checkout API: server-side order confirmation with charge authorization.
- Deferred capture: authorize at checkout, capture when item ships.
- Void and refund API for cancellations and returns.
- Merchant receives full payment minus fee; Affirm handles credit risk.
- Available via direct API, Stripe, Shopify (Shop Pay Installments), BigCommerce.

### Afterpay (Clearpay in UK/EU)
- 4 interest-free installments (customer pays every 2 weeks).
- Afterpay.js for client-side checkout widget integration.
- Orders API for server-side order creation and management.
- Deferred capture: authorize at checkout, capture on shipment.
- In-store Afterpay via virtual Visa card in Apple/Google Wallet.
- Owned by Square (Block, Inc.); deep Square integration.
- Integration via direct API, Stripe, Adyen, or Square.

### BNPL Implementation Strategy
- Display BNPL messaging on product detail pages, cart, and checkout to increase conversion.
- Typical AOV lift of 20-50% when BNPL is available.
- Offer multiple BNPL providers for maximum customer coverage.
- Evaluate merchant fees (3-8%) against AOV increase and conversion lift.
- Handle deferred capture correctly: authorize at checkout, capture when items ship.
- Partial refund handling varies by provider; implement per-provider refund logic.

## Cryptocurrency Payments

### BitPay
- Invoice API: create crypto payment requests (BTC, ETH, LTC, DOGE, stablecoins USDC/USDT/GUSD/PAX).
- Settlement: receive fiat (USD, EUR, GBP) or keep as crypto (merchant choice).
- BitPay Checkout widget for embedding in web checkout flow.
- Webhook notifications for invoice status changes (paid, confirmed, complete, expired).
- Plugins for Shopify, WooCommerce, Magento, BigCommerce, WHMCS.
- BitPay handles KYC/AML compliance for crypto transactions.
- Supported currencies and networks configurable per merchant account.

### BTCPay Server
- Self-hosted, open-source cryptocurrency payment processor (zero fees, no custody risk).
- Bitcoin: on-chain and Lightning Network for instant, low-fee payments.
- Altcoins via plugins: Monero, Litecoin, and others.
- WooCommerce, Shopify, Drupal, and custom API (Greenfield REST API) integrations.
- Point-of-sale app for in-person crypto payments.
- Pull payments for recurring billing and payouts.
- Multi-store support with separate wallets per store.
- Docker-based deployment; host on your own infrastructure or VPS.

### Crypto Strategy
- Offer crypto as an additional payment method alongside card and wallet options.
- Stablecoin acceptance (USDC, USDT) eliminates price volatility risk.
- Consider regulatory requirements: money transmitter licenses, tax reporting obligations.
- Real-time exchange rate display with short expiration window (15-30 minutes).
- Custodial (BitPay) vs. self-custodial (BTCPay): trade-off between convenience and control.
- Tax: crypto payments are taxable events (record fair market value at time of receipt).

## Payment Orchestration

### Primer
- Universal Checkout: single frontend integration for multiple PSPs and payment methods.
- No-code workflow builder: visually configure routing, fallbacks, and retry logic.
- 50+ PSP connections (Stripe, Adyen, Braintree, Checkout.com, Mollie, Worldpay).
- Processor-agnostic vault: tokenize cards independently of any single PSP.
- Built-in 3DS2 that works across all connected PSPs.
- Observability: approval rates, decline reasons, PSP performance comparison dashboards.
- BIN lookup and metadata enrichment for intelligent routing decisions.
- Fallback chains: if primary PSP declines, automatically retry on secondary PSP.

### Spreedly
- Universal Vault: PCI-compliant card vault usable with any supported gateway.
- Gateway-agnostic tokenization: tokenize once, transact with 100+ gateways.
- Lifecycle management: automatic card updater, network tokenization for improved auth rates.
- 3DS2 integration independent of payment gateway.
- Environment-based configuration for multi-merchant and multi-region setups.
- Receiver API for pushing card data to non-gateway third parties (loyalty, travel, insurance).
- Transaction logging and reconciliation across all gateways.

### Orchestration Strategy
- When to use: accepting payments in 3+ countries with different optimal PSPs per region.
- Cost optimization: route to lowest-cost acquirer per BIN/country/card type.
- Availability: automatic failover to backup PSP during outages (zero customer impact).
- Auth rate optimization: route to PSP with highest historical approval rate per BIN range.
- A/B testing: compare PSP authorization rates and costs with controlled traffic splitting.
- Consolidated reporting: single dashboard across all PSPs for finance and ops teams.
- Reduced lock-in: switch PSPs without re-tokenizing stored cards (vault portability).

## 3D Secure 2 (3DS2) Authentication

### SCA Compliance (PSD2)
- Strong Customer Authentication required for EU/UK online card payments.
- 3DS2 provides frictionless (no customer interaction) or challenge (OTP/biometric) flows.
- Frictionless: issuer authenticates based on risk signals without interrupting the customer.
- Challenge: customer completes verification (SMS OTP, banking app approval, biometric).
- Liability shift: successful 3DS authentication shifts fraud liability from merchant to issuer.

### 3DS2 Data Enrichment
- Send browser data: user agent, screen dimensions, timezone, language, Java/JavaScript enabled.
- Send device data: IP address, device fingerprint, account age, purchase history.
- More data = higher frictionless approval rate (issuers trust well-known devices/customers).
- Use 3DS SDKs from payment gateways (Stripe, Adyen, Braintree) or orchestrators (Primer, Spreedly).

### Exemptions
- Low-value transactions: under 30 EUR (cumulative limit applies).
- Merchant-initiated transactions (MIT): recurring subscription charges, merchant-triggered payments.
- Trusted beneficiaries: customer adds merchant to their trusted list with the issuer.
- Transaction Risk Analysis (TRA): merchants with low fraud rates can request exemption for transactions up to 500 EUR.
- Secure corporate payments: B2B payments with dedicated corporate cards.

## Fraud Prevention

### Gateway-Native Tools
- Stripe Radar: ML-based fraud scoring, custom rules (block, review, allow per risk level).
- Adyen RevenueProtect: risk rules, referral management, device fingerprinting, velocity checks.
- PayPal Seller Protection: automatic coverage for eligible transactions.
- Square Risk Manager: automated fraud detection integrated into Square payments.

### Third-Party Fraud Prevention
- **Sift**: real-time ML fraud detection for payments, account takeover, content abuse. Workflow automation for review queues.
- **Riskified**: guaranteed fraud protection (chargeback liability shifts to Riskified if they approve a fraudulent transaction).
- **Signifyd**: commerce protection platform with guaranteed fraud decisions and chargeback recovery.
- **Forter**: real-time fraud decisioning across the entire customer journey (account, payment, return).
- **Kount (Equifax)**: AI-driven fraud and identity trust network with cross-merchant intelligence.
- Integration: pre-authorization (block before charging) or post-authorization (review after charging, void if fraudulent).

### Fraud Prevention Best Practices
- AVS (Address Verification System): match billing address with issuer records.
- CVV/CVC verification: require card security code for every card-not-present transaction.
- Velocity checks: flag multiple failed attempts, unusual amounts, rapid successive orders.
- Device fingerprinting: identify returning devices across sessions and accounts.
- IP geolocation: flag transactions from high-risk countries or mismatched with billing address.
- Email risk scoring: check email domain age, disposable email providers, breach databases.
- Shipping-billing address mismatch: flag orders with different shipping and billing addresses.
- Proxy/VPN detection: identify customers masking their true location.
- Manual review queue: human review for high-value, first-time, or flagged international orders.

## Subscription Billing

### Recurring Models
- Fixed recurring: charge the same amount on a regular interval.
- Metered/usage-based: report usage, calculate charges at billing cycle end.
- Per-seat: adjust charge based on active user count.
- Tiered: graduated pricing based on usage bands.
- Hybrid: base fee + usage-based overage charges.

### Lifecycle Management
- Implement trial periods with automatic conversion to paid (free trial, paid trial, payment method required).
- Handle plan upgrades/downgrades with proration (immediate or at next renewal).
- Dunning: retry failed payments with schedule (day 0, 1, 3, 5, 7, 14), notify customer, enforce grace periods.
- Track subscription events: `created`, `activated`, `renewed`, `past_due`, `paused`, `cancelled`, `expired`, `reactivated`.
- Cancellation: immediate vs. end-of-period; collect cancellation reason; offer win-back incentive.
- Pause: allow customers to skip cycles or pause for a period, then auto-resume.

### Subscription Platforms
- Stripe Billing: hosted customer portal, smart retries, revenue recovery, usage billing.
- Chargebee: subscription management with dunning, revenue recognition, analytics, and self-serve portal.
- Recurly: decline management, subscriber analytics, plan experimentation.
- Paddle: merchant of record (handles tax, compliance, payouts globally).
- Custom: build your own billing engine on top of gateway APIs for full control and flexibility.

## Refunds and Disputes

### Refund Processing
- Issue full or partial refunds via the gateway API.
- Track refund reasons for analytics (customer request, defective, wrong item, fraud).
- Refund to original payment method (default) or store credit (alternative).
- Refund timing: card refunds take 5-10 business days; BNPL refunds vary by provider; ACH 3-5 days.
- Handle multi-tender refunds: refund to the correct payment method when order used multiple methods.

### Dispute/Chargeback Management
- Respond to chargebacks by submitting evidence (tracking numbers, communication logs, refund policy).
- Prevent disputes with clear billing descriptors (customer recognizes the charge on their statement).
- Chargeback alert services (Verifi, Ethoca): get notified before a dispute becomes a chargeback.
- Visa CE 3.0: submit prior successful transaction evidence to fight fraud chargebacks.
- Chargeback monitoring: Visa (0.9%), Mastercard (1.0%) thresholds -- exceed and enter monitoring programs.
- Dispute analytics: track dispute rate by product, category, payment method, and customer segment.

## Multi-Currency

- Present prices in the customer's local currency (auto-detect via IP geolocation or customer preference).
- Use the gateway's automatic currency conversion or manage exchange rates yourself.
- Be aware of minimum charge amounts per currency (e.g., Stripe's 50 cents USD equivalent).
- Display and settle in appropriate currencies based on your merchant account configuration.
- Dynamic currency conversion (DCC): let international cardholders pay in their home currency.
- Multi-currency pricing: set explicit prices per currency (preferred) or auto-convert with rounding rules.
- Cross-border interchange fees: understand pricing impact of international card-not-present transactions.
- Settlement currency: configure per-region merchant accounts to settle in local currency and reduce FX costs.

## Idempotency and Reliability

- Always include an `Idempotency-Key` header on payment creation and capture requests.
- Generate deterministic keys (e.g., `order_{orderId}_payment`) to prevent duplicate charges on retries.
- Store the idempotency key alongside the payment record for traceability.
- Retry with the same key on network timeouts to guarantee exactly-once semantics.
- Design webhook handlers to be idempotent: deduplicate by event ID, skip already-processed events.
- Use database transactions to ensure payment and order state consistency (payment captured AND order updated atomically).
- Implement a payment state machine: `created` -> `authorized` -> `captured` -> `settled` (or `voided` / `refunded`).
- Dead letter queue for webhook events that fail processing after all retries.
- Daily reconciliation: automated matching of gateway transactions against internal payment records.
- Alert on discrepancies: settlement mismatches, unusual decline rates, webhook delivery failures.
