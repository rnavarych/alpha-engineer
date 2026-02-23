# Cart Architecture

## When to load
Load when designing cart storage, data model, cart merging, or cart validation logic.

## Storage Strategies
- **Session-based**: server-side session or cookie. Simple but lost on session expiry. Low-traffic only.
- **Database-backed**: `cart_items` table keyed by user ID or session ID. Survives restarts; cross-device persistence.
- **Redis**: hash or JSON with TTL. Fast reads; use Redis Cluster for horizontal scale.
- **Headless cart API**: platform-managed (Shopify Storefront API, commercetools, Medusa). Frontend is stateless.
- **Hybrid**: Redis for hot cart (active sessions), DB for cold storage (abandoned carts); sync on checkout start.

## Cart Data Model
- Cart entity: `cart_id`, `customer_id` (nullable guest), `session_id`, `status` (active/merged/converted/abandoned), `currency`, `created_at`, `updated_at`, `expires_at`.
- Line items: `line_id`, `cart_id`, `variant_id`, `quantity`, `unit_price`, `line_total`, `metadata` (customization, gift wrap, subscription options).
- Cart-level data: shipping/billing address, selected shipping method, applied promotions, notes.
- Cart totals: subtotal, discount total, shipping total, tax total, grand total — recalculate on every modification.

## Cart Merging
- On anonymous-to-authenticated login: merge session cart with saved cart.
- Merge strategies: keep higher quantity, sum quantities, or prompt user.
- Transfer items from session key to user ID in the backing store.
- Preserve applied promotions and selections during merge where possible.
- Handle cross-device merge (mobile add, desktop login).

## Cart Validation
- Re-validate prices, stock, and promo eligibility on every cart view and at checkout start.
- Display warnings for out-of-stock items or price changes since addition.
- Remove or disable unavailable items automatically with clear messaging.
- Validate minimum/maximum order quantities per product.
- Enforce minimum order amount for checkout eligibility.
- Check product-level restrictions: age verification, hazmat, alcohol, regional availability.
