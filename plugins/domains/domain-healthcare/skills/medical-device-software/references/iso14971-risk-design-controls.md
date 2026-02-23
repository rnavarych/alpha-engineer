# ISO 14971 Risk Management and Design Controls

## When to load
Performing hazard analysis, building a risk management file, designing a FMEA or FTA, applying the risk control hierarchy, or structuring design inputs, design outputs, and design reviews for a regulated device.

## Risk Management Process (ISO 14971)

1. **Risk analysis**: Identify intended use, foreseeable misuse, and hazardous situations
2. **Hazard identification**: Systematic identification of hazards (FMEA, FTA, HAZOP)
3. **Risk estimation**: Determine severity of harm and probability of occurrence
4. **Risk evaluation**: Compare estimated risk against acceptance criteria
5. **Risk control**: Implement measures to reduce unacceptable risks
6. **Residual risk evaluation**: Verify overall residual risk is acceptable
7. **Risk management report**: Summarize the risk management process and outcomes

## Risk Control Hierarchy

1. **Inherently safe design**: Eliminate the hazard by design (preferred)
2. **Protective measures**: Add alarms, interlocks, or safety mechanisms in the device
3. **Information for safety**: Warnings, instructions, training (least preferred, last resort)

## Risk Acceptability Matrix

| Probability \ Severity | Negligible | Minor | Serious | Critical | Catastrophic |
|------------------------|-----------|-------|---------|----------|-------------|
| Frequent               | Medium    | High  | High    | Unacceptable | Unacceptable |
| Probable               | Low       | Medium| High    | High     | Unacceptable |
| Occasional             | Low       | Low   | Medium  | High     | High |
| Remote                 | Negligible| Low   | Low     | Medium   | High |
| Improbable             | Negligible| Negligible | Low | Low     | Medium |

## Design Controls

### Design Input
- User needs, intended use, and use environment
- Performance requirements (accuracy, speed, capacity)
- Safety requirements derived from risk analysis
- Regulatory requirements (IEC 62304, IEC 62366 usability, applicable FDA guidance)
- Interface requirements (hardware, network, other software systems)

### Design Output
- Software architecture and detailed design documents
- Source code and build artifacts
- Labeling and instructions for use
- Manufacturing and deployment specifications

### Design Review
- Conduct reviews at defined milestones (requirements, architecture, detailed design, pre-release)
- Include independent reviewers not directly involved in the design
- Document review findings, action items, and resolution

### Design Verification
- Confirm design outputs meet design inputs through testing, inspection, or analysis
- Unit tests, integration tests, system tests with traceability to requirements
- Code review and static analysis for coding standard compliance

### Design Validation
- Confirm the device meets user needs and intended use in the actual or simulated use environment
- Usability testing with representative users (IEC 62366)
- Clinical evaluation or simulation where applicable
