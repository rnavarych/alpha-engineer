---
name: medical-device-software
description: |
  Medical device software development covering IEC 62304 software lifecycle, ISO 14971
  risk management, design controls, software verification and validation, FDA regulatory
  submissions, software change control, and cybersecurity for medical devices.
allowed-tools: Read, Grep, Glob, Bash
---

# Medical Device Software

## IEC 62304 Software Lifecycle

### Software Safety Classification
| Class | Risk | Requirements | Examples |
|-------|------|-------------|----------|
| **Class A** | No injury or damage to health | Basic lifecycle, minimal documentation | Wellness apps, scheduling software |
| **Class B** | Non-serious injury possible | Full lifecycle, detailed documentation | Monitoring displays, clinical calculators |
| **Class C** | Death or serious injury possible | Full lifecycle, rigorous documentation and review | Infusion pump software, ventilator control, diagnostic algorithms |

### Lifecycle Processes
1. **Software development planning**: Define lifecycle model, tools, standards, and deliverables
2. **Software requirements analysis**: Capture functional, performance, and safety requirements
3. **Software architectural design**: Define software structure, interfaces, and data flows
4. **Software detailed design**: Specify modules, algorithms, and data structures (Class B and C)
5. **Software unit implementation**: Code to the detailed design with coding standards
6. **Software unit verification**: Unit testing with traceability to detailed design (Class B and C)
7. **Software integration and integration testing**: Assemble units and verify interfaces
8. **Software system testing**: Verify the complete system against software requirements
9. **Software release**: Document release, known anomalies, and release criteria

### Documentation Requirements
- Software Development Plan (SDP)
- Software Requirements Specification (SRS)
- Software Architecture Document (SAD)
- Software Detailed Design Document (SDD) (Class B and C)
- Software Test Plans and Reports
- Traceability Matrix (requirements to design to tests)

## Risk Management (ISO 14971)

### Risk Management Process
1. **Risk analysis**: Identify intended use, foreseeable misuse, and hazardous situations
2. **Hazard identification**: Systematic identification of hazards (FMEA, FTA, HAZOP)
3. **Risk estimation**: Determine severity of harm and probability of occurrence
4. **Risk evaluation**: Compare estimated risk against acceptance criteria
5. **Risk control**: Implement measures to reduce unacceptable risks
6. **Residual risk evaluation**: Verify overall residual risk is acceptable
7. **Risk management report**: Summarize the risk management process and outcomes

### Risk Control Hierarchy
1. **Inherently safe design**: Eliminate the hazard by design (preferred)
2. **Protective measures**: Add alarms, interlocks, or safety mechanisms in the device
3. **Information for safety**: Warnings, instructions, training (least preferred, last resort)

### Risk Acceptability Matrix
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

## Software Verification and Validation (V&V)

- **Verification**: "Did we build the product right?" (testing against specifications)
- **Validation**: "Did we build the right product?" (testing against user needs)
- Maintain a Requirements Traceability Matrix linking requirements to design elements to test cases
- Achieve appropriate code coverage: statement coverage (Class A), branch coverage (Class B), MC/DC (Class C)
- Use static analysis tools (MISRA C/C++, Coverity, Polyspace) for safety-critical code
- Perform regression testing after every change

## FDA Regulatory Submissions

### 510(k) Premarket Notification
- Demonstrate substantial equivalence to a legally marketed predicate device
- Include software documentation per FDA guidance on software in medical devices
- Software Level of Concern (Minor, Moderate, Major) determines documentation depth

### PMA (Premarket Approval)
- Required for Class III high-risk devices with no predicate
- Comprehensive clinical evidence and full design history file
- Most rigorous review pathway

### De Novo Classification
- For novel low-to-moderate risk devices without a predicate
- Creates a new regulatory classification and product code

## Software Change Control

- Classify changes by impact: safety-related, regulatory, functional, cosmetic
- Perform regression risk analysis for every change (what could this break?)
- Require documented approval before implementing changes in released software
- Maintain complete change history with rationale, risk analysis, and verification results
- Determine if the change requires a new regulatory submission (e.g., new 510(k))

## Cybersecurity for Medical Devices

### FDA Premarket Cybersecurity Guidance
- Perform threat modeling during design (STRIDE, attack trees)
- Implement secure by design: authentication, encryption, access control, secure boot
- Provide a Software Bill of Materials (SBOM) listing all components and dependencies
- Design for updateability: support secure software updates and patches in the field
- Address end-of-life planning: how will security be maintained when support ends

### Key Cybersecurity Controls
- Encrypt data at rest and in transit on the device and during communication
- Implement device authentication and integrity verification
- Log security events and support remote monitoring where appropriate
- Harden the device OS and disable unnecessary services and ports
- Plan for coordinated vulnerability disclosure
