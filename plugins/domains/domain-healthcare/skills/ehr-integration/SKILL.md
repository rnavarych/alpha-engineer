---
name: ehr-integration
description: EHR system integration covering Epic, Cerner/Oracle Health, and Allscripts platforms, HL7v2 messaging, interface engines, CCD/C-CDA document exchange, and integration testing with vendor sandboxes.
allowed-tools: Read, Grep, Glob, Bash
---

# EHR Integration

## When to use
- Integrating with Epic, Cerner, or Allscripts via FHIR R4 or proprietary APIs
- Processing HL7v2 ADT, ORM, ORU, or other message types from an EHR feed
- Selecting or configuring an interface engine (Mirth, Rhapsody)
- Implementing CCD or C-CDA document generation, parsing, or reconciliation
- Setting up or debugging SMART on FHIR application registration
- Testing integrations against vendor sandboxes

## Core principles
1. **FHIR R4 first, HL7v2 as legacy** — all new integrations use FHIR; HL7v2 is maintenance mode for existing feeds
2. **Interface engine as single point of control** — route all EHR traffic through one engine; direct point-to-point integrations become unmanageable fast
3. **ACK or it didn't happen** — every HL7v2 message needs acknowledgment; assume delivery failure without it
4. **Dead letter queue from day one** — messages that fail processing will happen; design the failure path before the happy path
5. **Test against real sandboxes, not mocks** — vendor-specific quirks (Epic's ADT extensions, Cerner's FHIR pagination) only show up against actual endpoints

## Reference Files
- `references/epic-cerner-allscripts.md` — Epic FHIR R4, App Orchard, MyChart, Interconnect; Cerner Millennium, Code Console, CDS Hooks; Allscripts Open API and Unity API
- `references/hl7v2-messaging.md` — ADT/ORM/ORU/MDM/SIU/DFT/RDE message types, segment structure, ACK pattern, field mapping best practices, dead letter queue design
- `references/interface-engines-document-exchange.md` — Mirth Connect channel architecture, Rhapsody routing, interface engine best practices, CCD/C-CDA exchange, Direct messaging, integration testing tools
