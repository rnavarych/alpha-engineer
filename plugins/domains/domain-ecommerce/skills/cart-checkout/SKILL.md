---
name: cart-checkout
description: |
  Shopping cart and checkout flow design: cart architectures (session, DB, Redis, headless cart APIs),
  express checkout (Apple Pay, Google Pay, Shop Pay, Amazon Pay), shipping integration (ShipStation,
  Shippo, EasyPost), tax engines (Avalara, TaxJar), promotion/discount engine, cart recovery
  (Klaviyo, Omnisend), BOPIS (buy online pick up in-store), guest checkout, address validation,
  and checkout conversion optimization.
allowed-tools: Read, Grep, Glob, Bash
---

# Cart and Checkout

## Shopping Cart Architecture

### Storage Strategies
- **Session-based**: Store cart in a server-side session or cookie. Simple but lost on session expiry. Suitable for low-traffic sites.
- **Database-backed**: Store cart rows in a `cart_items` table keyed by user ID or session ID. Survives server restarts. Best for carts that need to persist across sessions and devices.
- **Redis**: Store cart as a hash or JSON document with a TTL. Fast reads, good for high-traffic stores. Use Redis Cluster for horizontal scaling.
- **Headless cart API**: Platform-managed cart (Shopify Storefront API Cart, commercetools Cart API, Medusa Cart API). Cart state managed by the commerce backend, frontend is stateless.
- **Hybrid**: Redis for hot cart data (active sessions), database for cold storage (abandoned carts for recovery), sync on checkout start.

### Cart Data Model
- Cart entity: `cart_id`, `customer_id` (nullable for guest), `session_id`, `status` (active/merged/converted/abandoned), `currency`, `created_at`, `updated_at`, `expires_at`.
- Cart line items: `line_id`, `cart_id`, `variant_id`, `quantity`, `unit_price`, `line_total`, `metadata` (customization, gift wrapping, subscription options).
- Cart-level data: shipping address, billing address, selected shipping method, applied promotions, notes.
- Cart totals: subtotal, discount total, shipping total, tax total, grand total (recalculated on every cart modification).

### Cart Merging
- When an anonymous user logs in, merge their session cart with their saved cart.
- Merge strategies: keep the higher quantity, sum quantities, or prompt the user to choose.
- Transfer cart items from session key to user ID in the backing store.
- Preserve applied promotions and selections during merge when possible.
- Handle cart merging across devices (user adds items on mobile, logs in on desktop).

### Cart Validation
- Re-validate prices, stock availability, and promo eligibility on every cart view and at checkout start.
- Display warnings for out-of-stock items or price changes since the item was added.
- Remove or disable unavailable items automatically with clear messaging.
- Validate minimum/maximum order quantities per product.
- Enforce minimum order amount for checkout eligibility.
- Check product-level restrictions: age verification required, shipping restrictions (hazmat, alcohol), regional availability.

## Express Checkout

### Apple Pay
- Display Apple Pay button on product pages, cart, and checkout for one-tap purchase.
- Payment Request API (web) or PassKit (iOS) integration.
- Retrieve shipping address and contact info from Apple Pay to skip address entry forms.
- Dynamically calculate shipping options and tax based on the Apple Pay-provided address.
- Merchant domain verification and certificate configuration.
- Apple Pay express checkout flow: button click -> sheet with address/shipping/payment -> authorize -> capture.

### Google Pay
- Display Google Pay button with `isReadyToPay` check for device/browser support.
- Retrieve payment token, shipping address, and email from Google Pay.
- Gateway tokenization (recommended) or direct tokenization.
- Configure payment data request with supported networks, merchant info, and transaction details.
- Dynamic shipping cost and tax update via `onPaymentDataChanged` callback.

### Shop Pay
- Shopify's accelerated checkout: returning buyers complete purchase in one tap.
- Shop Pay Installments: BNPL via Affirm (4 interest-free payments for eligible orders).
- Available on Shopify Checkout and through Shopify Payments.
- Carbon-neutral: every Shop Pay transaction includes carbon offset.
- Cross-merchant buyer recognition via the Shop app.

