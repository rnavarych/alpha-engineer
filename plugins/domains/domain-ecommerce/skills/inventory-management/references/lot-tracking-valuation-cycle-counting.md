# Lot Tracking, Inventory Valuation, and Cycle Counting

## When to load
Load when implementing lot/batch/serial number tracking, inventory valuation methods (FIFO/LIFO/WAC), or cycle counting workflows.

## Lot and Batch Tracking

### Data Model
- Assign lot/batch number to inventory received together (same production run, PO, or shipment).
- Track at variant + location level: `variant_id`, `location_id`, `lot_number`, `quantity`, `received_date`, `expiry_date`.
- Record lot number on order line items for traceability (which lot shipped to which customer).
- Required for: food, cosmetics, pharmaceuticals, supplements, and any regulated product.

### Expiration Management
- **FEFO** (First Expired, First Out): pick items closest to expiration first.
- Expiration alerts: configurable threshold (30/60/90 days before expiry).
- Auto-quarantine expired lots from sellable inventory.
- Short-dated discounting: auto-reduce price for items nearing expiry.
- Disposal workflow: document disposal for regulatory compliance.

### Recall Management
- Identify all orders containing a specific lot number.
- Auto-generate recall notices for affected customers.
- Quarantine affected inventory across all locations.
- Track return/replacement rates for recalled lots.
- Regulatory reporting: lot traceability for FDA, USDA, or applicable bodies.

### Serial Number Tracking
- Track individual units (high-value electronics, luxury goods, equipment).
- Capture at receiving; assign to order at fulfillment.
- Warranty management linked to serial number and customer.
- Anti-counterfeiting: verify serial authenticity for returns and warranty claims.

## Inventory Valuation

### FIFO (First In, First Out)
- Oldest inventory sold first. COGS based on oldest unit costs.
- Common for perishables and most e-commerce. Inflationary: lower COGS, higher taxable income.
- Implementation: queue of purchase costs per SKU; dequeue from front on each sale.

### LIFO (Last In, First Out)
- Newest inventory sold first. COGS based on most recent purchase costs.
- **Not permitted under IFRS** — US GAAP only. Inflationary: higher COGS, lower taxable income (tax advantage).
- Implementation: stack of purchase costs per SKU; pop from top on each sale.

### Weighted Average Cost (WAC)
- Average cost = total inventory cost / total units. Recalculate after each purchase/receipt.
- Simpler than FIFO/LIFO; smooths cost fluctuations. Common for frequent purchases of similar items.
- Implementation: running total cost and quantity; divide for average unit cost.

### Specific Identification
- Actual cost of each specific unit tracked by serial number or lot.
- Required for unique, high-value items (jewelry, art, vehicles, custom goods).
- Most accurate; most complex. Implementation: purchase cost recorded per individual unit or lot.

### Valuation Reporting
- Inventory valuation report: total units × unit cost = total inventory value per SKU.
- **Landed cost**: purchase price + freight + customs + insurance = true unit cost.
- **Write-down**: reduce value for damaged, obsolete, or slow-moving stock (lower of cost or NRV).
- Perpetual vs. periodic: perpetual updates on every transaction; periodic recalculates at period end.

## Cycle Counting

### vs. Full Physical Count
- Full count: all inventory at once — disruptive, requires shutdown, done annually.
- Cycle counting: subset regularly (daily/weekly), no shutdown, covers all items over a cycle.
- More frequent accuracy checks with less operational disruption.

### Methods
- **ABC analysis**: A items (80% revenue) monthly; B items quarterly; C items annually.
- **Random sampling**: randomly select SKUs/locations each cycle.
- **Usage-based**: high-velocity SKUs counted more frequently.
- **Discrepancy-triggered**: count when stock seems incorrect (negative stock, unexpected zero).

### Process
1. Generate count list (select SKUs/locations for current cycle).
2. Staff physically counts units via barcode scanner or manual entry.
3. System compares counted quantity to system quantity.
4. Flag discrepancies above threshold (>2% or >5 units).
5. Approve adjustments with reason codes (shrinkage, damage, receiving error, system error).
6. Report accuracy rate, adjustment frequency, and variance value.

### Accuracy Metrics
- **Inventory accuracy rate**: (matching counts / total counts) × 100% — target >97%.
- **Variance value**: total dollar value of inventory adjustments.
- **Shrinkage rate**: (unaccounted loss / total inventory value) × 100%.
- **Days on hand**: average inventory / average daily sales.
- **Stockout rate**: % of time a SKU is unavailable — target <2% for key items.
