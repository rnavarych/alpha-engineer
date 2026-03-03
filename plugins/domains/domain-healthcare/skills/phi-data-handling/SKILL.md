---
name: domain-healthcare:phi-data-handling
description: Protected Health Information (PHI) data handling covering the 18 HIPAA identifiers, de-identification methods (Safe Harbor, Expert Determination), minimum necessary principle, access controls, audit logging, encryption, and secure disposal.
allowed-tools: Read, Grep, Glob, Bash
---

# PHI Data Handling

## When to use
- Determining whether a dataset or field constitutes PHI
- Implementing Safe Harbor or Expert Determination de-identification
- Designing role-based access controls for a clinical system
- Configuring audit logging for PHI access events
- Implementing encryption for PHI at rest or in transit
- Planning media sanitization or cryptographic erasure of PHI

## Core principles
1. **When in doubt it's PHI** — if a data element could identify an individual in combination with health information, treat it as PHI; the cost of over-protecting is low, the cost of a breach is not
2. **Minimum necessary is enforced at the API layer** — strip fields the caller's role doesn't need before the response leaves your service; don't rely on the client to ignore what it receives
3. **Every PHI access gets a log entry** — read access included, not just writes; audit trails without reads are half the story
4. **Cryptographic erasure beats secure delete** — destroying the encryption key is faster, more reliable, and more auditable than overwriting data in place
5. **Break-glass access is not a loophole** — it must be logged, time-limited, and reviewed post-access; emergency access that goes unreviewed is a compliance finding waiting to happen

## Reference Files
- `references/identifiers-deidentification.md` — the 18 HIPAA identifiers, Safe Harbor removal checklist, Expert Determination method and documentation requirements
- `references/access-controls-audit-logging.md` — minimum necessary principle, RBAC table by clinical role, break-glass implementation, required audit log fields, tamper-evident logging, high-risk access review cadence
- `references/encryption-disposal.md` — AES-256-GCM column encryption, TDE, key rotation with cloud KMS, mTLS for microservices, NIST SP 800-88 disposal methods, cryptographic erasure pattern
