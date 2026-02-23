# SOX Controls and PSD2 Requirements

## When to load
Load when implementing Sarbanes-Oxley controls (segregation of duties, access controls, change
management, evidence collection) or PSD2 SCA requirements and open banking API obligations.

## SOX Controls (Sarbanes-Oxley)

### Segregation of Duties (SoD)
- No single user can: create a payment, approve it, AND execute it
- Implement role-based access with mutually exclusive permission sets
- Enforce SoD in code: check that approver != initiator before processing
- Maintain an SoD conflict matrix and validate against user role assignments
- Log all privilege escalations and emergency access (break-glass) usage

### Access Controls
- Quarterly access recertification: managers review and confirm user access
- Automated deprovisioning on employee termination (HR system integration)
- Privileged access management (PAM): just-in-time access with time-limited grants
- Multi-factor authentication for all administrative and financial system access
- Access request and approval workflows with audit trail

### Change Management
- All production changes require documented change request with approval
- Separate environments: development, staging, pre-production, production
- Code review required before merge (minimum two reviewers for financial logic)
- Automated testing gate: changes cannot deploy without passing test suites
- Post-deployment verification and rollback procedures documented

### Evidence Collection
- Automate control evidence gathering (access logs, approval records, test results)
- Store evidence in tamper-proof, time-stamped repositories
- Map controls to SOX requirements with traceability matrix
- Continuous control monitoring dashboards for real-time compliance status

## PSD2 (Payment Services Directive 2)

### SCA Requirements
- Authenticate using two of three factors: knowledge (PIN), possession (phone), inherence (biometric)
- Dynamic linking: authentication code must be bound to specific amount and payee
- Independence: compromise of one factor must not compromise the other
- Implementation: 3DS2 for card payments, app-based authentication for banking

### SCA Exemptions
- Low-value transactions: cumulative <100 EUR or individual <30 EUR
- Recurring payments: SCA required on first payment only, with same amount and payee
- Trusted beneficiaries: customer-maintained whitelist
- Transaction Risk Analysis (TRA) exemption based on fraud rate thresholds:
  - <500 EUR if fraud rate <0.13%
  - <250 EUR if fraud rate <0.06%
  - <100 EUR if fraud rate <0.01%

### Open Banking API Standards
- Berlin Group NextGenPSD2: predominant in continental Europe
- UK Open Banking: CMA-mandated standard for UK banks
- STET PSD2 API: French banking standard
- Polish API: KIR standard for Polish market
- All require: versioning, availability SLA (99.5%+), performance targets (<5s response)
