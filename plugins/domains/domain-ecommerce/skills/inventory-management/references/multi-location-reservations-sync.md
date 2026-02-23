# Multi-Location Inventory, Reservations, and Channel Sync

## When to load
Load when building multi-warehouse order routing, inventory reservation patterns, backorder/preorder handling, stock alert automation, or multi-channel inventory sync.

## Multi-Location Inventory

### Aggregated vs. Per-Location Views
- Display aggregated availability to customers (sum across all locations).
- Route orders to optimal fulfillment location: proximity, stock level, shipping cost.
- Support "ship from store" for omnichannel retailers.
- Per-location dashboards for warehouse managers and store associates.

### Order Routing (DOM — Distributed Order Management)
- Routing rules: closest warehouse to customer, single location with full order availability, lowest shipping cost.
- Split orders across locations when no single location has all items.
- Priority routing: owned warehouses > 3PL > stores.
- Capacity constraints: limit daily orders per location.
- SLA-based routing: route to location that can meet promised delivery date.

### Inter-Location Transfers
- Transfer orders with states: requested, approved, in-transit, received, cancelled.
- Deduct from source and credit to destination atomically on receipt confirmation.
- Transfer cost tracking: freight + labor allocated to transfer.
- Proactive redistribution based on demand forecasts per location.

## Backorder and Preorder

### Backorder
- Allow overselling with backorder flag when stock reaches zero.
- Display estimated restock dates at checkout.
- Allocate incoming stock to backorders in FIFO order automatically.
- Send notifications when backordered items ship.
- Separate backorder items from in-stock items in fulfillment workflows.

### Preorder
- List products for sale before they are in stock (launches, restocks).
- Collect full payment or deposit at preorder; charge remainder when ships.
- Display expected ship date prominently on PDP and checkout.
- Limit preorder quantities based on expected supply.
- Auto-convert preorders to regular orders when inventory is received.

## Inventory Reservation Patterns

### Soft Reserve
- Reserve stock when item added to cart.
- Apply TTL (e.g., 15 minutes); sweep expired reservations via background job.
- Prevents most overselling during flash sales but adds complexity.

### Hard Reserve
- Reserve stock when order is placed (payment authorized).
- Hold until fulfillment or cancellation; convert from soft to hard at checkout completion.
- Released only on cancellation or fulfillment failure.

### Implementation
- `stock_reservations` table: `variant_id`, `location_id`, `quantity`, `type` (soft/hard), `expires_at`, `order_id`, `created_at`.
- Decrement available on reserve; increment on release or expiry.
- Optimistic locking or row-level locks to prevent double-reservation.
- High-concurrency (flash sales): queue-based reservation processing.

## Stock Alerts and Reorder Automation

### Low Stock Alerts
- Configure reorder points per variant per location.
- Trigger alerts (email, Slack, PagerDuty) when available stock drops below reorder point.
- Generate suggested POs based on lead times, sales velocity, and EOQ.
- Distinguish seasonal vs. evergreen reorder points.

### Out-of-Stock Handling
- Hide or badge out-of-stock products on storefront (configurable per product).
- "Notify me when available" email/SMS capture.
- Track out-of-stock events for forecasting and lost revenue estimation.
- Auto-delist from marketplace feeds (Google Shopping, Amazon) when out of stock.

### Reorder Automation
- Auto-generate POs when stock hits reorder point.
- PO routing: send to appropriate supplier by product-supplier mapping.
- Approval workflows: auto-approve below threshold; manager approval above.
- PO tracking: expected delivery date, partial receipt, full receipt, supplier scoring.

## Inventory Sync Across Channels

### Multi-Channel Strategy
- Centralized inventory service as single source of truth.
- Push stock updates to all channels via API or feeds near-real-time.
- Channel-specific buffer stock: reserve percentage per channel to prevent over-allocation.

### Platforms
- **ChannelAdvisor (CommerceHub)**: enterprise multi-channel across 100+ marketplaces.
- **Linnworks**: multi-channel order and inventory management with warehouse integration.
- **Channable**: product feeds and marketplace integration (strong in European markets).
- **Zentail**: AI-powered multi-channel listing and inventory optimization.

### Conflict Resolution
- Handle simultaneous sales across channels with centralized reservation.
- On oversell: cancel the later order and notify customer promptly.
- Near-real-time sync (1-5 min) vs. real-time (event-driven) based on system capability.
- Last-unit problem: list on one channel only or accept oversell risk when single unit remains.
