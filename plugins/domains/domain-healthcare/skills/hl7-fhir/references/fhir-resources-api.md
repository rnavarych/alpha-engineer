# FHIR Resources and RESTful API Operations

## When to load
Working with FHIR resources directly, implementing CRUD or search operations against a FHIR server, handling Bundle pagination, or using FHIR operations like $everything, $validate, or $export.

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

## CRUD Operations

- `GET /Patient/123` - Read a specific patient
- `POST /Patient` - Create a new patient
- `PUT /Patient/123` - Update a patient (full replacement)
- `PATCH /Patient/123` - Partial update (JSON Patch or FHIRPath Patch)
- `DELETE /Patient/123` - Remove a patient record

## Search

- `GET /Patient?family=Smith&birthdate=1990-01-01` - Search by parameters
- `GET /Observation?patient=123&code=http://loinc.org|85354-9` - Search with system and code
- `_include` and `_revinclude` for loading related resources in a single request
- `_count` and `_offset` for pagination; use Bundle links for cursor-based paging
- Search result Bundles use `type: searchset`

## Operations

- `$everything` on Patient: Retrieve all data for a patient
- `$validate` on any resource: Check resource conformance to profiles
- `$export` on system or group: Bulk data export (NDJSON format)
