---
name: phi-data-handling
description: |
  Protected Health Information (PHI) data handling covering the 18 HIPAA identifiers,
  de-identification methods (Safe Harbor, Expert Determination), minimum necessary
  principle, access controls, audit logging, encryption, and secure disposal.
allowed-tools: Read, Grep, Glob, Bash
---

# PHI Data Handling

## The 18 HIPAA Identifiers

Any of these elements, when linked to health information, constitute PHI:

1. **Names** (full or partial)
2. **Geographic data** smaller than a state (street address, city, ZIP code)
3. **Dates** related to an individual (birth date, admission date, discharge date, death date) except year
4. **Phone numbers**
5. **Fax numbers**
6. **Email addresses**
7. **Social Security numbers**
8. **Medical record numbers**
9. **Health plan beneficiary numbers**
10. **Account numbers**
11. **Certificate/license numbers**
12. **Vehicle identifiers** (license plate numbers, VINs)
13. **Device identifiers and serial numbers**
14. **Web URLs**
15. **IP addresses**
16. **Biometric identifiers** (fingerprints, voiceprints, retinal scans)
17. **Full-face photographs** and comparable images
18. **Any other unique identifying number, characteristic, or code**

## De-identification Methods

### Safe Harbor Method
Remove all 18 identifiers listed above from the dataset:
- Replace names with pseudonyms or remove entirely
- Generalize geographic data to state level or first 3 digits of ZIP (if population > 20,000)
- Generalize dates to year only; for ages over 89, aggregate into a single category (90+)
- Remove all direct identifiers (SSN, MRN, phone, email, etc.)
- Verify no residual information could re-identify individuals
- No statistical expertise required; follow the checklist rigorously

### Expert Determination Method
- Engage a qualified statistical expert
- Expert applies statistical and scientific methods to determine re-identification risk
- Must demonstrate that the risk of identifying any individual is "very small"
- Document the methods, results, and expert's qualifications
- Allows retention of more data elements than Safe Harbor when justified
- Preferred when research or analytics require richer datasets

## Minimum Necessary Principle

- Limit PHI access to the minimum amount needed for the specific task
- Define role-based data views: clinicians see clinical data, billing sees billing data
- Implement field-level access controls where possible (e.g., hide SSN from clinical views)
- Apply data filtering at the API layer to strip unnecessary fields from responses
- Review and adjust access levels quarterly

## Access Controls

### Role-Based Access Control (RBAC)
| Role | Access Level | Example Permissions |
|------|-------------|-------------------|
| Attending Physician | Full clinical | Read/write all clinical data for assigned patients |
| Nurse | Clinical care | Read/write vitals, medications, care notes for assigned unit |
| Specialist | Consultation | Read-only access to referred patient records |
| Billing Staff | Financial | Read demographics and billing codes; no clinical notes |
| Administrator | System | User management, audit review; no direct PHI access |
| Patient | Self-service | Read own records, request amendments |
| Researcher | De-identified | Access only to de-identified or limited datasets |

### Access Control Implementation
- Enforce authentication with MFA for all PHI-accessing systems
- Implement break-glass procedures for emergency access with mandatory post-access review
- Log and alert on access to VIP or employee patient records
- Restrict access by care relationship (patient-provider assignment)
- Automatically expire temporary access grants

## Audit Logging

### Required Log Fields
- **Who**: User ID, role, department
- **What**: Resource type, resource ID, specific fields accessed
- **When**: Timestamp with timezone (ISO 8601)
- **Where**: Source IP address, application name, device identifier
- **Action**: Read, create, update, delete, print, export, transmit
- **Outcome**: Success or failure with reason

### Logging Best Practices
- Log all PHI access, not just modifications
- Store audit logs separately from application data with restricted access
- Retain logs for a minimum of 6 years per HIPAA requirements
- Implement tamper-evident logging (append-only, cryptographic chaining)
- Run automated reports: access frequency, unusual patterns, after-hours access
- Review high-risk access logs (VIP patients, behavioral health, HIV/STI) daily

## Data Encryption

### At Rest
- AES-256-GCM for database column-level encryption of sensitive PHI fields
- Transparent Data Encryption (TDE) for full-database encryption
- Encrypt backups and replicas with separate key hierarchies
- Use cloud KMS for key management with automatic rotation every 90 days

### In Transit
- TLS 1.2+ (prefer TLS 1.3) for all API and web traffic
- Mutual TLS for service-to-service communication within microservices
- Encrypt message queue payloads containing PHI
- VPN or private connectivity for connections to on-premises EHR systems

## Secure Data Disposal

- **Digital media**: Use NIST SP 800-88 guidelines (Clear, Purge, or Destroy)
- **Database records**: Cryptographic erasure (destroy the encryption key) for efficient bulk disposal
- **Paper records**: Cross-cut shredding or incineration
- **Cloud storage**: Verify provider's data destruction certification and process
- **Backup media**: Include in disposal schedules; do not retain expired PHI in old backups
- Document all disposal actions with date, method, responsible party, and witness
