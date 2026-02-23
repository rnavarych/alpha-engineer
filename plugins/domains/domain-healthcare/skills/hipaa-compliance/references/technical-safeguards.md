# Technical Safeguards

## When to load
Implementing encryption for PHI at rest or in transit, configuring access controls, setting up audit logging, designing transmission security for APIs and microservices, or reviewing system architecture for HIPAA technical compliance.

## Encryption

- **At rest**: AES-256-GCM for all PHI stored in databases, file systems, and backups
- **In transit**: TLS 1.2+ (prefer TLS 1.3) for all network communication carrying PHI
- **Key management**: Use cloud KMS (AWS KMS, Azure Key Vault, GCP Cloud KMS) with automatic key rotation
- **Envelope encryption**: Encrypt data with a data encryption key (DEK), then encrypt the DEK with a key encryption key (KEK)

## Access Controls

- **Unique user identification**: Every user must have a unique identifier; no shared accounts
- **Emergency access procedure**: Documented break-glass process for emergency PHI access with post-access review
- **Automatic logoff**: Session timeout after 15 minutes of inactivity for clinical workstations
- **Role-based access**: Define roles (clinician, nurse, admin, billing, patient, researcher) with minimum necessary permissions

## Audit Controls

- Log every PHI access event: user ID, timestamp, action (read/write/delete), resource accessed, IP address
- Retain audit logs for a minimum of 6 years (HIPAA retention requirement)
- Protect logs from tampering (write-once storage, cryptographic hashing)
- Implement automated alerting for suspicious access patterns (after-hours access, bulk downloads, access to VIP records)

## Transmission Security

- Enforce TLS for all API endpoints serving PHI
- Use mutual TLS (mTLS) for service-to-service communication in microservices
- Encrypt email containing PHI or use a secure messaging portal
- Disable legacy protocols (SSLv3, TLS 1.0, TLS 1.1)
