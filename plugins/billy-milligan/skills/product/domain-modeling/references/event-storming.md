# Event Storming

## When to load
Load when planning or facilitating an event storming workshop, introducing the format to stakeholders, or using the sticky note vocabulary to run a Big Picture or Design-Level session.

---

## Event Storming Overview

Event storming is a workshop format for exploring complex business domains through domain events. It gets domain experts and engineers in the same room, writing on sticky notes, discovering how the business actually works — not how anyone thinks it works.

### Why it works
- Non-technical stakeholders can participate (events are business facts, not code)
- Surfaces disagreements and misunderstandings before they become bugs
- Identifies aggregate boundaries naturally (from command/event clusters)
- Produces a shared ubiquitous language the whole team can use

### Two formats

**Big Picture Event Storming** (discovery):
- 4–8 hours, entire domain
- All stakeholders present: business, product, engineering, operations
- Output: shared understanding, context boundaries, problem areas

**Design-Level Event Storming** (design):
- 2–4 hours, one bounded context
- Smaller group: product + engineering team for that context
- Output: aggregate boundaries, commands, events, policies, read models

---

## Sticky Note Vocabulary

| Color | Element | Definition | Example |
|-------|---------|-----------|---------|
| Orange | **Domain Event** | Something that happened; past tense; business-meaningful | `OrderPlaced`, `PaymentFailed`, `InventoryReserved` |
| Blue | **Command** | An intent or instruction that triggers an event | `PlaceOrder`, `CancelOrder`, `RefundPayment` |
| Yellow | **Aggregate** | A cluster of objects that handles commands and emits events | `Order`, `Payment`, `Customer` |
| Purple | **Policy / Reaction** | "Whenever event X, then trigger command Y" | "Whenever OrderPlaced, then ReserveInventory" |
| Pink | **External System** | Third-party or external system that receives commands or produces events | Stripe, SendGrid, Warehouse Management System |
| Green | **Read Model / View** | Data needed to display a UI or make a decision | Order history list, current cart contents |
| Red | **Hotspot** | Disputed, unclear, or problematic area — revisit later | Mark with ⚠️, don't block; keep moving |

---

## Workshop Facilitation Guide

### Phase 1: Chaotic exploration (45–60 minutes)
**Format:** Unstructured. Everyone writes domain events on orange stickies simultaneously.
**Facilitation rule:** No discussion, no judgment — just write events as fast as you can.
**Prompt:** "What happens in this business? Write every significant business fact you can think of."

Common outputs at this stage:
```
OrderPlaced          PaymentFailed        CustomerRegistered
OrderCancelled       PaymentSucceeded     PasswordResetRequested
ItemShipped          RefundProcessed      EmailVerified
ItemReturned         ChargebackReceived   AccountSuspended
ReviewSubmitted      InventoryLow         PromotionApplied
```

**Tip:** Enforce past tense. If someone writes "Place Order" (command), reframe it: "What happened? An OrderWasPlaced."

### Phase 2: Timeline ordering (30–45 minutes)
**Format:** Arrange stickies in chronological order on a long wall or Miro board.
**What to watch for:**
- Disagreements about order → reveals process uncertainty (add a hotspot)
- Missing events that everyone assumes → important discoveries
- Duplicate events with different names → language conflict (pick one, eliminate the other)
- Events that happen in parallel → separate swimlanes

```
Timeline (left = earlier, right = later):

CustomerRegistered → EmailVerified → FirstProductAdded → OrderPlaced →
PaymentSucceeded → InventoryReserved → PickTaskCreated →
ItemPicked → ItemPacked → ShipmentCreated → OrderShipped →
TrackingEmailSent → ItemDelivered

Parallel:
PaymentFailed → DunningEmailSent → PaymentRetried (3 attempts) → OrderCancelled
```

### Phase 3: Add commands (30 minutes)
For each domain event, add the blue command (intent) that caused it.

```
[RegisterCustomer] → CustomerRegistered
[PlaceOrder] → OrderPlaced
[ProcessPayment] → PaymentSucceeded OR PaymentFailed
[CancelOrder] → OrderCancelled
[ReserveInventory] → InventoryReserved OR StockInsufficient
```

### Phase 4: Add actors and external systems (20 minutes)
Who or what issues each command?
- **User**: adds their name or role above the command sticky
- **External system**: pink sticky (Stripe for PaymentSucceeded, etc.)
- **Automated policy**: purple sticky ("When OrderPlaced, then ProcessPayment")

### Phase 5: Identify aggregates (30–45 minutes)
Group command/event clusters into aggregates. An aggregate:
- Handles a set of commands
- Enforces business rules when handling those commands
- Emits events as the result

### Phase 6: Add policies (20 minutes)
Policies are the "business glue" — automated reactions to events.

```
Policy: "Whenever PaymentSucceeded, then ReserveInventory"
Policy: "Whenever InventoryReserved, then CreatePickTask"
Policy: "Whenever AllItemsShipped, then MarkOrderShipped"
Policy: "Whenever PaymentFailed (3rd attempt), then CancelOrder AND NotifyCustomer"
```

### Phase 7: Identify read models (20 minutes)
For each point in the flow where a user makes a decision, what data do they need to see?

```
Decision: Customer decides whether to place order
  Read Model: Cart contents (items, quantities, prices, subtotal, estimated shipping)

Decision: Warehouse picker finds the item
  Read Model: Pick list (SKU, location, quantity, order priority)
```

---

## Anti-Patterns

### Writing solutions, not events
"Database updated", "API called", "Service invoked" — these are implementation details, not domain events. Domain events are business facts: what happened from the business's perspective?

### Skipping domain experts
Engineers running event storming alone discover the technical view of the domain, not the actual business domain. The value comes from discovering what the business people know that engineers assumed or got wrong.

### Ignoring hotspots
Red stickies get added and then nobody revisits them. Hotspots are where requirements are ambiguous, where the team disagrees, where bugs will appear. They are the most important output of the workshop.

---

## Quick Reference

```
Event storming phases: explore → timeline → commands → actors → aggregates → policies → read models
Orange (event): past tense business fact — "OrderPlaced", not "PlaceOrder"
Blue (command): intent that triggers an event — "PlaceOrder"
Purple (policy): "Whenever [event], then [command]" — automated reaction
Red (hotspot): disputed or unclear — mark and revisit, don't block
Duration: Big Picture = 4–8h; Design Level = 2–4h
Critical rule: domain experts must be present — engineers alone miss the domain
```
