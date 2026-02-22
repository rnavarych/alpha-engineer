---
name: inventory-management
description: |
  Inventory management for e-commerce: WMS integration (warehouse management systems), dropshipping,
  3PL (ShipBob, Flexport), demand forecasting, lot/batch tracking, inventory valuation (FIFO/LIFO/
  weighted average), cycle counting, stock tracking (available, reserved, committed), multi-location
  inventory, backorder handling, reservation patterns, stock alerts, and inventory sync across channels.
allowed-tools: Read, Grep, Glob, Bash
---

# Inventory Management

## Stock Tracking

### Quantity Types
- **Available**: units on hand that can be sold (eligible for new orders).
- **Reserved**: units held for carts or pending orders (not yet committed).
- **Committed**: units allocated to confirmed, paid, or processing orders.
- **On-hand**: total physical units = available + reserved + committed.
- **In-transit**: units shipped from supplier or transferred between locations (not yet received).
- **Damaged/quarantined**: units removed from sellable stock pending inspection or disposal.
- **Returned**: units received back from customers pending restocking or disposition.

### Stock Ledger
- Maintain an append-only stock movements ledger recording every change (received, sold, returned, adjusted, transferred, damaged, disposed).
- Each ledger entry: `product_variant_id`, `location_id`, `quantity_change` (+/-), `reason`, `reference_id` (order/PO/transfer), `actor`, `timestamp`.
- Derive current stock levels by summing ledger entries; cache the running total for fast reads.
- Use the ledger for audit trail: reconstruct stock levels at any point in time by replaying entries.
- Reconcile ledger-derived totals against physical counts periodically (cycle counting).

### Atomic Updates
- Use database-level atomic operations (`UPDATE ... SET available = available - 1 WHERE available > 0`) to prevent overselling.
- Return the updated row count to detect insufficient stock without a separate read.
- Use row-level locking or optimistic concurrency (version column) to prevent race conditions during high-traffic events.
- For distributed systems, use distributed locks (Redis SETNX) or compare-and-swap operations.
- Consider eventual consistency trade-offs: during flash sales, allow brief overselling and reconcile asynchronously.

## Warehouse Management System (WMS) Integration

### WMS Platforms
- **ShipHero**: cloud-based WMS for e-commerce; direct integrations with Shopify, Amazon, WooCommerce.
- **Deposco**: order management and warehouse execution for mid-market and enterprise.
- **Manhattan Active WM**: enterprise WMS with advanced warehouse optimization and labor management.
- **Logiwa**: cloud fulfillment platform for high-volume B2C and B2B.
- **SkuVault (Linnworks)**: inventory and warehouse management for e-commerce sellers.
- **NetSuite WMS**: ERP-integrated warehouse management with barcode scanning and wave picking.
- **Custom WMS**: in-house solution when off-the-shelf cannot meet unique workflow requirements.

### WMS Integration Patterns
- **Push orders**: send confirmed orders from OMS to WMS via API or message queue for fulfillment.
- **Pull shipments**: receive shipment confirmations, tracking numbers, and package details from WMS.
- **Real-time inventory sync**: WMS publishes inventory updates (received, picked, adjusted) to OMS via webhooks or events.
- **Batch sync**: scheduled inventory file exchange (CSV, EDI 846) for systems lacking real-time APIs.
- **Error handling**: implement dead letter queues for failed order pushes; retry with exponential backoff.
- **Data mapping**: map WMS SKU, location, and status codes to your internal identifiers.

### Location Modeling
- Define locations as warehouses, stores, fulfillment centers, or distribution centers with address and capabilities.
- Track bin/shelf/aisle locations within a warehouse for pick-path optimization.
- Zone-based picking: organize warehouse into zones (ambient, refrigerated, high-value, bulk) with zone-specific workflows.
- Assign priority per location for order routing (closest to customer, lowest cost, highest stock, fastest SLA).

### Receiving and Putaway
- Record inbound shipments from suppliers with expected vs. actual quantities (purchase order receipt).
- Quality inspection: inspect received goods, record defects, accept/reject quantities.
- Generate putaway tasks to assign received stock to bin locations.
- Update available quantities only after putaway confirmation.
- Cross-docking: receive inbound and immediately route to outbound shipment (skip putaway/storage).
- ASN (Advanced Shipping Notice): receive supplier ASN via EDI 856 or API for pre-receipt planning.

