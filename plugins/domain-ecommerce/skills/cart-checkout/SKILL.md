---
name: cart-checkout
description: |
  Shopping cart and checkout flow design: cart persistence (session, DB, Redis), checkout flow
  patterns (single-page, multi-step), guest checkout, address validation, shipping calculation,
  promo codes/coupons, and abandoned cart recovery.
allowed-tools: Read, Grep, Glob, Bash
---

# Cart and Checkout

## Shopping Cart Persistence

### Storage Strategies
- **Session-based**: Store cart in a server-side session or cookie. Simple but lost on session expiry.
- **Database-backed**: Store cart rows in a `cart_items` table keyed by user ID or session ID. Survives server restarts.
- **Redis**: Store cart as a hash or JSON document with a TTL. Fast reads, good for high-traffic stores.

### Cart Merging
- When an anonymous user logs in, merge their session cart with their saved cart.
- Resolve conflicts: keep the higher quantity, or prompt the user.
- Transfer cart items from session key to user ID in the backing store.

### Cart Validation
- Re-validate prices, stock availability, and promo eligibility on every cart view and at checkout start.
- Display warnings for out-of-stock items or price changes since the item was added.
- Remove or disable unavailable items automatically with clear messaging.

## Checkout Flow Design

### Single-Page Checkout
- All steps (shipping address, shipping method, payment, review) on one page.
- Use accordion or tabbed sections to manage visual complexity.
- Best for stores with few options; reduces page loads and perceived friction.

### Multi-Step Checkout
- Separate pages for address, shipping, payment, and review.
- Show a progress indicator so users know where they are.
- Persist step data server-side to handle back-button navigation and page refreshes.

### Guest Checkout
- Allow purchase without account creation to reduce abandonment.
- Offer optional account creation after order confirmation (post-purchase registration).
- Collect only the email required for order confirmation and tracking.

## Address Validation
- Validate shipping addresses against a postal service API (USPS, Google Address Validation, SmartyStreets).
- Suggest corrections for typos or incomplete addresses.
- Restrict shipping to supported countries/regions; display clear messaging for unsupported destinations.

## Shipping Calculation

### Carrier API Integration
- Fetch real-time rates from carriers (UPS, FedEx, USPS, DHL) using their rating APIs.
- Cache shipping rates briefly (5-15 minutes) to avoid redundant API calls during checkout.
- Fall back to flat-rate or table-rate shipping if carrier APIs are unavailable.

### Shipping Methods
- Offer multiple options: standard, expedited, overnight, in-store pickup.
- Display estimated delivery dates based on carrier transit times and warehouse cut-off times.
- Support free shipping thresholds (e.g., free shipping on orders over $50).

## Promo Codes and Coupons

### Types
- Percentage discount (10% off), fixed amount ($5 off), free shipping.
- Product-specific, category-specific, or order-level discounts.
- Buy-one-get-one (BOGO) and bundle discounts.

### Validation Rules
- Enforce usage limits: per-customer, total uses, minimum order amount, valid date range.
- Stack or exclude: define whether multiple codes can combine.
- Calculate discount amounts before tax; display savings clearly on the order summary.

## Abandoned Cart Recovery

### Detection
- Define abandonment: cart with items and no checkout completion within a time window (e.g., 1 hour, 24 hours).
- Track the checkout step where the user dropped off for funnel analysis.

### Recovery Tactics
- Send a sequence of recovery emails (1 hour, 24 hours, 72 hours after abandonment).
- Include a direct link back to the saved cart with items pre-loaded.
- Optionally offer an incentive (discount code) in the second or third email.

### Analytics
- Track recovery email open rates, click-through rates, and conversion rates.
- Measure revenue recovered from abandoned cart campaigns.
- Segment by abandonment stage (cart page vs. shipping vs. payment) to identify friction points.