### Amazon Pay
- Amazon Pay button on cart and checkout pages.
- Buyer selects shipping address and payment from their Amazon account.
- Headless API integration or hosted widgets for address/payment selection.
- Automatic Payments for subscriptions and recurring orders.
- A-to-z Guarantee for buyer protection.

### Express Checkout Best Practices
- Display express checkout buttons above the fold on cart page (before the standard checkout button).
- Show express options on product detail pages for impulse purchases.
- Support multiple express methods simultaneously (Apple Pay + Google Pay + Shop Pay).
- Ensure express checkout total matches the standard checkout total (including tax and shipping).
- Handle failed express checkout gracefully: fall back to standard checkout with pre-filled data.

## Checkout Flow Design

### Single-Page Checkout
- All steps (shipping address, shipping method, payment, review) on one page.
- Use accordion or tabbed sections to manage visual complexity.
- Best for stores with few options; reduces page loads and perceived friction.
- Auto-advance to next section on completion of current section.
- Inline validation: validate fields as the user moves between sections.

### Multi-Step Checkout
- Separate pages for address, shipping, payment, and review.
- Show a progress indicator so users know where they are.
- Persist step data server-side to handle back-button navigation and page refreshes.
- Allow users to edit previous steps without losing current step data.
- URL-based steps (e.g., `/checkout/shipping`, `/checkout/payment`) for analytics tracking.

### Guest Checkout
- Allow purchase without account creation to reduce abandonment (typically 10-25% abandonment from forced registration).
- Offer optional account creation after order confirmation (post-purchase registration) with a pre-filled form.
- Collect only the email required for order confirmation and tracking.
- Store guest order data with email as identifier for customer service lookups.
- Offer "save info for next time" via payment method (Apple Pay, Google Pay, Link by Stripe).

### Checkout Conversion Optimization
- Minimize form fields: auto-detect city/state from ZIP code, use single name field or auto-split.
- Auto-fill support: use proper HTML `autocomplete` attributes for browser auto-fill compatibility.
- Address autocomplete: Google Places API, Loqate, SmartyStreets for type-ahead address entry.
- Trust signals: security badges, SSL indicator, accepted payment method logos, return policy summary.
- Order summary always visible: show cart contents, totals, and applied discounts throughout checkout.
- Exit-intent popup: show offer or reminder when user attempts to leave checkout.
- Progress persistence: save checkout state so users can return later without starting over.

## Address Validation

### Validation Services
- **SmartyStreets (Smarty)**: US and international address validation and autocomplete, USPS certified.
- **Google Address Validation API**: verify and correct addresses using Google Maps data.
- **Loqate (GBG)**: international address capture and verification with type-ahead.
- **USPS Address API**: free address validation for US addresses (standardization and ZIP+4 lookup).
- **Melissa**: global address verification, geocoding, and data quality.
- **EasyPost Address Verification**: built into EasyPost shipping platform.

### Implementation
- Validate shipping addresses at checkout before proceeding to shipping method selection.
- Suggest corrections for typos or incomplete addresses with a "Did you mean...?" prompt.
- Restrict shipping to supported countries/regions; display clear messaging for unsupported destinations.
- Handle PO boxes: some carriers/services do not deliver to PO boxes -- warn the user.
- Military addresses (APO/FPO/DPO): ensure proper formatting and carrier support.
- Store validated/standardized address alongside the user-entered address for reference.

## Shipping Integration

### Shipping Aggregators
- **ShipStation**: multi-carrier shipping platform with rate comparison, label generation, and tracking. Integrates with 100+ carriers (USPS, UPS, FedEx, DHL, etc.) and 70+ sales channels.
- **Shippo**: shipping API for rate comparison, label creation, and tracking across 85+ carriers. Generous free tier for low-volume shippers.
- **EasyPost**: shipping API with carrier-agnostic label generation, tracking, and address verification. SmartRate for delivery date and rate optimization.
- **ShipBob**: 3PL + shipping platform for outsourced fulfillment with 2-day shipping network.
- **Pirate Ship**: USPS and UPS discounted rates with free label generation (no monthly fees).

