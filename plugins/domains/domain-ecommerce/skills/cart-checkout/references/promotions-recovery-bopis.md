# Promotions, Cart Recovery, and BOPIS

## When to load
Load when building discount/promotion engines, abandoned cart recovery workflows, or BOPIS (buy online pick up in-store) features.

## Promotion and Discount Engine

### Discount Types
- Percentage (10% off), fixed amount ($5 off), free shipping.
- Product-specific, category-specific, order-level.
- BOGO / buy-X-get-Y, bundle discounts, tiered spend discounts.
- Gift with purchase: auto-add free item when conditions are met.
- First-time customer discount, loyalty points redemption.

### Promotion Conditions
- Usage limits: per-customer, total uses, minimum order amount, valid date range.
- Stacking rules: define whether multiple promotions can combine (sale items excluded from coupons).
- Customer targeting: segments, email domains, geographic regions.
- Channel restrictions: web-only, in-store-only, omnichannel.
- Calculate discount before tax; display savings clearly on order summary.

### Promotion Engine Architecture
- Rule engine: evaluate conditions in priority order, apply highest-priority matching promotion.
- Composable rules: conditions (cart > $50 AND customer is VIP) + actions (apply 20% discount).
- Automatic promotions: applied without code when conditions met (free shipping over $75).
- Code-based: require promo code entry at checkout.
- Abuse prevention: per-customer usage limits, code-sharing detection, block known abusers.
- Promotion analytics: track usage, redemption rate, revenue impact, margin impact.

## Cart Recovery

### Klaviyo
- E-commerce-focused marketing automation with deep Shopify, Magento, WooCommerce, BigCommerce integrations.
- Pre-built abandoned cart flow; dynamic cart content blocks with product images and prices.
- Flow branching: high-value vs. low-value, first-time vs. returning.
- SMS recovery; A/B testing within flows; revenue attribution.

### Omnisend
- Omnichannel: email, SMS, push, web push.
- Pre-built abandoned cart workflow with unique discount code generation.
- Multi-channel escalation: email → SMS → push.
- Segmentation by cart value, product category, customer type.

### Cart Recovery Strategy
- **T+1h**: reminder with cart contents, no discount (user just forgot).
- **T+24h**: create urgency ("selling fast"), optional small incentive.
- **T+72h**: discount code (5-10%) as final nudge.
- Include direct cart-reconstruction link in all messages.
- Personalize with customer name, exact abandoned products, alternatives if now out of stock.
- Exit-intent popup: capture email before abandonment.
- Web push: consent-based recovery without requiring email.
- Track open rate, CTR, conversion rate, recovered revenue, and unsubscribe rates.

## BOPIS (Buy Online, Pick Up In-Store)

### Checkout Flow
1. Customer selects "Pick up in store" as delivery method.
2. Store selection with real-time inventory availability per cart item.
3. Customer picks store and preferred pickup time/window.
4. Order routed to selected store for preparation.
5. Staff picks and stages; marks "ready for pickup."
6. Customer receives notification (email, SMS, push).
7. Customer presents confirmation or ID for pickup; staff marks "picked up."

### Technical Requirements
- Real-time per-store inventory (requires POS ↔ ecommerce inventory sync).
- Store locator with geocoding and distance calculation (Google Maps API, Mapbox).
- Store operating hours, pickup windows, and inventory reservation at order placement.
- Notification system triggered when staff completes staging.
- Curbside variation: customer check-in (SMS/app) triggers staff delivery to parking.
- Store-level fulfillment dashboard for BOPIS order management.

### BOPIS Edge Cases
- Mixed carts: items for pickup + items for shipping → split fulfillment.
- Hold period: cancel and refund if not picked up within X days.
- Returns: customer can return at any store location.
- Tax jurisdiction: based on store location, not customer home address.
