---
name: ehr-integration
description: |
  EHR system integration covering Epic, Cerner/Oracle Health, and Allscripts platforms,
  HL7v2 messaging, interface engines, CCD/C-CDA document exchange, and integration
  testing with vendor sandboxes.
allowed-tools: Read, Grep, Glob, Bash
---

# EHR Integration

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

## HL7v2 Messaging

### Message Types
| Message | Trigger | Purpose |
|---------|---------|---------|
| **ADT** (A01-A60) | Admit, Discharge, Transfer | Patient movement and registration events |
| **ORM** (O01) | Order Message | New orders for labs, imaging, procedures |
| **ORU** (R01) | Observation Result | Lab results, radiology reports, transcriptions |
| **MDM** (T01-T11) | Medical Document Management | Clinical document notifications and content |
| **SIU** (S12-S26) | Scheduling | Appointment scheduling and updates |
| **DFT** (P03) | Detail Financial Transaction | Charge posting and billing events |
| **RDE** (O11) | Pharmacy Encoded Order | Medication orders to pharmacy systems |

### HL7v2 Message Structure
- Messages consist of segments (MSH, PID, PV1, OBR, OBX) separated by carriage returns
- Fields within segments separated by `|`, components by `^`, subcomponents by `&`
- MSH segment contains message type, sending/receiving facility, timestamp, and message control ID
- Implement acknowledgment (ACK) messages for reliable delivery

### HL7v2 Best Practices
- Validate inbound messages against expected message profiles
- Map HL7v2 fields to your internal data model with explicit transformation rules
- Handle character encoding (UTF-8) and escape sequences
- Implement dead letter queues for messages that fail processing
- Log all messages with correlation IDs for troubleshooting

## Interface Engines

### Mirth Connect (NextGen Connect)
- Open-source integration engine widely used in healthcare
- Channel-based architecture: source connector, filters, transformers, destination connector
- Supports HL7v2, FHIR, CDA, CSV, JSON, XML, DICOM
- JavaScript-based message transformation
- Built-in message queuing, retry logic, and error handling

### Rhapsody Integration Engine
- Enterprise-grade integration engine by Rhapsody (formerly InterSystems)
- Visual route designer for message flow configuration
- Strong HL7v2 and FHIR support with built-in validation
- High availability and clustering for production workloads

### Interface Engine Best Practices
- Centralize all EHR integrations through the interface engine
- Implement message logging and audit trails for all transactions
- Use message queues for reliable delivery with configurable retry policies
- Build environment-specific configurations (dev, staging, production)
- Monitor interface health: message throughput, error rates, queue depths

## CCD/C-CDA Document Exchange

- Use Continuity of Care Documents (CCD) for care transitions between providers
- Generate C-CDA documents for patient discharge summaries, referrals, and transfer of care
- Validate C-CDA documents against standard templates before sending
- Parse inbound C-CDA documents and reconcile data (medications, allergies, problems) with existing records
- Support Direct messaging (Direct Protocol) for secure point-to-point document exchange

## Integration Testing

- **Epic sandbox**: open.epic.com with synthetic patients and FHIR R4 endpoints
- **Cerner sandbox**: code.cerner.com with test tenants and sample data
- **Touchstone**: HL7 FHIR testing platform for conformance and interoperability testing
- **Synthea**: Generate synthetic but realistic patient data for testing pipelines
- Test with realistic clinical scenarios: admissions, orders, results, discharges
- Validate message transforms with before/after comparison for every supported message type
