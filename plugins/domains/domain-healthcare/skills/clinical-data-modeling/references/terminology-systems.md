# Terminology Systems

## When to load
Working with clinical codes, building a vocabulary mapping layer, linking EHR data to billing codes, configuring FHIR resource coding systems, or troubleshooting code mismatches between systems.

## ICD-10 (International Classification of Diseases, 10th Revision)
- **Purpose**: Diagnosis codes for clinical documentation and billing
- **ICD-10-CM**: Clinical Modification for diagnosis coding in the US
- **ICD-10-PCS**: Procedure Coding System for inpatient procedures
- **Structure**: Alphanumeric codes (e.g., E11.65 = Type 2 diabetes with hyperglycemia)
- **Usage**: Required on claims, problem lists, discharge summaries
- **Updates**: Annual updates effective October 1 each year

## SNOMED CT (Systematized Nomenclature of Medicine - Clinical Terms)
- **Purpose**: Comprehensive clinical terminology for EHR data capture
- **Coverage**: 350,000+ concepts spanning findings, procedures, body structures, organisms, substances
- **Structure**: Concept IDs with hierarchical is-a relationships and defining attributes
- **Usage**: Clinical documentation, clinical decision support rules, interoperability mapping
- **Mapping**: SNOMED-to-ICD-10 maps available for billing translation
- **FHIR binding**: Use SNOMED CT as the coding system for Condition, Procedure, and other clinical resources

## LOINC (Logical Observation Identifiers Names and Codes)
- **Purpose**: Universal identifiers for laboratory tests and clinical observations
- **Structure**: Numeric codes (e.g., 85354-9 = Blood pressure panel)
- **Axes**: Component, property, timing, system, scale, method
- **Usage**: Lab results, vital signs, clinical surveys, document types
- **FHIR binding**: Required coding system for Observation resources in US Core

## RxNorm
- **Purpose**: Normalized drug names linking to various drug vocabularies
- **Term types**: Semantic Clinical Drug (SCD), Semantic Branded Drug (SBD), Generic Pack, Branded Pack
- **Usage**: Medication reconciliation, drug interaction checking, e-prescribing
- **Integration**: Links NDC codes, brand names, and generic names into a unified vocabulary
- **FHIR binding**: Preferred coding system for MedicationRequest and Medication resources

## CPT (Current Procedural Terminology)
- **Purpose**: Procedure coding for physician services and outpatient billing
- **Categories**: Category I (common procedures), Category II (performance measures), Category III (emerging technology)
- **Maintained by**: American Medical Association (AMA); requires license for use
- **Usage**: Professional claims, quality reporting, revenue cycle management

## NDC (National Drug Code)
- **Purpose**: Unique product identifier for human drugs in the US
- **Structure**: 10-digit code in 3 segments: labeler, product, package (e.g., 0777-3105-02)
- **Usage**: Pharmacy dispensing, drug supply chain, FDA drug registration
- **Relationship**: Maps to RxNorm for clinical terminology normalization
