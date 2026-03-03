---
name: domain-ecommerce:pci-compliance
description: |
  PCI DSS compliance for e-commerce: compliance levels (SAQ A, SAQ A-EP, SAQ D), cardholder
  data handling, tokenization (Stripe, Braintree tokens), secure payment forms (iframes,
  hosted fields), network segmentation, vulnerability scanning, penetration testing, and
  compliance audit preparation.
allowed-tools: Read, Grep, Glob, Bash
---

# PCI DSS Compliance

## When to use
- Choosing the right PCI compliance level (SAQ A vs. SAQ A-EP vs. SAQ D) for a checkout integration
- Auditing what card data is stored, logged, or transmitted — and what must be eliminated
- Implementing tokenization correctly (Stripe, Braintree, Adyen) to keep servers out of PCI scope
- Setting up or reviewing secure payment form implementation (iframes, hosted fields, hosted pages)
- Designing network segmentation for payment processing systems (VPC, VLAN, firewall rules)
- Preparing for quarterly vulnerability scans (ASV) or annual penetration testing
- Assembling documentation and evidence for a PCI compliance audit

## Core principles
1. **SAQ A is the target** — every architectural decision should aim to keep card data off your servers entirely
2. **Never store CVV after auth** — not encrypted, not hashed, not "temporarily" — this is a hard PCI DSS requirement
3. **Tokenize client-side, always** — the token travels to your server; the raw PAN must never touch it
4. **Network segmentation reduces scope** — systems outside the CDE subnet face far fewer requirements
5. **Documentation is the audit** — assessors believe what is written and evidenced, not what you remember

## Reference Files
- `references/cardholder-data-tokenization.md` — SAQ levels and selection criteria, what can/cannot be stored, tokenization per gateway (Stripe/Braintree/Adyen), iframe and hosted page secure form patterns
- `references/network-security-audit.md` — network segmentation requirements, internal and ASV vulnerability scanning, annual penetration testing, audit documentation and evidence collection
