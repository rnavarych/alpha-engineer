# Interface Engines and Document Exchange

## When to load
Selecting or configuring a healthcare integration engine, designing message routing channels, implementing CCD/C-CDA document generation or parsing, or setting up testing environments with vendor sandboxes.

## Mirth Connect (NextGen Connect)

- Open-source integration engine widely used in healthcare
- Channel-based architecture: source connector, filters, transformers, destination connector
- Supports HL7v2, FHIR, CDA, CSV, JSON, XML, DICOM
- JavaScript-based message transformation
- Built-in message queuing, retry logic, and error handling

## Rhapsody Integration Engine

- Enterprise-grade integration engine by Rhapsody (formerly InterSystems)
- Visual route designer for message flow configuration
- Strong HL7v2 and FHIR support with built-in validation
- High availability and clustering for production workloads

## Interface Engine Best Practices

- Centralize all EHR integrations through the interface engine
- Implement message logging and audit trails for all transactions
- Use message queues for reliable delivery with configurable retry policies
- Build environment-specific configurations (dev, staging, production)
- Monitor interface health: message throughput, error rates, queue depths

## CCD/C-CDA Document Exchange

- Use Continuity of Care Documents (CCD) for care transitions between providers
- Generate C-CDA documents for patient discharge summaries, referrals, and transfer of care
- Validate C-CDA documents against standard templates before sending
- Parse inbound C-CDA documents and reconcile data (medications, allergies, problems) with existing records
- Support Direct messaging (Direct Protocol) for secure point-to-point document exchange

## Integration Testing

- **Epic sandbox**: open.epic.com with synthetic patients and FHIR R4 endpoints
- **Cerner sandbox**: code.cerner.com with test tenants and sample data
- **Touchstone**: HL7 FHIR testing platform for conformance and interoperability testing
- **Synthea**: Generate synthetic but realistic patient data for testing pipelines
- Test with realistic clinical scenarios: admissions, orders, results, discharges
- Validate message transforms with before/after comparison for every supported message type
