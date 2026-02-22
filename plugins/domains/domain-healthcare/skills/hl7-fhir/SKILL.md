---
name: hl7-fhir
description: |
  HL7 FHIR interoperability covering FHIR resources, RESTful API patterns, server
  implementation, SMART on FHIR authorization, CDS Hooks, Bulk Data Access, and
  US Core Implementation Guide profiles.
allowed-tools: Read, Grep, Glob, Bash
---

# HL7 FHIR Interoperability

## Core FHIR Resources

| Resource | Purpose | Common Use |
|----------|---------|------------|
| **Patient** | Demographics, identifiers, contacts | Patient registration, matching |
| **Observation** | Lab results, vitals, social history | Clinical measurements and findings |
| **Encounter** | Visit or admission context | Inpatient/outpatient tracking |
| **Condition** | Diagnoses, problems, health concerns | Problem lists, active diagnoses |
| **MedicationRequest** | Prescribed medications | e-Prescribing, medication orders |
| **DiagnosticReport** | Lab panels, imaging, pathology reports | Results delivery |
| **AllergyIntolerance** | Allergies and adverse reactions | Clinical safety checks |
| **Procedure** | Surgeries, therapies, interventions | Procedure documentation |
| **Immunization** | Vaccination records | Immunization registries |
| **CarePlan** | Treatment plans and goals | Care coordination |

## RESTful API Operations

### CRUD Operations
- `GET /Patient/123` - Read a specific patient
- `POST /Patient` - Create a new patient
- `PUT /Patient/123` - Update a patient (full replacement)
- `PATCH /Patient/123` - Partial update (JSON Patch or FHIRPath Patch)
- `DELETE /Patient/123` - Remove a patient record

### Search
- `GET /Patient?family=Smith&birthdate=1990-01-01` - Search by parameters
- `GET /Observation?patient=123&code=http://loinc.org|85354-9` - Search with system and code
- `_include` and `_revinclude` for loading related resources in a single request
- `_count` and `_offset` for pagination; use Bundle links for cursor-based paging
- Search result Bundles use `type: searchset`

### Operations
- `$everything` on Patient: Retrieve all data for a patient
- `$validate` on any resource: Check resource conformance to profiles
- `$export` on system or group: Bulk data export (NDJSON format)

## FHIR Server Implementation

### HAPI FHIR (Java)
- Open-source, widely adopted, supports FHIR R4 and R5
- JPA backend for persistence with PostgreSQL or MySQL
- Built-in search parameter indexing and subscription support
- Extensible interceptor framework for custom logic (validation, authorization, auditing)

### Microsoft FHIR Server
- Azure Health Data Services (managed) or open-source .NET implementation
- Native Azure AD integration for SMART on FHIR authorization
- Built-in FHIR-to-DICOM and FHIR-to-HL7v2 conversion tools

### Implementation Considerations
- Enable resource versioning (vRead) for audit trails
- Implement conditional create/update to prevent duplicates
- Use Subscriptions (R5 topic-based or R4 Criteria-based) for event-driven workflows
- Set up capability statement (`/metadata`) accurately reflecting supported features

## SMART on FHIR

### Authorization Flow
1. App registers with the FHIR server's authorization server
2. EHR launches app with launch context (patient ID, encounter ID)
3. App requests authorization with scopes (e.g., `patient/Observation.read`)
4. User authenticates and consents
5. App receives access token and uses it for FHIR API calls

### Scopes
- `patient/Resource.read` - Read access in patient context
- `user/Resource.write` - Write access in user context
- `system/Resource.read` - Backend service access (no user)
- `launch/patient` - Receive patient context at launch
- `openid fhirUser` - Obtain user identity claims

### Launch Context
- **EHR Launch**: App launched from within the EHR, receives context automatically
- **Standalone Launch**: App launches independently, must discover and authenticate
- Pass `iss` (FHIR server URL) and `launch` token in EHR launch

## CDS Hooks

- **Hook points**: `patient-view`, `order-select`, `order-sign`, `encounter-start`, `encounter-discharge`
- CDS service receives clinical context and returns **cards** with suggestions, warnings, or links
- Cards have indicators: `info`, `warning`, `critical`
- Support `suggestions` for one-click actions (e.g., add an order, update a prescription)
- Use prefetch to request needed FHIR data upfront, reducing round trips

## Bulk Data Access

- `GET /$export` - System-level export of all resources
- `GET /Group/123/$export` - Export data for a specific patient group
- Output format: NDJSON (Newline Delimited JSON), one resource per line
- Poll the `Content-Location` URL for export status until complete
- Download result files from the URLs provided in the completion response
- Use for population health analytics, quality reporting, and research data extraction

## US Core Implementation Guide

- Defines minimum data requirements for FHIR R4 in US healthcare
- Mandates support for specific profiles: US Core Patient, US Core Condition, US Core Observation (vitals, labs, social history)
- Requires specific search parameters and includes for each profile
- Aligns with USCDI (United States Core Data for Interoperability) data elements
- Validate resources against US Core profiles to ensure conformance
