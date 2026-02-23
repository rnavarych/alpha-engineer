---
name: compliance-gdpr
description: |
  GDPR compliance implementation: Subject Access Requests (30-day), right to erasure,
  consent management, data retention policies, 72-hour breach notification, lawful basis,
  PII detection, data minimization. PostgreSQL RLS for data isolation.
  Use when implementing GDPR features, data subject rights, consent flows, breach response.
allowed-tools: Read, Grep, Glob
---

# GDPR Compliance Implementation

## When to use
- Implementing Subject Access Requests (SAR) and right to erasure
- Designing consent management systems
- Setting up data retention and automatic deletion
- Planning 72-hour breach notification workflow
- Choosing lawful basis for data processing

## Core principles
1. **Privacy by design** — build privacy in from the start; retrofitting is 10x harder
2. **Data minimization** — collect only what you need for the stated purpose
3. **72 hours for breach notification** — to supervisory authority; 30 days for SAR response
4. **Consent must be specific and withdrawable** — "I agree to terms" does not cover marketing emails
5. **Document the lawful basis** — legitimate interest requires a balancing test; consent is not always the right choice

## References available
- `references/data-mapping.md` — retention schedules, lawful basis matrix, data flow mapping, PII inventory
- `references/consent-management.md` — consent record schema, grant/withdraw patterns, audit trail requirements
- `references/dsar-procedures.md` — SAR workflow (30-day), right to erasure with financial compliance exceptions, breach notification steps

## Assets available
- `assets/dpia-template.md` — Data Protection Impact Assessment template for high-risk processing