### Picking Strategies
- **Discrete picking**: pick one order at a time (simplest, best for low volume or large orders).
- **Batch picking**: pick multiple orders simultaneously, sort into individual orders at packing station.
- **Wave picking**: group orders into waves based on shipping method, priority, or zone; pick per wave.
- **Zone picking**: assign pickers to warehouse zones; orders move through zones, each picker adds their items.
- **Pick-to-light**: light-directed picking with bin indicators (high accuracy, fast for high-volume).
- **Voice picking**: voice-directed picking via headset (hands-free, suitable for cold storage).
- **Barcode/RFID scanning**: validate picked items against order to prevent errors.

## Dropshipping

### Dropshipping Model
- Merchant lists products without holding inventory; supplier ships directly to customer.
- No upfront inventory investment; lower risk, lower margin.
- Merchant handles storefront, marketing, and customer service; supplier handles fulfillment.

### Dropshipping Integration
- **Supplier catalogs**: import supplier product data (via CSV, API, or platforms like Oberlo, Spocket, Modalyst, DSers).
- **Order routing**: when a customer places an order, automatically forward to the supplier for fulfillment.
- **Inventory sync**: sync supplier stock levels to prevent selling out-of-stock items (real-time API or periodic feed).
- **Tracking passthrough**: receive tracking numbers from supplier; forward to customer.
- **Returns**: define return flow (customer returns to you or directly to supplier; restocking fees).
- **Pricing**: apply markup to supplier cost price; auto-update when supplier prices change.

### Dropshipping Platforms
- **DSers / CJ Dropshipping**: AliExpress-based dropshipping with order automation.
- **Spocket**: curated US/EU suppliers with faster shipping (vs. AliExpress).
- **Modalyst**: branded dropshipping with independent brands and suppliers.
- **Inventory Source**: supplier directory with automated inventory sync and order routing.
- **Printful / Printify**: print-on-demand dropshipping for custom apparel, accessories, and home goods.

### Dropshipping Challenges
- Shipping time: manage customer expectations (AliExpress: 15-30 days; US/EU suppliers: 3-7 days).
- Quality control: limited ability to inspect products; rely on supplier reputation and sampling.
- Branding: custom packaging and inserts depend on supplier capabilities.
- Returns and refunds: complex when supplier is overseas or has restrictive return policies.
- Margin pressure: competition drives prices down; differentiate via branding, content, and customer experience.

## 3PL (Third-Party Logistics)

### 3PL Providers
- **ShipBob**: e-commerce 3PL with distributed fulfillment centers, 2-day shipping, and real-time analytics. API and direct integrations with Shopify, BigCommerce, WooCommerce.
- **Flexport**: global logistics platform for freight forwarding, customs brokerage, warehousing, and last-mile delivery. Strong for international supply chain.
- **ShipMonk**: 3PL for DTC brands with custom packaging, subscription box fulfillment, and Amazon FBA prep.
- **Deliverr (now Flexport)**: 2-day fulfillment network with distributed inventory across US warehouses.
- **Red Stag Fulfillment**: specialized in heavy, oversized, and high-value items.
- **Amazon FBA (Fulfillment by Amazon)**: use Amazon's warehouse network; products eligible for Prime shipping.
- **Rakuten Super Logistics (ShipNetwork)**: 1-2 day ground shipping via distributed warehouse network.

### 3PL Integration Patterns
- **Order push**: send confirmed orders to 3PL via API; receive shipment confirmation with tracking.
- **Inventory feed**: receive daily or real-time inventory snapshots from 3PL warehouses.
- **Inbound shipments**: create inbound shipment (ASN) with expected SKUs and quantities; 3PL receives and confirms.
- **Returns processing**: 3PL receives returns, inspects, and updates inventory (or quarantines); reports back to merchant.
- **Billing reconciliation**: 3PL bills for storage, pick/pack, shipping, and value-added services; reconcile against orders.
- **SLA monitoring**: track fulfillment speed, accuracy, and damage rates per 3PL.

