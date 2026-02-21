---
name: healthcare-analytics
description: |
  Healthcare analytics covering population health management, clinical decision support,
  quality measures (eCQM, HEDIS, MIPS), de-identified analytics, research data lakes
  (OMOP CDM), outcomes analysis, and social determinants of health data.
allowed-tools: Read, Grep, Glob, Bash
---

# Healthcare Analytics

## Population Health Management

### Risk Stratification
- Assign patients to risk tiers (low, rising, moderate, high, complex) based on clinical and utilization data
- Use validated risk models: HCC (Hierarchical Condition Categories), LACE index (readmission risk), Charlson Comorbidity Index
- Input data: diagnoses, medications, lab results, utilization history, demographics, social determinants
- Update risk scores monthly or upon significant clinical events
- Stratified lists drive care management workflows: high-risk patients get proactive outreach

### Care Gap Identification
- Compare patient records against evidence-based guidelines to identify missing preventive care
- Common care gaps: overdue screenings (mammography, colonoscopy, HbA1c), missing immunizations, uncontrolled chronic conditions
- Generate patient outreach lists with specific gap details for care coordinators
- Track gap closure rates as a quality improvement metric
- Integrate care gap alerts into provider workflows at the point of care

### Chronic Disease Management
- Build disease registries for diabetes, hypertension, heart failure, COPD, asthma
- Track key metrics per condition: HbA1c for diabetes, BP readings for hypertension, ejection fraction for heart failure
- Identify patients not meeting treatment targets for intervention
- Support care plan adherence monitoring (medication refills, follow-up visits, self-management goals)

## Clinical Decision Support (CDS)

### CDS Alert Types
| Type | Trigger | Example |
|------|---------|---------|
| **Drug-drug interaction** | Medication order entry | Alert for concurrent warfarin and aspirin |
| **Drug-allergy** | Medication order with allergy on file | Alert for penicillin order with documented allergy |
| **Duplicate order** | Same or similar order already active | Alert for duplicate lab order within 24 hours |
| **Dosing guidance** | Order with renal/hepatic impairment | Suggest dose adjustment for low eGFR |
| **Preventive care reminder** | Patient visit with overdue screening | Prompt for annual diabetic eye exam |
| **Diagnostic support** | Lab result outside critical range | Flag critical potassium level for immediate review |

### Alert Fatigue Management
- Track override rates per alert type; alerts overridden more than 90% of the time need redesign
- Implement tiered severity: informational (passive), warning (interruptive but dismissible), hard stop (requires action)
- Suppress duplicate alerts within clinically appropriate windows
- Allow department and specialty-specific alert configuration
- Regularly review and retire low-value alerts based on clinician feedback

### Order Sets
- Pre-built bundles of orders for common clinical scenarios (e.g., chest pain admission, post-surgical care)
- Include medications, labs, imaging, nursing orders, and consults
- Based on evidence-based guidelines and institutional protocols
- Track order set utilization and outcomes for continuous improvement

## Quality Measures

### eCQM (Electronic Clinical Quality Measures)
- CMS-defined measures calculated from EHR data for quality reporting
- Specified using Clinical Quality Language (CQL) for computable measure logic
- Common domains: preventive care, chronic disease, patient safety, care coordination
- Report via QRDA (Quality Reporting Document Architecture) Category I (patient-level) and Category III (aggregate)

### HEDIS (Healthcare Effectiveness Data and Information Set)
- NCQA-managed quality measures for health plans
- Covers effectiveness of care, access, utilization, patient experience
- Key measures: Comprehensive Diabetes Care, Controlling High Blood Pressure, Breast Cancer Screening
- Hybrid measures combine claims data with medical record review

### MIPS (Merit-based Incentive Payment System)
- CMS program adjusting Medicare payments based on quality, cost, improvement activities, and promoting interoperability
- Report quality measures, improvement activities, and promoting interoperability measures annually
- Performance scores determine payment adjustments (bonus or penalty)

## De-identified Analytics

### HIPAA Safe Harbor for Analytics
- Remove all 18 HIPAA identifiers before loading data into analytics environments
- Replace dates with relative offsets (days from a reference point) to preserve temporal relationships
- Generalize geographic data to state or region level
- Aggregate age into bands; cap at 90+ for ages over 89
- Assign random study IDs unlinked to source patient identifiers

### Limited Data Sets
- Permitted for research, public health, and healthcare operations under a Data Use Agreement (DUA)
- May include dates (admission, discharge, birth, death) and geographic data (city, state, ZIP)
- Must exclude direct identifiers (name, SSN, MRN, phone, email)
- DUA must specify permitted uses, require safeguards, and prohibit re-identification

## Research Data Lakes

### OMOP Common Data Model (CDM)
- Standardized data model maintained by OHDSI (Observational Health Data Sciences and Informatics)
- Core tables: Person, Observation_Period, Visit_Occurrence, Condition_Occurrence, Drug_Exposure, Measurement, Procedure_Occurrence
- Uses standard vocabularies: SNOMED CT, LOINC, RxNorm mapped through OMOP concept IDs
- Enables cross-institutional federated research without sharing patient-level data
- ETL from EHR source data into OMOP CDM using established mapping conventions

### Data Lake Architecture
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

## Social Determinants of Health (SDOH)

### SDOH Data Categories
- **Economic stability**: Employment, income, food insecurity, housing instability
- **Education**: Literacy, language, educational attainment
- **Healthcare access**: Insurance coverage, transportation barriers, provider availability
- **Neighborhood**: Safety, environmental quality, broadband access
- **Social and community**: Social isolation, discrimination, incarceration history

### SDOH Data Collection
- Screen patients using validated tools: PRAPARE, AHC-HRSN (Accountable Health Communities)
- Code SDOH observations using ICD-10-CM Z-codes (Z55-Z65 range) and LOINC survey codes
- Store SDOH data as FHIR Observation resources linked to the patient
- Integrate SDOH data into risk models and care gap identification
- Connect patients to community resources through closed-loop referral platforms (e.g., Unite Us, Aunt Bertha/findhelp)
