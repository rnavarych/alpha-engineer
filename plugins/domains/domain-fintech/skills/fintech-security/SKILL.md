---
name: fintech-security
description: "Guides fintech security: HSM integration (key generation, signing, encryption), cryptographic key management (BYOK, rotation, key ceremony), PCI DSS for fintech, data encryption (field-level, tokenization), secure multi-party computation, zero-knowledge proofs, and SOC 2 Type II requirements. Use when implementing security controls for financial systems, managing cryptographic key lifecycles, or preparing for compliance audits."
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

## Workflow

### Step 1: Design envelope encryption architecture
```
┌─────────────┐     ┌──────────┐     ┌──────────┐
│ Plaintext   │────▶│ DEK      │────▶│ Encrypted│
│ (card data) │     │ (AES-256)│     │ Data     │
└─────────────┘     └────┬─────┘     └──────────┘
                         │
                    ┌────▼─────┐
                    │ HSM/KMS  │
                    │ wraps DEK│
                    └──────────┘
```
- Generate a unique Data Encryption Key (DEK) per record or batch
- Encrypt data with the DEK (AES-256-GCM)
- Wrap (encrypt) the DEK with the Key Encryption Key (KEK) in HSM
- Store encrypted data + wrapped DEK together; KEK never leaves HSM

### Step 2: Implement tokenization for PCI scope reduction
```
# Tokenization flow (reduces PCI DSS scope)
1. Card data enters at payment boundary
2. Tokenization service replaces PAN with non-reversible token
3. Token stored in application database (out of PCI scope)
4. Original PAN stored only in PCI-compliant token vault
5. Detokenize only when needed (e.g., processor submission)
```

### Step 3: Configure key rotation
- Set 90-day rotation schedule for symmetric keys (DEKs)
- During rotation: dual-key period — old key decrypts, new key encrypts
- Re-encrypt data lazily (on next read) or in background batch
- Log all rotation events for SOC 2 evidence

### Step 4: Validate compliance posture
- Map implemented controls to PCI DSS requirements (3, 4, 6, 7, 8, 10, 11)
- Run automated evidence collection for SOC 2 trust service criteria
- Verify HSM audit logs capture all key operations
- Confirm no plaintext secrets in application logs or environment dumps

## Reference Files
- `references/hsm-key-management.md` — HSM key generation, signing, envelope encryption, cloud HSM options, key lifecycle, BYOK, rotation policy, and key ceremony procedure
- `references/pci-dss-encryption.md` — PCI DSS scope reduction, key requirements (3/4/6/7/8/10/11), tokenization architecture, field-level encryption, encryption at rest and in transit
- `references/advanced-crypto-compliance.md` — SMPC use cases and implementation approaches, ZKP protocols (zk-SNARKs, zk-STARKs, Bulletproofs), SOC 2 Type II trust service criteria and fintech-specific evidence automation
