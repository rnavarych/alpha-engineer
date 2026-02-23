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

## When to use
- Designing or rebuilding a shopping cart (storage strategy, data model, merge logic)
- Implementing express checkout methods (Apple Pay, Google Pay, Shop Pay, Amazon Pay)
- Building or integrating a checkout flow (single-page, multi-step, guest checkout)
- Wiring up shipping aggregators or tax engines (Avalara, TaxJar, ShipStation, EasyPost)
- Building a promotion/discount engine with rules, stacking, and abuse prevention
- Setting up abandoned cart recovery sequences (Klaviyo, Omnisend, or custom)
- Implementing BOPIS with real-time store inventory and pickup notifications

## Core principles
1. **Validate the cart on every read** — prices, stock, and promotions change; never trust a stale cart total
2. **Express checkout above the fold** — Apple Pay + Google Pay on product pages and cart converts before standard checkout even loads
3. **Guest checkout is not optional** — forced registration causes 10-25% abandonment; post-purchase signup instead
4. **Shipping rate circuit breaker** — always fall back to flat-rate if carrier APIs are down; never block checkout
5. **Recovery sequence timing matters** — T+1h (reminder), T+24h (urgency), T+72h (discount); discount-first burns margin

## Reference Files
- `references/cart-architecture.md` — storage strategies (session/DB/Redis/headless/hybrid), data model, cart merging, cart validation
- `references/express-checkout.md` — Apple Pay, Google Pay, Shop Pay, Amazon Pay integration patterns and best practices
- `references/checkout-flow-tax-shipping.md` — single-page vs. multi-step checkout, guest flow, address validation, shipping aggregators, tax engine integration
- `references/promotions-recovery-bopis.md` — promotion engine architecture, discount types, Klaviyo/Omnisend cart recovery, BOPIS flow and technical requirements
