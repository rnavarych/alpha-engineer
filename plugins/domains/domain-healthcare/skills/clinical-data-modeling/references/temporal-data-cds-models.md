# Temporal Clinical Data and Decision Support Models

## When to load
Designing time-series clinical data storage, building bi-temporal query capability, modeling clinical decision support rules, implementing order sets, or managing alert fatigue in CDS systems.

## Time-Series Patterns

- **Observations over time**: Vital signs, lab results, and measurements recorded at specific timestamps
- **Encounter-based grouping**: Associate observations with encounters for clinical context
- **Effective dates vs. recorded dates**: Distinguish when a finding was clinically relevant vs. when it was entered
- **Status tracking**: Resources progress through states (registered, preliminary, final, amended, cancelled)

## Data Model Considerations

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
