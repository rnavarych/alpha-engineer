---
name: medical-device-software
description: Medical device software development covering IEC 62304 software lifecycle, ISO 14971 risk management, design controls, software verification and validation, FDA regulatory submissions, software change control, and cybersecurity for medical devices.
allowed-tools: Read, Grep, Glob, Bash
---

# Medical Device Software

## When to use
- Classifying software safety class (A, B, or C) under IEC 62304
- Planning documentation requirements for a regulated software development project
- Performing hazard analysis or building a risk management file under ISO 14971
- Structuring design controls for a 510(k), PMA, or De Novo submission
- Implementing change control for released medical device software
- Addressing FDA premarket cybersecurity guidance for a connected device

## Core principles
1. **Safety class determines everything** — get Class A/B/C right first; it drives documentation depth, testing rigor, and regulatory pathway
2. **Traceability matrix is not optional** — requirements to design to test cases must be linked; FDA will ask for it and gaps are findings
3. **Risk control hierarchy is ordered** — inherently safe design beats protective measures beats warnings; document why you couldn't go higher
4. **Verification is not validation** — "built it right" (spec compliance) and "built the right thing" (user need) are separate activities requiring separate evidence
5. **SBOM is now a submission requirement** — list every component and dependency; FDA expects it as part of premarket cybersecurity documentation

## Reference Files
- `references/iec62304-lifecycle.md` — software safety classification table, 9-step lifecycle processes, required documentation artifacts (SDP, SRS, SAD, SDD, test plans, traceability matrix)
- `references/iso14971-risk-design-controls.md` — ISO 14971 risk management process, risk control hierarchy, risk acceptability matrix, design inputs/outputs, design review, design verification and validation
- `references/vv-fda-cybersecurity.md` — V&V definitions, requirements traceability, code coverage by class, static analysis tools, 510(k)/PMA/De Novo pathways, change control classification, FDA cybersecurity guidance, SBOM, coordinated vulnerability disclosure
