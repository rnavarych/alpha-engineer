---
name: hipaa-compliance
description: HIPAA compliance implementation covering technical, administrative, and physical safeguards, Business Associate Agreement checklists, risk assessment methodology, and breach notification procedures. Use when building or reviewing healthcare systems that handle PHI.
allowed-tools: Read, Grep, Glob, Bash
---

# HIPAA Compliance Implementation

## When to use
- Designing or auditing encryption for PHI at rest and in transit
- Implementing access controls, audit logging, or session management for clinical systems
- Evaluating a new vendor and determining BAA requirements
- Conducting or documenting a formal HIPAA risk assessment
- Responding to a suspected PHI breach and navigating notification timelines
- Reviewing workforce training or physical security gaps

## Core principles
1. **AES-256-GCM at rest, TLS 1.3 in transit, KMS for keys** — these three together cover the encryption baseline; anything less needs a documented exception
2. **Every PHI access gets a log entry** — who, what resource, when, from where, and outcome; 6-year retention minimum, tamper-evident storage required
3. **BAA before byte one** — no PHI reaches a vendor system without a signed BAA in place; subcontractor flow-down is not optional
4. **Risk assessment is continuous, not annual** — reassess after every significant system change, incident, or regulatory update
5. **Breach notification clock starts at discovery** — 60 days to notify individuals and HHS; do not wait for the investigation to conclude before starting the clock

## Reference Files
- `references/technical-safeguards.md` — encryption (AES-256-GCM, TDE, envelope encryption), access controls (RBAC, break-glass, session timeout), audit controls, transmission security (TLS, mTLS)
- `references/administrative-physical-safeguards.md` — security officer designation, workforce training, access management workflows, incident response, contingency planning, risk analysis, physical facility and device controls
- `references/baa-risk-breach.md` — BAA checklist for vendor onboarding, risk assessment methodology (8-step), breach notification procedures and HHS reporting timelines
