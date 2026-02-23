---
name: order-processing
description: |
  Order processing for e-commerce: order state machine (pending through delivered/cancelled/returned),
  fulfillment workflows, returns/exchanges (RMA), invoice/receipt generation, order event sourcing,
  split shipments, and order notifications.
allowed-tools: Read, Grep, Glob, Bash
---

# Order Processing

## When to use
- Designing or implementing an order state machine with explicit transitions and audit logging
- Building fulfillment workflows (pick/pack/ship, WMS push, partial fulfillment handling)
- Implementing split shipments for multi-location or mixed-availability orders
- Building a returns and exchanges (RMA) flow with inspection and refund/exchange logic
- Setting up order event sourcing for audit trail and async downstream processing
- Generating invoices and receipts with legally required fields
- Wiring up order notification pipelines (confirmation, shipping, delivery, refund)

## Core principles
1. **State transitions must be explicit and validated** — reject invalid transitions with errors; no silent state drift
2. **Every transition is an event** — store the full history in `order_events`, not just the current state
3. **Atomic state + event writes** — update order state AND record the event in a single transaction
4. **Fulfillment failures need a path** — partial fulfillment and split shipments must be first-class states, not edge cases
5. **Notification dispatch must be idempotent** — order events can be processed more than once; guard against duplicate sends

## Reference Files
- `references/state-machine-fulfillment.md` — order state definitions, allowed transitions, implementation patterns, pick/pack/ship workflow, WMS integration, split shipments, invoice generation
- `references/returns-events-notifications.md` — RMA flow, return policies, exchange handling, order event sourcing design, customer and internal notification channels