### Carrier API Integration
- Fetch real-time rates from carriers (UPS, FedEx, USPS, DHL, Canada Post, Royal Mail) using their rating APIs or via an aggregator.
- Cache shipping rates briefly (5-15 minutes) to avoid redundant API calls during checkout.
- Fall back to flat-rate or table-rate shipping if carrier APIs are unavailable (circuit breaker pattern).
- Rate shopping: compare rates across carriers and present the cheapest or fastest option per tier.

### Shipping Methods
- **Standard shipping**: ground delivery, 5-7 business days.
- **Expedited shipping**: 2-3 business day delivery.
- **Overnight/express**: next business day delivery.
- **Free shipping**: conditional (minimum order amount, specific products/categories, promotional periods).
- **In-store pickup (BOPIS)**: customer picks up at a retail location (no shipping cost).
- **Curbside pickup**: BOPIS variant; customer stays in vehicle, staff brings order out.
- **Same-day / local delivery**: for businesses with local fulfillment capabilities (courier, own fleet).
- **Ship to store**: ship to customer's preferred store for pickup.
- Display estimated delivery dates based on carrier transit times, warehouse cut-off times, and processing days.
- Saturday and Sunday delivery options where available (UPS Saturday, Amazon).

### Shipping Rules Engine
- Define shipping rules: free shipping over $X, flat rate per order, weight-based rates, price-based tiers.
- Geo-based rules: different rates for domestic, international, and specific zones (Alaska, Hawaii, territories).
- Product-based rules: oversized items, hazmat, fragile items with special handling surcharges.
- Promotional shipping: free shipping codes, reduced-rate shipping for loyalty members.
- Multi-warehouse routing: automatically select the warehouse closest to the customer or with the most available stock.

## Tax Calculation

### Tax Engine Integration
- **Avalara AvaTax**: real-time tax calculation for US, Canada, EU, and 190+ countries. Product tax codes, exemption certificates, and automated filing.
- **TaxJar**: automated US sales tax calculation, reporting, and filing. SmartCalcs API with nexus determination.
- **Vertex**: enterprise tax engine for complex multi-jurisdictional scenarios (B2B, manufacturing, ERP integration).
- **Stripe Tax**: simple tax calculation integrated with Stripe Payments (limited to Stripe transactions).
- **TaxCloud**: free US sales tax calculation API (funded by states).

### Tax Calculation in Checkout
- Calculate tax after shipping address is entered (tax depends on destination jurisdiction).
- Pass product tax codes to the tax engine for correct categorization (clothing, food, digital goods have different rates).
- Handle tax-exempt customers: validate exemption certificates, apply exemption at checkout.
- Display tax amount on the order summary; update dynamically as address or items change.
- Tax-inclusive vs. tax-exclusive display based on customer locale (EU: inclusive, US: exclusive).
- Store tax calculation details on the order for refund calculation and reporting.

## Promotion and Discount Engine

### Discount Types
- Percentage discount (10% off), fixed amount ($5 off), free shipping.
- Product-specific, category-specific, or order-level discounts.
- Buy-one-get-one (BOGO) and buy-X-get-Y promotions.
- Bundle discounts: buy products A + B + C together for a combined discount.
- Tiered discounts: spend $50 get 5% off, spend $100 get 10% off, spend $200 get 15% off.
- Gift with purchase: free item added to cart when conditions are met.
- First-time customer discount: auto-applied or via unique code for new customers.
- Loyalty points redemption: redeem loyalty points as a discount at checkout.

### Promotion Conditions and Rules
- Enforce usage limits: per-customer, total uses, minimum order amount, valid date range.
- Stack or exclude: define whether multiple promotions can combine (e.g., sale items excluded from coupon discounts).
- Customer targeting: specific customer segments, email domains, geographic regions.
- Channel restrictions: web-only, in-store-only, or omnichannel promotions.
- Product restrictions: specific SKUs, categories, brands, collections, or exclusions.
- Calculate discount amounts before tax; display savings clearly on the order summary.

### Promotion Engine Architecture
- Rule engine: evaluate conditions in priority order, apply highest-priority matching promotion.
- Composable rules: conditions (cart total > $50 AND customer is VIP) + actions (apply 20% discount to order).
- Automatic promotions: applied without a code when conditions are met (e.g., "free shipping on orders over $75").
- Code-based promotions: require a promo code entry at checkout.
- Promotion analytics: track usage, redemption rate, revenue impact, and margin impact per promotion.
- Abuse prevention: limit per-customer usage, detect code sharing, block known abusers.

