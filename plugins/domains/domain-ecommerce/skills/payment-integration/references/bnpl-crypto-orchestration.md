# BNPL, Crypto, and Payment Orchestration

## When to load
Load when adding buy-now-pay-later options, crypto payments, or multi-PSP routing/orchestration.

## BNPL (Buy Now Pay Later)

### Klarna
- Pay in 4 (interest-free), Pay in 30 days, Financing (6-36 months) via Klarna Payments API.
- Klarna Checkout: fully hosted one-page experience. On-site messaging widgets on PDP and cart.
- Order Management API: capture, refund, extend due dates, add shipping info.
- Merchant receives full payment upfront minus fees; Klarna takes credit risk.
- Integration via direct API or through Stripe, Adyen, Braintree, Mollie. Strong in Europe + growing US/AU.

### Affirm
- Affirm.js for prequalification and checkout. Promotional messaging ("As low as $X/month") on PDP and cart.
- Adaptive Checkout: dynamically selects Pay in 4 or monthly installments by amount.
- Deferred capture: authorize at checkout, capture on ship. Void and refund API for cancellations.
- Available direct, via Stripe, Shopify (Shop Pay Installments), or BigCommerce.

### Afterpay (Clearpay in UK/EU)
- 4 interest-free installments (every 2 weeks). Afterpay.js widget + Orders API.
- Deferred capture. In-store via virtual Visa card. Owned by Square (Block, Inc.).

### BNPL Strategy
- Display BNPL messaging on PDP, cart, and checkout — typical AOV lift 20-50%.
- Offer multiple providers for maximum coverage.
- Evaluate merchant fees (3-8%) against AOV and conversion lift.
- Handle deferred capture per provider; partial refund logic varies per provider.

## Cryptocurrency Payments

### BitPay
- Invoice API: BTC, ETH, LTC, DOGE, USDC, USDT, GUSD, PAX.
- Settlement in fiat (USD/EUR/GBP) or keep as crypto (merchant choice).
- BitPay Checkout widget for web. Webhooks for invoice status changes (paid, confirmed, complete, expired).
- KYC/AML compliance handled by BitPay. Plugins for Shopify, WooCommerce, Magento, BigCommerce.

### BTCPay Server
- Self-hosted, open-source, zero fees, no custody risk.
- Bitcoin on-chain and Lightning Network. Altcoins via plugins (Monero, Litecoin).
- Greenfield REST API, WooCommerce/Shopify integrations. POS app for in-person. Docker deployment.

### Crypto Strategy
- Offer alongside card/wallet — don't replace.
- Stablecoins (USDC, USDT) eliminate price volatility risk.
- Short expiration window (15-30 min) on exchange rate quotes.
- Custodial (BitPay) vs. self-custodial (BTCPay): convenience vs. control.
- Tax: crypto payments are taxable events; record fair market value at receipt.

## Payment Orchestration

### Primer
- Universal Checkout: single frontend for 50+ PSPs. No-code visual workflow builder for routing and fallbacks.
- Processor-agnostic vault; built-in 3DS2 across all PSPs. BIN lookup for routing decisions.
- Observability dashboard: approval rates, decline reasons, PSP performance comparison.

### Spreedly
- Universal Vault: PCI-compliant tokenization usable with 100+ gateways.
- Automatic card updater, network tokenization. 3DS2 independent of gateway.
- Receiver API for pushing card data to non-gateway third parties.

### Orchestration Strategy
- Use when accepting payments in 3+ countries with different optimal PSPs per region.
- Cost optimization: route to lowest-cost acquirer by BIN/country/card type.
- Availability: auto-failover to backup PSP on outages.
- Auth rate optimization: route to PSP with highest historical approval rate per BIN.
- A/B test PSP authorization rates with controlled traffic splitting.
- Vault portability: switch PSPs without re-tokenizing stored cards.
