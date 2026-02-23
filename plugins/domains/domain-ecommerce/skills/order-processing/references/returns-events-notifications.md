# Returns, Event Sourcing, and Notifications

## When to load
Load when implementing RMA/returns workflows, order event sourcing, or order notification systems.

## Returns and Exchanges (RMA)

### Return Flow
1. Customer initiates return request via self-service portal or customer service.
2. System generates RMA number and return shipping label.
3. Customer ships items back.
4. Warehouse receives and inspects returned items.
5. System processes refund or exchange based on inspection outcome.

### Return Policies
- Define return window (e.g., 30 days from delivery).
- Specify eligible conditions: unopened, defective, wrong item, buyer's remorse.
- Calculate restocking fees if applicable.
- Track return reasons for product quality and catalog improvement insights.

### Exchanges
- Create a new order linked to the original for exchange items.
- Handle price differences (charge or refund the delta).
- Reserve exchange inventory upon RMA approval to prevent selling reserved stock.

## Order Event Sourcing

### Event Log
- Record every order-related event: `OrderPlaced`, `PaymentCaptured`, `ItemPicked`, `Shipped`, `Delivered`, `Refunded`.
- Each event: `order_id`, `event_type`, `payload` (JSON), `actor`, `timestamp`.
- Rebuild order state at any point in time by replaying events.

### Benefits
- Complete audit trail for compliance and customer service investigations.
- Asynchronous downstream processing via event consumers (analytics, notifications, inventory updates).
- Debugging: replay the exact sequence of events that produced the current state.

## Order Notifications

### Customer Notifications
- Order confirmation email with order summary and estimated delivery.
- Shipping confirmation with tracking number and carrier link.
- Delivery confirmation notification.
- Return/refund confirmation with refund amount and timing.

### Internal Notifications
- Alert operations on high-value or fraud-flagged orders.
- Notify warehouse teams of new orders ready for fulfillment.
- Escalate orders stuck in a state beyond SLA thresholds (e.g., processing > 24h).

### Implementation
- Event-driven architecture: order events trigger notification dispatchers.
- Multiple channels: email (SendGrid, Postmark), SMS, push notifications.
- Template notifications with order data; respect customer communication preferences.
- Idempotent notification dispatch — deduplicate by order event ID to prevent duplicate sends.