## Cart Recovery

### Klaviyo
- E-commerce-focused marketing automation platform with deep Shopify, Magento, WooCommerce, and BigCommerce integrations.
- Pre-built abandoned cart flow: trigger sequence based on cart abandonment event.
- Dynamic cart content blocks: show abandoned products with images, prices, and a "complete purchase" link.
- Flow branching: different recovery sequences for high-value vs. low-value carts, first-time vs. returning customers.
- SMS cart recovery: send text message with cart link for mobile-first customers.
- A/B testing within flows: test subject lines, send times, discount offers.
- Revenue attribution: track revenue recovered from abandoned cart campaigns.

### Omnisend
- Omnichannel marketing platform with email, SMS, push notifications, and web push.
- Abandoned cart automation: pre-built workflow with customizable timing and content.
- Product recommender: suggest related products in recovery emails.
- Discount incentive automation: auto-generate unique discount codes for recovery emails.
- Segmentation: segment abandoned carts by value, product category, customer type.
- Multi-channel recovery: email first, then SMS, then push notification (escalation sequence).

### Cart Recovery Strategy
- **Timing**: Send first recovery message 1 hour after abandonment, second at 24 hours, third at 72 hours.
- **First email**: reminder with cart contents, no discount (many users simply forgot or got distracted).
- **Second email**: create urgency ("items are selling fast"), optionally include a small incentive.
- **Third email**: offer a discount code (5-10% off) as a final nudge.
- **Direct cart link**: include a link that reconstructs the cart with items pre-loaded.
- **Personalization**: use customer name, show exact abandoned products, recommend alternatives if items are now out of stock.
- **Exit-intent**: capture email before abandonment using an exit-intent popup with a small incentive.
- **Web push**: browser push notification for cart recovery (no email required, consent-based).

### Cart Recovery Analytics
- Track recovery email open rates, click-through rates, and conversion rates.
- Measure revenue recovered from abandoned cart campaigns.
- Segment by abandonment stage (cart page vs. shipping vs. payment) to identify friction points.
- Compare recovery rates across channels (email vs. SMS vs. push).
- Monitor unsubscribe rates from recovery sequences (too aggressive = high unsubscribes).
- A/B test: timing, subject lines, incentive amounts, and content layout.

## BOPIS (Buy Online, Pick Up In-Store)

### BOPIS Checkout Flow
1. Customer selects "Pick up in store" as the delivery method.
2. Store selection: show nearby stores with real-time inventory availability for cart items.
3. Customer selects a store and preferred pickup time/window.
4. Order is placed and routed to the selected store for preparation.
5. Store staff picks and stages the order; marks as "ready for pickup" in the system.
6. Customer receives notification (email, SMS, push) that the order is ready.
7. Customer arrives at store; presents order confirmation or ID for pickup.
8. Staff hands off the order; marks as "picked up" to complete fulfillment.

### BOPIS Technical Requirements
- Real-time per-store inventory visibility (requires POS <-> ecommerce inventory sync).
- Store locator with geocoding and distance calculation (Google Maps API, Mapbox).
- Store-specific operating hours and pickup windows.
- Inventory reservation at the selected store on order placement (prevent selling the last unit to an in-store customer).
- Notification system: trigger "ready for pickup" notifications when store staff completes staging.
- Pickup time windows: configurable per store (e.g., "ready in 2 hours", "ready by tomorrow 10 AM").
- Curbside variation: customer check-in flow (SMS, app button) triggers staff delivery to parking area.
- Store-level fulfillment dashboard: separate view for store staff to manage BOPIS orders.

### BOPIS Considerations
- Mixed carts: some items for pickup, some for shipping (handle as split fulfillment).
- Hold period: if customer does not pick up within X days, cancel and refund (or restock).
- Returns for BOPIS: customer can return picked-up items to any store location.
- Tax calculation: for BOPIS, tax jurisdiction is based on the store location (not customer's home address).
- Metrics: track BOPIS adoption rate, preparation time, pickup time, and conversion vs. standard shipping.
