---
name: role-architect:threat-modeling
description: |
  Threat modeling expertise including STRIDE methodology, attack trees,
  trust boundary identification, data flow analysis, risk assessment,
  mitigation prioritization, and security architecture review.
allowed-tools: Read, Grep, Glob, Bash
---

# Threat Modeling

## When to use
- Performing a security review of a new system design or major feature
- Systematically identifying threats using the STRIDE framework
- Building attack trees for a specific attacker goal
- Identifying and documenting trust boundaries in a system architecture
- Rating threats by likelihood and impact to prioritize mitigation work
- Conducting pre-launch or post-incident security architecture reviews

## Core principles
1. **STRIDE is a checklist, not a destination** — apply it to every component and every data flow crossing
2. **Trust boundaries are the attack surface map** — draw them before writing a single mitigation
3. **Risk = Likelihood x Impact** — prioritize by score, not by what feels scary
4. **Quick wins first within each risk tier** — cheapest effective fix before the strategic overhaul
5. **Residual risk must be documented** — accepting a risk without recording it is the same as ignoring it

## Reference Files
- `references/stride-and-attack-analysis.md` — full STRIDE breakdown (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege) with check items and mitigations per category; attack tree construction methodology; trust boundary identification with common boundary types; and sensitive data flow analysis with aggregation risk
- `references/risk-assessment-and-review.md` — Likelihood x Impact matrix with 1-9 risk scoring, risk tolerance definition, mitigation prioritization (quick wins vs strategic), residual risk documentation, and security architecture review checklist covering authentication, authorization, data protection, network security, logging, dependencies, and incident response
