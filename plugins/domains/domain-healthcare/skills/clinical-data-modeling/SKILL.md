---
name: clinical-data-modeling
description: Clinical data modeling covering healthcare terminology systems (ICD-10, SNOMED CT, LOINC, RxNorm, CPT, NDC), clinical document architecture, patient data normalization, temporal clinical data patterns, and clinical decision support data models.
allowed-tools: Read, Grep, Glob, Bash
---

# Clinical Data Modeling

## When to use
- Designing a data model that stores diagnoses, observations, medications, or procedures
- Mapping between terminology systems (ICD-10, SNOMED, LOINC, RxNorm)
- Implementing a Master Patient Index or patient matching algorithm
- Building a C-CDA to FHIR conversion pipeline
- Designing time-series storage for vitals, labs, or clinical events
- Implementing clinical decision support rules against coded clinical data

## Core principles
1. **Coded concepts over free text** — bind every clinical element to a standard code system; free text cannot drive logic reliably
2. **MPI is ground truth** — patient identity lives in one authoritative index; all source MRNs are aliases
3. **Bi-temporal modeling by default** — separate "when it happened clinically" from "when it was recorded"; both matter for audit and legal hold
4. **Terminology mapping is lossy** — every SNOMED-to-ICD-10 map has exceptions; document them and handle unmapped concepts explicitly
5. **CDS rules are data, not code** — store clinical knowledge (rules, guidelines, order sets) separately from patient data so clinicians can update them without a deployment

## Reference Files
- `references/terminology-systems.md` — ICD-10, SNOMED CT, LOINC, RxNorm, CPT, NDC: structure, usage, FHIR bindings, and cross-system mapping
- `references/document-architecture-normalization.md` — CDA/C-CDA document types, C-CDA to FHIR mapping, Master Patient Index, probabilistic patient matching, survivorship rules
- `references/temporal-data-cds-models.md` — time-series patterns, bi-temporal query design, UTC storage, CDS rule models, order sets, alert fatigue management
