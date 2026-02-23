# Order State Machine and Fulfillment Workflows

## When to load
Load when designing order state machines, fulfillment workflows, split shipments, or warehouse integration patterns.

## Order State Machine

### Core States
- **Pending**: order placed, awaiting payment confirmation.
- **Confirmed**: payment captured or authorized successfully.
- **Processing**: order sent to fulfillment (picking and packing).
- **Shipped**: carrier picked up package; tracking number assigned.
- **Delivered**: carrier confirms delivery.
- **Cancelled**: order cancelled before shipment (by customer or system).
- **Returned**: items returned after delivery (RMA completed).

### State Transitions
- Define allowed transitions explicitly: `confirmed → processing`, `processing → shipped`, etc.
- Reject invalid transitions with clear error messages.
- Log every transition with timestamp, actor (user/system), and reason.

### Implementation
- Model in code using a state machine library or a simple enum + transition table.
- Store current state on order record; full transition history in `order_events` table.
- Use database transactions to update state and record the event atomically.

## Fulfillment Workflows

### Pick, Pack, Ship
- Generate pick lists grouped by warehouse zone for efficient picking.
- Validate picked items against the order (barcode scanning).
- Generate packing slips and shipping labels via carrier APIs.
- Record package weight and dimensions for accurate shipping charges.

### Warehouse Integration
- Push orders to WMS or 3PL via API on confirmation.
- Poll or receive webhooks for shipment confirmations and tracking numbers.
- Handle partial fulfillment when some items are unavailable at the assigned warehouse.

## Split Shipments
- Split an order into multiple shipments when items are at different locations or have different availability dates.
- Track each shipment independently with its own tracking number and state.
- Charge shipping once or proportionally; communicate clearly to the customer.
- Aggregate shipment statuses to derive overall order status.

## Invoice and Receipt Generation
- Generate invoices on order confirmation with line items, taxes, shipping, and discounts.
- PDF generation via Puppeteer, wkhtmltopdf, or a templating service.
- Legally required fields: invoice number, seller/buyer details, tax ID, itemized taxes.
- Send receipts via email with PDF attached or as hosted link.
- Store invoices in object storage (S3) with references on the order record.
