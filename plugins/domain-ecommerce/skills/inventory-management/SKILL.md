---
name: inventory-management
description: |
  Inventory management for e-commerce: stock tracking (available, reserved, committed),
  warehouse management, multi-location inventory, backorder handling, reservation patterns
  (soft reserve, hard reserve), stock alerts, and inventory sync across channels.
allowed-tools: Read, Grep, Glob, Bash
---

# Inventory Management

## Stock Tracking

### Quantity Types
- **Available**: units on hand that can be sold.
- **Reserved**: units held for carts or pending orders (not yet committed).
- **Committed**: units allocated to confirmed, unpaid or processing orders.
- **On-hand**: total physical units = available + reserved + committed.

### Stock Ledger
- Maintain an append-only stock movements ledger recording every change (received, sold, returned, adjusted, transferred).
- Each ledger entry: `product_variant_id`, `location_id`, `quantity_change`, `reason`, `reference_id`, `timestamp`.
- Derive current stock levels by summing ledger entries; cache the running total for fast reads.

### Atomic Updates
- Use database-level atomic operations (`UPDATE ... SET available = available - 1 WHERE available > 0`) to prevent overselling.
- Return the updated row count to detect insufficient stock without a separate read.

## Warehouse Management

### Location Modeling
- Define locations as warehouses, stores, or fulfillment centers with address and capabilities (ships-to regions, handling types).
- Assign priority per location for order routing (closest to customer, lowest cost, highest stock).
- Track bin/shelf locations within a warehouse for pick-path optimization.

### Receiving and Putaway
- Record inbound shipments from suppliers with expected vs. actual quantities.
- Generate putaway tasks to assign received stock to bin locations.
- Update available quantities only after putaway confirmation.

## Multi-Location Inventory

### Aggregated vs. Per-Location Views
- Display aggregated availability to the customer (sum across all locations).
- Route orders to the optimal fulfillment location based on proximity, stock, and shipping cost.
- Support "ship from store" for omnichannel retailers.

### Inter-Location Transfers
- Create transfer orders to move stock between locations.
- Track transfer state: requested, in-transit, received.
- Deduct from source and credit to destination atomically on receipt confirmation.

## Backorder Handling

- Allow overselling with a backorder flag when stock reaches zero.
- Display estimated restock dates to the customer at checkout.
- Automatically allocate incoming stock to backorders in FIFO order.
- Send notifications when backordered items ship.

## Inventory Reservation Patterns

### Soft Reserve
- Reserve stock when an item is added to the cart.
- Apply a TTL (e.g., 15 minutes) after which the reservation expires and stock is released.
- Use a background job to sweep expired reservations.

### Hard Reserve
- Reserve stock when the order is placed (payment authorized or confirmed).
- Hold until fulfillment or cancellation.
- Convert from soft to hard reserve at checkout completion.

### Reservation Implementation
- Store reservations in a `stock_reservations` table: `variant_id`, `location_id`, `quantity`, `type` (soft/hard), `expires_at`, `order_id`.
- Decrement available stock on reserve; increment on release or expiry.
- Use optimistic locking or row-level locks to prevent double-reservation race conditions.

## Stock Alerts

### Low Stock Alerts
- Configure reorder points per variant per location.
- Trigger alerts (email, Slack, dashboard notification) when available stock drops below the reorder point.
- Generate suggested purchase orders based on lead times and sales velocity.

### Out-of-Stock Handling
- Hide or badge out-of-stock products on the storefront.
- Offer "notify me when available" signup for customer email capture.
- Track out-of-stock events for demand forecasting.

## Inventory Sync Across Channels

### Multi-Channel
- Sync inventory across your website, marketplaces (Amazon, eBay), and POS systems.
- Use a centralized inventory service as the source of truth.
- Push stock updates to channels via APIs or feeds on a near-real-time schedule.

### Conflict Resolution
- Handle simultaneous sales on multiple channels with centralized reservation.
- If stock is oversold, cancel the later order and notify the customer promptly.
- Allocate safety stock buffers per channel to reduce oversell risk.
