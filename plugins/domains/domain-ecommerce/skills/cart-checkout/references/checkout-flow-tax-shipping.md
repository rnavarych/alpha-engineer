# Checkout Flow, Tax, and Shipping

## When to load
Load when designing checkout UX, integrating shipping aggregators, or wiring up tax engines.

## Checkout Flow Patterns

### Single-Page Checkout
- All steps (address, shipping method, payment, review) on one page with accordion/tab sections.
- Best for stores with few options; reduces page loads and friction.
- Auto-advance to next section; inline field validation.

### Multi-Step Checkout
- Separate pages for address, shipping, payment, review with a progress indicator.
- Persist step data server-side for back-button and refresh handling.
- URL-based steps (`/checkout/shipping`, `/checkout/payment`) for analytics tracking.

### Guest Checkout
- Allow purchase without account creation — typically prevents 10-25% abandonment from forced registration.
- Offer optional post-purchase account creation with pre-filled form.
- Collect email only for confirmation and tracking.
- "Save info for next time" via Apple Pay, Google Pay, or Link by Stripe.

### Checkout Conversion Optimization
- Minimize form fields: ZIP-to-city/state auto-detect, single name field.
- Proper HTML `autocomplete` attributes for browser auto-fill.
- Address autocomplete: Google Places API, Loqate, SmartyStreets.
- Trust signals: security badges, SSL indicator, accepted payment logos, return policy.
- Order summary always visible with totals and applied discounts.
- Save checkout state for return visits.

## Address Validation
- **SmartyStreets**: US and international, USPS certified.
- **Google Address Validation API**: verify and correct via Google Maps data.
- **Loqate**: international capture with type-ahead.
- **USPS Address API**: free US validation, ZIP+4 lookup.
- Suggest corrections with "Did you mean...?" prompts.
- Warn on PO boxes and military addresses (APO/FPO/DPO) for carrier restrictions.

## Shipping Integration

### Aggregators
- **ShipStation**: 100+ carriers, 70+ sales channels, rate comparison, label generation, tracking.
- **Shippo**: 85+ carriers, generous free tier for low-volume shippers.
- **EasyPost**: carrier-agnostic with SmartRate for delivery date optimization.
- **ShipBob**: 3PL + shipping with 2-day network.
- Cache carrier rates 5–15 minutes; circuit-break to flat-rate if carrier APIs are down.

### Shipping Methods
- Standard (5-7 days), Expedited (2-3 days), Overnight, Free (conditional), BOPIS, Curbside, Same-day.
- Display estimated delivery dates based on transit time + warehouse cut-off + processing days.

### Shipping Rules Engine
- Free shipping over $X; flat rate; weight-based tiers; geo-based zones (Alaska, Hawaii, international).
- Product rules: oversized, hazmat, fragile surcharges.
- Multi-warehouse routing: closest to customer or highest available stock.

## Tax Calculation

### Tax Engines
- **Avalara AvaTax**: real-time for US, Canada, EU, 190+ countries. Product tax codes, exemptions, auto-filing.
- **TaxJar**: automated US sales tax with nexus determination. SmartCalcs API.
- **Vertex**: enterprise multi-jurisdictional (B2B, ERP).
- **Stripe Tax**: simple, Stripe-only.
- **TaxCloud**: free US sales tax API.

### Tax in Checkout
- Calculate after shipping address entry (destination determines jurisdiction).
- Pass product tax codes to engine (clothing, food, digital goods differ).
- Handle tax-exempt customers: validate exemption certificates, apply at checkout.
- Tax-inclusive vs. exclusive display per locale (EU: inclusive; US: exclusive).
- Store tax calculation details on order for refund and reporting.