### 3PL vs. In-House Fulfillment
- 3PL pros: no warehouse lease, scalable capacity, geographic distribution, carrier discounts.
- 3PL cons: less control over packing/branding, per-order fees eat into margins, complex returns.
- In-house pros: full control over quality, custom packaging, faster iteration on fulfillment process.
- In-house cons: capital investment (lease, equipment, labor), limited geographic reach, capacity constraints during peaks.
- Hybrid: own warehouse for core fulfillment, 3PL for overflow, geographic expansion, or specific product lines.

## Demand Forecasting

### Forecasting Methods
- **Time series analysis**: use historical sales data to identify trends, seasonality, and cyclicality.
- **Moving average**: simple or weighted moving average over N periods (30-day, 90-day rolling average).
- **Exponential smoothing**: weight recent data more heavily (Holt-Winters for trend + seasonality).
- **ARIMA/SARIMA**: autoregressive models for stationary/seasonal time series.
- **Machine learning**: gradient boosting (XGBoost, LightGBM), neural networks (LSTM, Transformer) for complex patterns.
- **Causal models**: incorporate external factors (marketing spend, weather, competitor pricing, economic indicators).

### Forecasting Inputs
- Historical sales data: daily/weekly unit sales per SKU per location.
- Promotional calendar: planned sales events, discount periods, marketing campaigns.
- Seasonal patterns: holiday peaks, back-to-school, seasonal products.
- Market trends: category growth rates, competitor activity, new product launches.
- Lead times: supplier production and shipping times (buffer for variability).
- External data: weather forecasts (for weather-sensitive products), economic indicators, event calendars.

### Forecasting Outputs
- **Demand plan**: projected unit sales per SKU per period (week, month, quarter).
- **Replenishment plan**: purchase order quantities and timing based on demand, lead time, and safety stock.
- **Safety stock calculation**: buffer stock = Z-score x standard deviation of demand during lead time.
- **Reorder point**: trigger replenishment when stock falls below (average daily demand x lead time) + safety stock.
- **Economic Order Quantity (EOQ)**: optimal order quantity minimizing total cost (ordering cost + holding cost).

### Forecasting Tools
- **Inventory Planner (Sage)**: Shopify/BigCommerce app for demand forecasting and replenishment planning.
- **Flieber**: e-commerce inventory planning with demand forecasting and purchase order automation.
- **Lokad**: quantitative supply chain optimization with probabilistic forecasting.
- **Amazon Forecast**: AWS ML service for time series forecasting.
- **Prophet (Meta)**: open-source forecasting library for time series with seasonality and holiday effects.
- **Custom models**: build in-house using Python (scikit-learn, statsmodels, PyTorch) + data warehouse.

## Lot / Batch Tracking

### Lot Tracking Model
- Assign a lot/batch number to inventory received together (same production run, supplier shipment, or purchase order).
- Track lot at the variant + location level: `variant_id`, `location_id`, `lot_number`, `quantity`, `received_date`, `expiry_date`.
- Record lot number on order line items for traceability (which lot was shipped to which customer).
- Essential for: food & beverage, cosmetics, pharmaceuticals, supplements, and any regulated product.

### Expiration Management
- FEFO (First Expired, First Out): pick and ship items closest to expiration first.
- Expiration alerts: notify when lots approach expiration date (configurable threshold, e.g., 30/60/90 days).
- Auto-quarantine: remove expired lots from sellable inventory automatically.
- Short-dated discounting: automatically reduce price for items nearing expiration (clearance).
- Disposal workflow: document disposal of expired or damaged lots for regulatory compliance.

### Recall Management
- Lot-level recall: identify all orders containing a specific lot number.
- Customer notification: automatically generate recall notices for affected customers.
- Quarantine affected inventory across all locations.
- Track recall response: monitor return/replacement rates for recalled lots.
- Regulatory reporting: generate lot traceability reports for FDA, USDA, or other regulatory bodies.

### Serial Number Tracking
- Track individual units by serial number (high-value electronics, luxury goods, equipment).
- Capture serial number at receiving, assign to order at fulfillment.
- Warranty management: link serial number to warranty terms and customer for support.
- Anti-counterfeiting: verify serial number authenticity for returns and warranty claims.

## Inventory Valuation

