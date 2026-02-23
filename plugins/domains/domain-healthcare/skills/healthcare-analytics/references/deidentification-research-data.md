# De-identified Analytics and Research Data Lakes

## When to load
Building an analytics environment with PHI, implementing HIPAA Safe Harbor de-identification, setting up an OMOP CDM data lake, designing federated research infrastructure, or handling limited datasets under a DUA.

## HIPAA Safe Harbor for Analytics

- Remove all 18 HIPAA identifiers before loading data into analytics environments
- Replace dates with relative offsets (days from a reference point) to preserve temporal relationships
- Generalize geographic data to state or region level
- Aggregate age into bands; cap at 90+ for ages over 89
- Assign random study IDs unlinked to source patient identifiers

## Limited Data Sets

- Permitted for research, public health, and healthcare operations under a Data Use Agreement (DUA)
- May include dates (admission, discharge, birth, death) and geographic data (city, state, ZIP)
- Must exclude direct identifiers (name, SSN, MRN, phone, email)
- DUA must specify permitted uses, require safeguards, and prohibit re-identification

## OMOP Common Data Model (CDM)

- Standardized data model maintained by OHDSI (Observational Health Data Sciences and Informatics)
- Core tables: Person, Observation_Period, Visit_Occurrence, Condition_Occurrence, Drug_Exposure, Measurement, Procedure_Occurrence
- Uses standard vocabularies: SNOMED CT, LOINC, RxNorm mapped through OMOP concept IDs
- Enables cross-institutional federated research without sharing patient-level data
- ETL from EHR source data into OMOP CDM using established mapping conventions

## Data Lake Architecture

- Raw zone: Ingested EHR extracts, claims files, device data in original format
- Curated zone: Cleaned, normalized, and de-identified data in OMOP CDM or similar standard model
- Analytics zone: Aggregated datasets, feature stores, and materialized views for specific use cases
- Apply column-level encryption and access controls per data sensitivity tier
- Maintain data lineage from source through all transformations to analytics output

## Outcomes Analysis

- Define outcome measures clearly: mortality, readmission, length of stay, patient-reported outcomes (PROs)
- Implement risk adjustment to account for case mix differences across providers or facilities
- Use time-to-event analysis (Kaplan-Meier, Cox regression) for survival and event outcomes
- Build dashboards for provider performance feedback with peer benchmarking
- Track process measures alongside outcome measures to identify improvement opportunities
