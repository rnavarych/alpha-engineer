---
name: domain-fintech:regulatory-compliance
description: Guides regulatory compliance implementation: SOX controls (segregation of duties, access controls, change management), PSD2 (SCA, open banking APIs, TPP authorization), KYC/AML (CDD, EDD, PEP screening, sanction lists), GDPR for financial data, MiFID II, Basel III, and regulatory reporting pipelines. Use when implementing compliance features or auditing financial systems.
allowed-tools: Read, Grep, Glob, Bash
---

# Regulatory Compliance

## When to use
- Implementing SOX segregation of duties and access control evidence collection
- Building PSD2 SCA flows or qualifying for TRA exemptions
- Implementing KYC/AML (CDD, EDD, PEP screening, sanctions checking)
- Navigating GDPR deletion requests against AML 5-7 year retention obligations
- Meeting MiFID II best execution or transaction reporting requirements
- Designing automated regulatory reporting pipelines with audit trails

## Core principles
1. **SoD in code, not just policy** — check approver != initiator at the application layer; policy documents don't stop fraud
2. **Legal obligation beats right to erasure** — AML retention overrides GDPR deletion; annotate retained records with legal basis
3. **Real-time sanctions screening** — onboarding-only screening misses exposure; screen every transaction against updated lists
4. **Automate evidence before the audit** — continuous control monitoring; manual evidence gathering at audit time is too late
5. **Version-control transformation rules** — regulators audit the logic, not just the output; treat report transforms as code

## Reference Files
- `references/sox-psd2-controls.md` — SOX segregation of duties, access controls, change management, evidence collection automation; PSD2 SCA factors, dynamic linking, exemptions (TRA, low-value, recurring), open banking API standards
- `references/kyc-aml-gdpr.md` — CDD/EDD tiers, PEP screening with fuzzy matching, sanctions list sources and update SLAs, transaction monitoring rules, GDPR retention vs AML deletion tension, data minimization
- `references/mifid-basel-reporting.md` — MiFID II best execution and record keeping, Basel III capital/liquidity ratios, regulatory reporting pipeline architecture with validation gating and resubmission workflow
