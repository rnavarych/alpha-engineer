---
name: hipaa-compliance
description: |
  HIPAA compliance implementation covering technical, administrative, and physical safeguards,
  Business Associate Agreement checklists, risk assessment methodology, and breach notification
  procedures. Use when building or reviewing healthcare systems that handle PHI.
allowed-tools: Read, Grep, Glob, Bash
---

# HIPAA Compliance Implementation

## Technical Safeguards

### Encryption
- **At rest**: AES-256-GCM for all PHI stored in databases, file systems, and backups
- **In transit**: TLS 1.2+ (prefer TLS 1.3) for all network communication carrying PHI
- **Key management**: Use cloud KMS (AWS KMS, Azure Key Vault, GCP Cloud KMS) with automatic key rotation
- **Envelope encryption**: Encrypt data with a data encryption key (DEK), then encrypt the DEK with a key encryption key (KEK)

### Access Controls
- **Unique user identification**: Every user must have a unique identifier; no shared accounts
- **Emergency access procedure**: Documented break-glass process for emergency PHI access with post-access review
- **Automatic logoff**: Session timeout after 15 minutes of inactivity for clinical workstations
- **Role-based access**: Define roles (clinician, nurse, admin, billing, patient, researcher) with minimum necessary permissions

### Audit Controls
- Log every PHI access event: user ID, timestamp, action (read/write/delete), resource accessed, IP address
- Retain audit logs for a minimum of 6 years (HIPAA retention requirement)
- Protect logs from tampering (write-once storage, cryptographic hashing)
- Implement automated alerting for suspicious access patterns (after-hours access, bulk downloads, access to VIP records)

### Transmission Security
- Enforce TLS for all API endpoints serving PHI
- Use mutual TLS (mTLS) for service-to-service communication in microservices
- Encrypt email containing PHI or use a secure messaging portal
- Disable legacy protocols (SSLv3, TLS 1.0, TLS 1.1)

## Administrative Safeguards

### Security Officer
- Designate a HIPAA Security Officer responsible for security policy and compliance
- Document the officer's responsibilities and authority

### Workforce Training
- Conduct HIPAA training at onboarding and annually thereafter
- Cover PHI handling, phishing awareness, incident reporting, and device security
- Document training completion and maintain records for 6 years

### Access Management
- Implement provisioning workflows tied to HR onboarding/offboarding
- Conduct quarterly access reviews to verify minimum necessary permissions
- Revoke access immediately upon employee termination or role change

### Incident Procedures
- Maintain a documented incident response plan specific to PHI breaches
- Define roles: incident commander, forensic analyst, legal counsel, communications
- Conduct tabletop exercises annually to test the response plan

### Contingency Plan
- **Data backup**: Automated daily backups of all PHI with encryption and integrity verification
- **Disaster recovery**: RTO and RPO targets documented, tested quarterly
- **Emergency mode**: Procedures for operating critical clinical systems during outages

### Risk Analysis
- Conduct a comprehensive risk assessment at least annually
- Reassess after significant system changes, security incidents, or regulatory updates
- Document all identified risks, likelihood, impact, and remediation plans

## Physical Safeguards

### Facility Access
- Restrict physical access to servers and workstations housing PHI
- Use badge access, visitor logs, and surveillance for data center entry

### Workstation Security
- Enable screen locks and enforce clean desk policies
- Prohibit PHI on personal devices unless MDM is deployed with remote wipe capability
- Position screens to prevent unauthorized viewing in clinical settings

### Device and Media Controls
- Encrypt all portable devices (laptops, USB drives, mobile phones) containing PHI
- Maintain hardware and media inventory with tracking of PHI storage
- Use NIST 800-88 compliant methods for media sanitization and disposal

## Business Associate Agreement Checklist

Before engaging any vendor that will access PHI:
1. Confirm a signed BAA is in place before sharing any PHI
2. Verify the BAA specifies permitted uses, required safeguards, and breach notification obligations
3. Confirm subcontractor BAA requirements flow down to the vendor's subcontractors
4. Include audit rights allowing you to verify the BA's compliance
5. Specify PHI return or destruction obligations upon contract termination
6. Review and update BAAs at least annually or upon contract renewal

## Risk Assessment Methodology

1. **Inventory**: Catalog all systems, data flows, and storage locations containing PHI
2. **Threat identification**: Natural disasters, malicious actors, insider threats, system failures
3. **Vulnerability assessment**: Penetration testing, configuration review, access control gaps
4. **Likelihood and impact scoring**: Rate each risk on a 1-5 scale for probability and impact
5. **Risk prioritization**: Address high-likelihood, high-impact risks first
6. **Control implementation**: Apply technical, administrative, or physical controls
7. **Residual risk acceptance**: Document accepted risks with management sign-off
8. **Continuous monitoring**: Reassess risks on an ongoing basis

## Breach Notification Procedures

1. **Discover and investigate**: Identify the scope and nature of the breach within 24 hours
2. **Perform risk assessment**: Evaluate the four factors (nature of PHI, unauthorized recipient, actual access, mitigation)
3. **Notify individuals**: Written notification within 60 days of discovery
4. **Notify HHS**: Breaches of 500+ individuals reported within 60 days; under 500 reported annually
5. **Notify media**: Required for breaches affecting 500+ residents of a single state
6. **Document everything**: Maintain breach investigation records for 6 years
