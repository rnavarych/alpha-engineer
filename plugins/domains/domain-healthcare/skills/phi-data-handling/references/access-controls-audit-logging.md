# Access Controls and Audit Logging for PHI

## When to load
Designing role-based access for a healthcare system, implementing break-glass emergency access, configuring audit logging for PHI access events, or reviewing access control gaps in an existing system.

## Minimum Necessary Principle

- Limit PHI access to the minimum amount needed for the specific task
- Define role-based data views: clinicians see clinical data, billing sees billing data
- Implement field-level access controls where possible (e.g., hide SSN from clinical views)
- Apply data filtering at the API layer to strip unnecessary fields from responses
- Review and adjust access levels quarterly

## Role-Based Access Control (RBAC)

| Role | Access Level | Example Permissions |
|------|-------------|-------------------|
| Attending Physician | Full clinical | Read/write all clinical data for assigned patients |
| Nurse | Clinical care | Read/write vitals, medications, care notes for assigned unit |
| Specialist | Consultation | Read-only access to referred patient records |
| Billing Staff | Financial | Read demographics and billing codes; no clinical notes |
| Administrator | System | User management, audit review; no direct PHI access |
| Patient | Self-service | Read own records, request amendments |
| Researcher | De-identified | Access only to de-identified or limited datasets |

## Access Control Implementation

- Enforce authentication with MFA for all PHI-accessing systems
- Implement break-glass procedures for emergency access with mandatory post-access review
- Log and alert on access to VIP or employee patient records
- Restrict access by care relationship (patient-provider assignment)
- Automatically expire temporary access grants

## Audit Logging — Required Log Fields

- **Who**: User ID, role, department
- **What**: Resource type, resource ID, specific fields accessed
- **When**: Timestamp with timezone (ISO 8601)
- **Where**: Source IP address, application name, device identifier
- **Action**: Read, create, update, delete, print, export, transmit
- **Outcome**: Success or failure with reason

## Logging Best Practices

- Log all PHI access, not just modifications
- Store audit logs separately from application data with restricted access
- Retain logs for a minimum of 6 years per HIPAA requirements
- Implement tamper-evident logging (append-only, cryptographic chaining)
- Run automated reports: access frequency, unusual patterns, after-hours access
- Review high-risk access logs (VIP patients, behavioral health, HIV/STI) daily
