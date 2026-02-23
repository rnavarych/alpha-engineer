# PHI Encryption and Secure Data Disposal

## When to load
Implementing encryption for PHI fields or databases, configuring key management, securing service-to-service communication in healthcare microservices, or planning media sanitization and PHI disposal procedures.

## Data Encryption — At Rest

- AES-256-GCM for database column-level encryption of sensitive PHI fields
- Transparent Data Encryption (TDE) for full-database encryption
- Encrypt backups and replicas with separate key hierarchies
- Use cloud KMS for key management with automatic rotation every 90 days

## Data Encryption — In Transit

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
