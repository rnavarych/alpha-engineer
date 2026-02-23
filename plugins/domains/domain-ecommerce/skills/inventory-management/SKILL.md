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

## When to use
- Designing stock quantity models (available/reserved/committed) and append-only ledger patterns
- Integrating with WMS platforms (ShipHero, NetSuite WMS) or 3PL providers (ShipBob, Flexport)
- Evaluating dropshipping vs. 3PL vs. in-house fulfillment for a new product line
- Building or improving demand forecasting and automated replenishment
- Implementing lot/batch/serial number tracking and expiration management
- Choosing and implementing inventory valuation method (FIFO, LIFO, WAC)
- Setting up multi-location routing, inter-location transfers, or multi-channel inventory sync

## Core principles
1. **Append-only ledger is the source of truth** — never mutate stock counts directly; replay entries for audit
2. **Atomic DB operations prevent overselling** — `UPDATE WHERE available > 0`; return row count; skip the SELECT
3. **Soft reserve expires, hard reserve holds** — cart TTL (15 min) soft; payment confirmed converts to hard
4. **Safety stock is not a guess** — Z-score × stddev of demand during lead time; recalculate per SKU seasonally
5. **One source of truth, push to channels** — centralized inventory with per-channel buffer stock; never let channels self-manage

## Reference Files
- `references/stock-tracking-wms.md` — quantity types, ledger pattern, atomic updates, WMS platforms and integration, location modeling, picking strategies
- `references/dropshipping-3pl-forecasting.md` — dropshipping model and platforms, 3PL providers and integration, in-house vs. 3PL comparison, demand forecasting methods and tools
- `references/lot-tracking-valuation-cycle-counting.md` — lot/batch/serial tracking, expiration and recall management, FIFO/LIFO/WAC/specific ID valuation, cycle counting process and metrics
- `references/multi-location-reservations-sync.md` — multi-location routing (DOM), inter-location transfers, backorder/preorder, soft/hard reservation implementation, stock alerts, reorder automation, multi-channel sync
