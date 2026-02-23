---
name: compliance-pci
description: |
  PCI DSS compliance: SAQ A vs SAQ D scope, Stripe Elements for card data isolation,
  tokenization patterns, cardholder data environment (CDE) scoping, network segmentation,
  encryption in transit/at rest, audit logging requirements. Never store raw card data.
  Use when implementing payment systems, reviewing card data handling, PCI scope reduction.
allowed-tools: Read, Grep, Glob
---

# PCI DSS Compliance

## When to use
- Implementing payment card processing
- Reducing PCI scope with hosted fields / Elements
- Reviewing what data can/cannot be stored
- Designing network segmentation for CDE
- Choosing SAQ level for annual assessment

## Core principles
1. **Never store raw card data** — full PAN, CVV, magnetic stripe data must never touch your servers
2. **Reduce scope, don't solve scope** — use Stripe Elements / Braintree Hosted Fields to push scope to the processor
3. **Tokenize, never transmit** — use processor tokens (`pm_xxx`, `tok_xxx`); your app never sees raw card numbers
4. **CVV must never be stored** — not even transiently in logs; PCI Req 3.3 is absolute
5. **SAQ A is achievable for most SaaS** — if you use hosted card collection, you avoid SAQ D's 300+ controls

## References available
- `references/saq-selection.md` — SAQ A vs SAQ A-EP vs SAQ D decision tree, control counts, scope criteria
- `references/cardholder-data.md` — what to store vs what to forbid, tokenization schema, webhook security patterns
- `references/network-segmentation.md` — CDE boundary design, firewall rules, segmentation testing
