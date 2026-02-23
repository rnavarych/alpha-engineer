# Software V&V, FDA Submissions, Change Control, and Cybersecurity

## When to load
Planning verification and validation activities, preparing a 510(k) or PMA submission, implementing software change control for a released device, or addressing FDA premarket cybersecurity guidance requirements.

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
