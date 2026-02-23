# SMART on FHIR, CDS Hooks, Bulk Data, and US Core

## When to load
Implementing SMART on FHIR authorization, configuring OAuth scopes for EHR launch, building a CDS Hooks service, performing bulk data exports for population health, or validating resources against US Core profiles.

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
