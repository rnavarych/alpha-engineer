# Epic, Cerner, and Allscripts Integration

## When to load
Integrating with a major EHR vendor, setting up SMART on FHIR app registration, accessing sandbox environments for development, or implementing CDS Hooks for point-of-care decision support.

## Epic Integration

### FHIR R4 APIs
- Epic supports FHIR R4 as the primary modern integration standard
- Register your application in the Epic App Orchard (now Epic App Market) for distribution
- Use Epic's FHIR sandbox (open.epic.com) for development and testing
- Supported resources: Patient, Encounter, Observation, Condition, MedicationRequest, AllergyIntolerance, Procedure, DiagnosticReport, DocumentReference
- Epic implements SMART on FHIR for authorization (EHR launch and standalone launch)

### MyChart Integration
- Patient-facing portal and mobile app integration via MyChart APIs
- Support for patient self-scheduling, messaging, bill pay, and health record access
- MyChart Bedside for inpatient engagement
- Third-party app integration through MyChart via SMART on FHIR launch

### Interconnect
- Epic's middleware layer for web services and API management
- Handles authentication, rate limiting, and routing to Epic backend services
- Supports both FHIR and proprietary Epic web services
- Configure Interconnect endpoints for each integration use case

## Cerner / Oracle Health Integration

### Millennium Platform
- Cerner Millennium is the core EHR platform
- Cerner Code Console (code.cerner.com) for API documentation and sandbox access
- Supports FHIR R4 APIs with comprehensive resource coverage
- Use Cerner's sandbox with synthetic patient data for development

### FHIR APIs
- FHIR R4 endpoints for clinical data: Patient, Encounter, Observation, Condition, MedicationRequest
- Authorization via SMART on FHIR with OAuth 2.0
- Supports Bulk Data Access ($export) for population health data extraction
- CDS Hooks integration for clinical decision support at the point of care

### CDS Hooks
- Cerner natively supports CDS Hooks: `patient-view`, `order-select`, `order-sign`
- Register external CDS services to provide real-time clinical recommendations
- Use prefetch templates to request necessary FHIR data with the hook invocation
- Return actionable cards with suggestions that clinicians can accept directly

## Allscripts Integration
- Allscripts Open API platform for third-party integration
- Supports FHIR R4 for clinical data exchange
- Unity API for Allscripts Professional and TouchWorks EHR systems
- FollowMyHealth patient portal APIs for patient engagement
