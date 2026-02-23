# FHIR Server Implementation

## When to load
Standing up a FHIR server, selecting between HAPI FHIR or Microsoft FHIR Server, configuring resource versioning and subscriptions, or building the capability statement for a FHIR endpoint.

## HAPI FHIR (Java)

- Open-source, widely adopted, supports FHIR R4 and R5
- JPA backend for persistence with PostgreSQL or MySQL
- Built-in search parameter indexing and subscription support
- Extensible interceptor framework for custom logic (validation, authorization, auditing)

## Microsoft FHIR Server

- Azure Health Data Services (managed) or open-source .NET implementation
- Native Azure AD integration for SMART on FHIR authorization
- Built-in FHIR-to-DICOM and FHIR-to-HL7v2 conversion tools

## Implementation Considerations

- Enable resource versioning (vRead) for audit trails
- Implement conditional create/update to prevent duplicates
- Use Subscriptions (R5 topic-based or R4 Criteria-based) for event-driven workflows
- Set up capability statement (`/metadata`) accurately reflecting supported features
