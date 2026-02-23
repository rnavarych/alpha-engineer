# IEC 62304 Software Lifecycle

## When to load
Planning a medical device software development project, determining software safety classification, defining documentation requirements per class, structuring verification activities, or preparing a software development plan for regulatory review.

## Software Safety Classification

| Class | Risk | Requirements | Examples |
|-------|------|-------------|----------|
| **Class A** | No injury or damage to health | Basic lifecycle, minimal documentation | Wellness apps, scheduling software |
| **Class B** | Non-serious injury possible | Full lifecycle, detailed documentation | Monitoring displays, clinical calculators |
| **Class C** | Death or serious injury possible | Full lifecycle, rigorous documentation and review | Infusion pump software, ventilator control, diagnostic algorithms |

## Lifecycle Processes

1. **Software development planning**: Define lifecycle model, tools, standards, and deliverables
2. **Software requirements analysis**: Capture functional, performance, and safety requirements
3. **Software architectural design**: Define software structure, interfaces, and data flows
4. **Software detailed design**: Specify modules, algorithms, and data structures (Class B and C)
5. **Software unit implementation**: Code to the detailed design with coding standards
6. **Software unit verification**: Unit testing with traceability to detailed design (Class B and C)
7. **Software integration and integration testing**: Assemble units and verify interfaces
8. **Software system testing**: Verify the complete system against software requirements
9. **Software release**: Document release, known anomalies, and release criteria

## Documentation Requirements

- Software Development Plan (SDP)
- Software Requirements Specification (SRS)
- Software Architecture Document (SAD)
- Software Detailed Design Document (SDD) (Class B and C)
- Software Test Plans and Reports
- Traceability Matrix (requirements to design to tests)
