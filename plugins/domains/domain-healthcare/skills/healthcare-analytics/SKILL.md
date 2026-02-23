---
name: healthcare-analytics
description: Healthcare analytics covering population health management, clinical decision support, quality measures (eCQM, HEDIS, MIPS), de-identified analytics, research data lakes (OMOP CDM), outcomes analysis, and social determinants of health data.
allowed-tools: Read, Grep, Glob, Bash
---

# Healthcare Analytics

## When to use
- Building risk stratification models or care gap identification pipelines
- Implementing clinical decision support alerts and managing alert fatigue
- Calculating eCQM, HEDIS, or MIPS quality measures
- De-identifying PHI for analytics or research workloads
- Setting up an OMOP CDM data lake or federated research environment
- Incorporating SDOH data into care management workflows

## Core principles
1. **Risk models need clinical validation** — HCC and LACE scores are starting points; tune thresholds against your actual population before driving care workflows
2. **Override rate is your alert quality metric** — any alert dismissed more than 90% of the time is noise; retire it or redesign it
3. **Safe Harbor is a checklist, not a guarantee** — removing 18 identifiers is necessary but not sufficient; verify residual re-identification risk before publishing data
4. **OMOP CDM enables federation** — standardize to OMOP once and run the same analytics across institutions without sharing patient-level data
5. **SDOH belongs in the risk model** — food insecurity and housing instability predict readmissions as reliably as clinical comorbidities

## Reference Files
- `references/population-health-cds.md` — risk stratification models (HCC, LACE, Charlson), care gap identification, disease registries, CDS alert types, alert fatigue management, order sets
- `references/quality-measures.md` — eCQM with CQL and QRDA, HEDIS measure calculation, MIPS quality reporting and payment adjustments
- `references/deidentification-research-data.md` — HIPAA Safe Harbor and Expert Determination, limited datasets and DUAs, OMOP CDM structure, data lake zone architecture, outcomes analysis methods
- `references/sdoh-data.md` — SDOH categories, PRAPARE and AHC-HRSN screening tools, ICD-10 Z-codes, FHIR Observation storage, community resource referral integration