### FIFO (First In, First Out)
- Assume oldest inventory is sold first.
- Cost of goods sold (COGS) based on the cost of the oldest units in stock.
- Common for perishable goods and most e-commerce businesses.
- In inflationary environments, FIFO results in lower COGS and higher taxable income.
- Implementation: maintain a queue of purchase costs per SKU; dequeue from the front on each sale.

### LIFO (Last In, First Out)
- Assume newest inventory is sold first.
- COGS based on the cost of the most recently purchased units.
- Not permitted under IFRS (only allowed under US GAAP).
- In inflationary environments, LIFO results in higher COGS and lower taxable income (tax advantage).
- Implementation: maintain a stack of purchase costs per SKU; pop from the top on each sale.

### Weighted Average Cost
- Calculate average cost across all units in stock: total cost of inventory / total units.
- Recalculate after each purchase or receipt.
- Simpler than FIFO/LIFO; smooths out cost fluctuations.
- Common for businesses with many similar items and frequent purchases.
- Implementation: maintain running total cost and total quantity; divide for average unit cost.

### Specific Identification
- Track the actual cost of each specific unit (by serial number or lot).
- Required for unique, high-value items (jewelry, art, vehicles, custom goods).
- Most accurate but most complex to maintain.
- Implementation: record purchase cost per individual unit or lot; match to sale.

### Inventory Valuation Reporting
- Generate inventory valuation report: total units x unit cost = total inventory value per SKU.
- Landed cost: include purchase price + freight + customs duties + insurance for true unit cost.
- Write-down: reduce inventory value for damaged, obsolete, or slow-moving stock (lower of cost or net realizable value).
- Periodic vs. perpetual inventory system: perpetual updates valuation on every transaction; periodic recalculates at period end.

## Cycle Counting

### Cycle Counting vs. Full Physical Count
- **Full physical count**: count all inventory at once (disruptive, requires warehouse shutdown, done annually).
- **Cycle counting**: count a subset of inventory regularly (daily/weekly) with no shutdown; covers all items over a cycle.
- Cycle counting provides more frequent accuracy checks with less operational disruption.

### Cycle Counting Methods
- **ABC analysis**: count A items (high value, 80% of revenue) most frequently (monthly), B items quarterly, C items annually.
- **Random sampling**: randomly select SKUs/locations to count each cycle.
- **Usage-based**: count high-velocity SKUs more frequently.
- **Location-based**: rotate through warehouse locations systematically.
- **Discrepancy-triggered**: initiate a count when stock levels seem incorrect (negative stock, unexpected zero).

### Cycle Counting Process
1. Generate count list: select SKUs/locations for the current cycle.
2. Count: warehouse staff physically counts units (barcode scanner or manual entry).
3. Compare: system compares counted quantity to system quantity.
4. Investigate variances: flag discrepancies exceeding a threshold (e.g., >2% or >5 units).
5. Adjust: approve adjustments, record reason codes (shrinkage, damage, receiving error, system error).
6. Report: track count accuracy rate, adjustment frequency, and variance value over time.

### Inventory Accuracy Metrics
- **Inventory accuracy rate**: (matching counts / total counts) x 100%. Target: >97%.
- **Variance value**: total dollar value of inventory adjustments (target: minimize).
- **Shrinkage rate**: (unaccounted-for inventory loss / total inventory value) x 100%.
- **Days of inventory on hand**: average inventory / average daily sales (target: balance carrying cost vs. stockout risk).
- **Stockout rate**: percentage of time a SKU is unavailable for sale (target: <2% for key items).

## Multi-Location Inventory

### Aggregated vs. Per-Location Views
- Display aggregated availability to the customer (sum across all locations).
- Route orders to the optimal fulfillment location based on proximity, stock, and shipping cost.
- Support "ship from store" for omnichannel retailers.
- Per-location inventory dashboards for warehouse managers and store associates.

### Order Routing / Distributed Order Management
- Define routing rules: closest warehouse to customer, warehouse with full order availability, lowest shipping cost.
- Split orders across locations when no single location has all items (vs. hold for complete fulfillment).
- Priority routing: prefer owned warehouses over 3PL; prefer fulfillment centers over stores.
- Capacity constraints: limit daily orders per location to prevent overwhelming a single warehouse.
- SLA-based routing: route to location that can meet the promised delivery date.

