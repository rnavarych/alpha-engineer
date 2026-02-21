---
name: clinical-data-modeling
description: |
  Clinical data modeling covering healthcare terminology systems (ICD-10, SNOMED CT,
  LOINC, RxNorm, CPT, NDC), clinical document architecture, patient data normalization,
  temporal clinical data patterns, and clinical decision support data models.
allowed-tools: Read, Grep, Glob, Bash
---

# Clinical Data Modeling

## Healthcare Terminology Systems

### ICD-10 (International Classification of Diseases, 10th Revision)
- **Purpose**: Diagnosis codes for clinical documentation and billing
- **ICD-10-CM**: Clinical Modification for diagnosis coding in the US
- **ICD-10-PCS**: Procedure Coding System for inpatient procedures
- **Structure**: Alphanumeric codes (e.g., E11.65 = Type 2 diabetes with hyperglycemia)
- **Usage**: Required on claims, problem lists, discharge summaries
- **Updates**: Annual updates effective October 1 each year

### SNOMED CT (Systematized Nomenclature of Medicine - Clinical Terms)
- **Purpose**: Comprehensive clinical terminology for EHR data capture
- **Coverage**: 350,000+ concepts spanning findings, procedures, body structures, organisms, substances
- **Structure**: Concept IDs with hierarchical is-a relationships and defining attributes
- **Usage**: Clinical documentation, clinical decision support rules, interoperability mapping
- **Mapping**: SNOMED-to-ICD-10 maps available for billing translation
- **FHIR binding**: Use SNOMED CT as the coding system for Condition, Procedure, and other clinical resources

### LOINC (Logical Observation Identifiers Names and Codes)
- **Purpose**: Universal identifiers for laboratory tests and clinical observations
- **Structure**: Numeric codes (e.g., 85354-9 = Blood pressure panel)
- **Axes**: Component, property, timing, system, scale, method
- **Usage**: Lab results, vital signs, clinical surveys, document types
- **FHIR binding**: Required coding system for Observation resources in US Core

### RxNorm
- **Purpose**: Normalized drug names linking to various drug vocabularies
- **Term types**: Semantic Clinical Drug (SCD), Semantic Branded Drug (SBD), Generic Pack, Branded Pack
- **Usage**: Medication reconciliation, drug interaction checking, e-prescribing
- **Integration**: Links NDC codes, brand names, and generic names into a unified vocabulary
- **FHIR binding**: Preferred coding system for MedicationRequest and Medication resources

### CPT (Current Procedural Terminology)
- **Purpose**: Procedure coding for physician services and outpatient billing
- **Categories**: Category I (common procedures), Category II (performance measures), Category III (emerging technology)
- **Maintained by**: American Medical Association (AMA); requires license for use
- **Usage**: Professional claims, quality reporting, revenue cycle management

### NDC (National Drug Code)
- **Purpose**: Unique product identifier for human drugs in the US
- **Structure**: 10-digit code in 3 segments: labeler, product, package (e.g., 0777-3105-02)
- **Usage**: Pharmacy dispensing, drug supply chain, FDA drug registration
- **Relationship**: Maps to RxNorm for clinical terminology normalization

## Clinical Document Architecture

### CDA / C-CDA
- **CDA**: HL7 Clinical Document Architecture; XML-based standard for clinical documents
- **C-CDA**: Consolidated CDA; standardized templates for common document types
- **Document types**: Continuity of Care Document (CCD), Discharge Summary, Progress Note, Referral Note, Care Plan
- **Sections**: Problems, Medications, Allergies, Procedures, Results, Vital Signs, Immunizations
- **Usage**: Health information exchange, care transitions, Meaningful Use / Promoting Interoperability

### C-CDA to FHIR Mapping
- Map C-CDA sections to corresponding FHIR resources (Problems to Condition, Medications to MedicationRequest)
- Use the HL7 C-CDA on FHIR Implementation Guide for standardized mappings
- Handle narrative (human-readable) and structured (machine-readable) sections

## Patient Data Normalization

- **Master Patient Index (MPI)**: Maintain a single authoritative patient identity across systems
- **Patient matching**: Use probabilistic matching algorithms (name, DOB, SSN, address) with configurable thresholds
- **Duplicate management**: Automated detection with manual review workflow for potential matches
- **Data standardization**: Normalize addresses (USPS format), phone numbers (E.164), names (case, suffixes)
- **Identifier management**: Track multiple MRNs across source systems with a unified enterprise ID
- **Data merging**: Define survivorship rules for conflicting data elements (most recent, most complete, source priority)

## Temporal Clinical Data

### Time-Series Patterns
- **Observations over time**: Vital signs, lab results, and measurements recorded at specific timestamps
- **Encounter-based grouping**: Associate observations with encounters for clinical context
- **Effective dates vs. recorded dates**: Distinguish when a finding was clinically relevant vs. when it was entered
- **Status tracking**: Resources progress through states (registered, preliminary, final, amended, cancelled)

### Data Model Considerations
- Use timestamped records with timezone awareness (UTC storage, local display)
- Design for bi-temporal queries: "What was the patient's medication list as of date X?" and "What did we know at time Y?"
- Partition time-series data by date range for query performance
- Implement point-in-time snapshots for clinical decision support and legal hold

## Clinical Decision Support Data Models

- **Rule-based CDS**: IF patient has Condition X AND is on Medication Y THEN alert for interaction
- **Order sets**: Predefined bundles of orders for common diagnoses (e.g., chest pain admission order set)
- **Evidence-based guidelines**: Model clinical pathways as structured data (diagnosis, criteria, recommended actions)
- **Alert fatigue management**: Track alert override rates, suppress low-priority alerts, implement tiered severity
- **Knowledge base design**: Separate clinical knowledge (rules, guidelines) from patient data for maintainability
- **Terminology binding**: CDS rules must reference coded concepts (SNOMED, LOINC, RxNorm), not free text
