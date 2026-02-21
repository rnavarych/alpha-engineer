---
name: order-processing
description: |
  Order processing for e-commerce: order state machine (pending through delivered/cancelled/returned),
  fulfillment workflows, returns/exchanges (RMA), invoice/receipt generation, order event sourcing,
  split shipments, and order notifications.
allowed-tools: Read, Grep, Glob, Bash
---

# Order Processing

## Order State Machine

### Core States
- **Pending**: order placed, awaiting payment confirmation.
- **Confirmed**: payment captured or authorized successfully.
- **Processing**: order sent to fulfillment (picking and packing).
- **Shipped**: carrier has picked up the package; tracking number assigned.
- **Delivered**: carrier confirms delivery.
- **Cancelled**: order cancelled before shipment (by customer or system).
- **Returned**: items returned after delivery (RMA completed).

### State Transitions
- Define allowed transitions explicitly (e.g., `confirmed -> processing`, `processing -> shipped`).
- Reject invalid transitions with clear error messages.
- Log every transition with timestamp, actor (user/system), and reason.

### Implementation
- Model the state machine in code using a state machine library or a simple enum + transition table.
- Store the current state on the order record and the full transition history in an `order_events` table.
- Use database transactions to update state and record the event atomically.

## Fulfillment Workflows

### Pick, Pack, Ship
- Generate pick lists grouped by warehouse zone for efficient picking.
- Validate picked items against the order (barcode scanning).
- Generate packing slips and shipping labels via carrier APIs.
- Record package weight and dimensions for accurate shipping charges.

### Warehouse Integration
- Push orders to a WMS (Warehouse Management System) or 3PL (third-party logistics) via API.
- Poll or receive webhooks for shipment confirmations and tracking numbers.
- Handle partial fulfillment when some items are out of stock at the assigned warehouse.

## Split Shipments

- Split an order into multiple shipments when items are at different locations or have different availability dates.
- Track each shipment independently with its own tracking number and state.
- Charge shipping once or proportionally; communicate clearly to the customer.
- Aggregate shipment statuses to derive the overall order status.

## Returns and Exchanges (RMA)

### Return Flow
1. Customer initiates a return request (portal or customer service).
2. System generates an RMA number and return shipping label.
3. Customer ships items back.
4. Warehouse receives and inspects returned items.
5. System processes refund or exchange based on inspection outcome.

### Policies
- Define return window (e.g., 30 days from delivery).
- Specify conditions: unopened, defective, wrong item, buyer's remorse.
- Calculate restocking fees if applicable.
- Track return reasons for product quality and catalog improvement insights.

### Exchanges
- Create a new order linked to the original for exchange items.
- Handle price differences (charge or refund the delta).
- Reserve exchange inventory upon RMA approval.

## Invoice and Receipt Generation

- Generate invoices on order confirmation with line items, taxes, shipping, and discounts.
- Use a PDF generation library (Puppeteer, wkhtmltopdf, or a templating service).
- Include legally required fields: invoice number, seller/buyer details, tax ID, itemized taxes.
- Send receipts via email with the PDF attached or as a hosted link.
- Store invoices in object storage (S3) with references on the order record.

## Order Event Sourcing

### Event Log
- Record every order-related event: `OrderPlaced`, `PaymentCaptured`, `ItemPicked`, `Shipped`, `Delivered`, `Refunded`.
- Each event contains: `order_id`, `event_type`, `payload` (JSON), `actor`, `timestamp`.
- Rebuild order state at any point in time by replaying events.

### Benefits
- Complete audit trail for compliance and customer service.
- Enable asynchronous downstream processing (analytics, notifications, inventory updates) via event consumers.
- Support debugging by replaying the exact sequence of events that led to the current state.

## Order Notifications

### Customer Notifications
- Order confirmation email with order summary and estimated delivery.
- Shipping confirmation with tracking number and carrier link.
- Delivery confirmation.
- Return/refund confirmation.

### Internal Notifications
- Alert operations on high-value orders or flagged orders (fraud risk).
- Notify warehouse teams of new orders ready for fulfillment.
- Escalate orders stuck in a state beyond SLA thresholds.

### Implementation
- Use an event-driven architecture: order events trigger notification dispatchers.
- Support multiple channels: email (transactional provider like SendGrid, Postmark), SMS, push notifications.
- Template notifications with order data; allow customers to set communication preferences.