### Inter-Location Transfers
- Create transfer orders to move stock between locations.
- Track transfer state: requested, approved, in-transit, received, cancelled.
- Deduct from source and credit to destination atomically on receipt confirmation.
- Transfer cost tracking: freight cost, labor cost allocated to the transfer.
- Planned transfers: proactively redistribute inventory based on demand forecasts per location.

## Backorder and Preorder Handling

### Backorder
- Allow overselling with a backorder flag when stock reaches zero.
- Display estimated restock dates to the customer at checkout.
- Automatically allocate incoming stock to backorders in FIFO order.
- Send notifications when backordered items ship.
- Separate backorder items from in-stock items in fulfillment workflows.

### Preorder
- List products for sale before they are in stock (upcoming launches, restocks).
- Collect payment at preorder time (full or deposit) or charge when item ships.
- Display expected ship date prominently on product page and checkout.
- Limit preorder quantities based on expected supply.
- Automatically convert preorders to regular orders when inventory is received.

## Inventory Reservation Patterns

### Soft Reserve
- Reserve stock when an item is added to the cart.
- Apply a TTL (e.g., 15 minutes) after which the reservation expires and stock is released.
- Use a background job to sweep expired reservations.
- Prevents most overselling during flash sales but adds complexity.

### Hard Reserve
- Reserve stock when the order is placed (payment authorized or confirmed).
- Hold until fulfillment or cancellation.
- Convert from soft to hard reserve at checkout completion.
- Hard reserves are only released on order cancellation or fulfillment failure.

### Reservation Implementation
- Store reservations in a `stock_reservations` table: `variant_id`, `location_id`, `quantity`, `type` (soft/hard), `expires_at`, `order_id`, `created_at`.
- Decrement available stock on reserve; increment on release or expiry.
- Use optimistic locking or row-level locks to prevent double-reservation race conditions.
- For high-concurrency scenarios (flash sales), consider queue-based reservation processing.

## Stock Alerts and Reorder Automation

### Low Stock Alerts
- Configure reorder points per variant per location.
- Trigger alerts (email, Slack, dashboard notification, PagerDuty) when available stock drops below the reorder point.
- Generate suggested purchase orders based on lead times, sales velocity, and EOQ formulas.
- Distinguish between seasonal and evergreen reorder points.

### Out-of-Stock Handling
- Hide or badge out-of-stock products on the storefront (configurable per product).
- Offer "notify me when available" signup for customer email/SMS capture.
- Track out-of-stock events for demand forecasting and lost revenue estimation.
- Auto-delist from marketplace feeds (Google Shopping, Amazon) when out of stock.

### Reorder Automation
- Automated purchase order generation when stock hits reorder point.
- PO routing: send PO to appropriate supplier based on product-supplier mapping.
- Approval workflows: auto-approve POs below a threshold; require manager approval above.
- PO tracking: expected delivery date, partial receipt, full receipt, supplier performance scoring.

## Inventory Sync Across Channels

### Multi-Channel
- Sync inventory across your website, marketplaces (Amazon, eBay, Walmart, Etsy), and POS systems.
- Use a centralized inventory service as the source of truth.
- Push stock updates to channels via APIs or feeds on a near-real-time schedule.
- Channel-specific buffer stock: reserve a percentage of inventory for each channel to prevent over-allocation.

### Multi-Channel Platforms
- **Channable**: product feed management and marketplace integration for European markets.
- **ChannelAdvisor (CommerceHub)**: enterprise multi-channel commerce with inventory sync across 100+ marketplaces.
- **Sellbrite (GoDataFeed)**: multi-channel listing and inventory sync for SMBs.
- **Linnworks**: multi-channel order and inventory management with warehouse integration.
- **Zentail**: AI-powered multi-channel listing and inventory optimization.

### Conflict Resolution
- Handle simultaneous sales on multiple channels with centralized reservation.
- If stock is oversold, cancel the later order and notify the customer promptly.
- Allocate safety stock buffers per channel to reduce oversell risk.
- Near-real-time sync (every 1-5 minutes) vs. real-time (event-driven) based on system capabilities.
- Last-unit problem: when only 1 unit remains, consider listing on only one channel or accepting oversell risk.
