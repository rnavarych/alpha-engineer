# Clinical Document Architecture and Patient Normalization

## When to load
Working with CDA or C-CDA documents, implementing care transitions or Meaningful Use workflows, building a Master Patient Index, handling duplicate patient records, or designing patient identity resolution logic.

## CDA / C-CDA

- **CDA**: HL7 Clinical Document Architecture; XML-based standard for clinical documents
- **C-CDA**: Consolidated CDA; standardized templates for common document types
- **Document types**: Continuity of Care Document (CCD), Discharge Summary, Progress Note, Referral Note, Care Plan
- **Sections**: Problems, Medications, Allergies, Procedures, Results, Vital Signs, Immunizations
- **Usage**: Health information exchange, care transitions, Meaningful Use / Promoting Interoperability

## C-CDA to FHIR Mapping
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
