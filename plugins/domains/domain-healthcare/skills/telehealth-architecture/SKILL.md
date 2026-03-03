---
name: domain-healthcare:telehealth-architecture
description: Telehealth system architecture covering HIPAA-compliant video consultation, remote patient monitoring, patient portal design, asynchronous telehealth, and billing integration with telehealth-specific CPT codes.
allowed-tools: Read, Grep, Glob, Bash
---

# Telehealth Architecture

## When to use
- Selecting a video platform for synchronous telehealth visits
- Implementing WebRTC with HIPAA-compliant session management
- Building a remote patient monitoring data pipeline and alerting system
- Designing a patient portal with scheduling, messaging, and lab result display
- Implementing store-and-forward workflows for dermatology, radiology, or ophthalmology
- Setting up telehealth CPT billing codes and place-of-service configuration

## Core principles
1. **BAA before first byte of video** — the video vendor must have a signed BAA; the platform being "HIPAA-eligible" is not the same as being covered
2. **Waiting room is non-negotiable** — sessions without a waiting room allow any link-holder to join before the provider; that is a PHI exposure
3. **RPM thresholds are per-patient, not per-population** — population averages make terrible individual alert thresholds; configure them per patient condition and history
4. **Health literacy beats clinical accuracy in patient-facing UI** — a correct lab result displayed in clinical jargon is worse than a slightly simplified one the patient actually understands
5. **Telehealth billing changes constantly** — verify payer coverage and Place of Service codes at the start of every project; COVID-era expansions have been rolling back

## Reference Files
- `references/video-consultation-hipaa.md` — platform comparison table (WebRTC, Twilio, Vonage, Zoom SDK, Doxy.me), WebRTC implementation with SRTP and TURN, video quality requirements, HIPAA compliance checklist, patient identity verification
- `references/rpm-patient-portal.md` — supported RPM devices, data collection pipeline steps, clinical alerting with escalation tiers, patient portal core features, WCAG 2.1 AA and health literacy UX requirements
- `references/async-telehealth-billing.md` — store-and-forward specialties and implementation, provider review queue design, telehealth CPT code table, billing considerations and state regulation awareness
