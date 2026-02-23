# Stock Tracking and WMS Integration

## When to load
Load when designing stock quantity models, ledger patterns, atomic updates, WMS integration, or warehouse picking strategies.

## Stock Quantity Types
- **Available**: units on hand eligible for new orders.
- **Reserved**: units held for carts or pending orders (not yet committed).
- **Committed**: units allocated to confirmed, paid, or processing orders.
- **On-hand**: total physical = available + reserved + committed.
- **In-transit**: shipped from supplier or transferred between locations; not yet received.
- **Damaged/quarantined**: removed from sellable stock pending inspection or disposal.
- **Returned**: received back from customers pending restocking or disposition.

## Stock Ledger Pattern
- Append-only ledger recording every stock change: received, sold, returned, adjusted, transferred, damaged, disposed.
- Each entry: `product_variant_id`, `location_id`, `quantity_change` (+/-), `reason`, `reference_id` (order/PO/transfer), `actor`, `timestamp`.
- Derive current levels by summing ledger entries; cache the running total for fast reads.
- Reconstruct stock at any point in time by replaying entries — full audit trail.
- Reconcile ledger totals against physical counts via cycle counting.

## Atomic Updates
- `UPDATE ... SET available = available - 1 WHERE available > 0` — prevent overselling at DB level.
- Return updated row count to detect insufficient stock without a separate read.
- Row-level locking or optimistic concurrency (version column) to prevent race conditions.
- Distributed systems: Redis SETNX locks or compare-and-swap for distributed atomicity.
- Flash sales: accept brief overselling, reconcile asynchronously (eventual consistency trade-off).

## WMS Platforms
- **ShipHero**: cloud WMS for e-commerce; direct Shopify, Amazon, WooCommerce integrations.
- **Deposco**: order management + warehouse execution for mid-market and enterprise.
- **Manhattan Active WM**: enterprise with warehouse optimization and labor management.
- **Logiwa**: cloud fulfillment for high-volume B2C and B2B.
- **NetSuite WMS**: ERP-integrated WMS with barcode scanning and wave picking.

## WMS Integration Patterns
- **Push orders**: confirmed orders from OMS to WMS via API or message queue.
- **Pull shipments**: receive shipment confirmations, tracking numbers, package details from WMS.
- **Real-time inventory sync**: WMS publishes inventory updates via webhooks or events.
- **Batch sync**: scheduled file exchange (CSV, EDI 846) for systems without real-time APIs.
- Error handling: dead letter queues for failed order pushes; retry with exponential backoff.
- Data mapping: map WMS SKU, location, and status codes to internal identifiers.

## Location Modeling
- Locations: warehouses, stores, fulfillment centers, distribution centers — each with address and capabilities.
- Bin/shelf/aisle locations within warehouse for pick-path optimization.
- Zone-based picking: ambient, refrigerated, high-value, bulk — zone-specific workflows.
- Priority routing per location: closest to customer, lowest cost, highest stock, fastest SLA.

## Receiving and Putaway
- Record inbound shipments with expected vs. actual quantities (PO receipt).
- Quality inspection: accept/reject quantities, record defects.
- Generate putaway tasks; update available quantities only after putaway confirmation.
- Cross-docking: receive inbound and immediately route to outbound (skip putaway).
- ASN via EDI 856 or API for pre-receipt planning.

## Picking Strategies
- **Discrete**: one order at a time — simplest, best for low volume or large orders.
- **Batch**: pick multiple orders simultaneously; sort at packing station.
- **Wave**: group orders by shipping method, priority, or zone.
- **Zone**: pickers assigned to zones; orders move through each zone.
- **Pick-to-light**: light-directed bin indicators — high accuracy, fast for high volume.
- **Voice picking**: hands-free via headset — suitable for cold storage.
- Barcode/RFID scanning validates picked items against order to prevent errors.
