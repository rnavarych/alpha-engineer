---
name: domain-fintech:fintech-security
description: Guides fintech security: HSM integration (key generation, signing, encryption), cryptographic key management (BYOK, rotation, key ceremony), PCI DSS for fintech, data encryption (field-level, tokenization), secure multi-party computation, zero-knowledge proofs, and SOC 2 Type II requirements. Use when implementing security controls for financial systems.
allowed-tools: Read, Grep, Glob, Bash
---

# Fintech Security

## When to use
- Implementing HSM-backed signing or envelope encryption
- Managing cryptographic key lifecycle (rotation, BYOK, key ceremony)
- Scoping and implementing PCI DSS controls
- Designing tokenization for card data or PII
- Evaluating SMPC or ZKP for privacy-preserving financial computations
- Preparing for SOC 2 Type II audit evidence collection

## Core principles
1. **Keys never leave the HSM boundary in plaintext** — envelope encryption; DEKs protect data, HSM protects DEKs
2. **Tokenize at the earliest point** — reduce PCI scope before data touches your systems
3. **Defense-in-depth encryption** — TDE at rest + FLE at application layer, not one or the other
4. **Rotate on a schedule, not on breach** — 90-day symmetric rotation with zero-downtime dual-key period
5. **Automate SOC 2 evidence** — continuous control monitoring beats point-in-time manual checks every time

## Reference Files
- `references/hsm-key-management.md` — HSM key generation, signing, envelope encryption, cloud HSM options, key lifecycle, BYOK, rotation policy, and key ceremony procedure
- `references/pci-dss-encryption.md` — PCI DSS scope reduction, key requirements (3/4/6/7/8/10/11), tokenization architecture, field-level encryption, encryption at rest and in transit
- `references/advanced-crypto-compliance.md` — SMPC use cases and implementation approaches, ZKP protocols (zk-SNARKs, zk-STARKs, Bulletproofs), SOC 2 Type II trust service criteria and fintech-specific evidence automation
