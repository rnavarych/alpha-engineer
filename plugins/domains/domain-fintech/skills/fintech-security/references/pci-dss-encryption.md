# PCI DSS Compliance and Data Encryption

## When to load
Load when scoping PCI DSS requirements for fintech, designing tokenization architecture, implementing
field-level encryption, or configuring TLS/mTLS for cardholder data environments.

## PCI DSS for Fintech

### Scope Reduction Strategy
- Tokenize card data at the earliest point to minimize CDE scope
- Network segmentation: isolate cardholder data environment (CDE)
- If you store card data (rare): PCI DSS Level 1 with annual QSA audit
- If you use tokens only: SAQ A or SAQ A-EP (reduced scope)

### Key PCI Requirements for Fintech
- **Req 3**: protect stored cardholder data (tokenization, encryption, masking)
- **Req 4**: encrypt transmission (TLS 1.2+, no fallback to older versions)
- **Req 6**: secure development (SAST, DAST, dependency scanning, code review)
- **Req 7**: restrict access (need-to-know, role-based, least privilege)
- **Req 8**: authentication (MFA for all access to CDE, unique IDs)
- **Req 10**: logging and monitoring (all access to cardholder data logged)
- **Req 11**: regular testing (quarterly ASV scans, annual pen test)

### Tokenization Architecture
- Replace sensitive data (PAN, SSN) with non-reversible tokens
- Token vault: HSM-protected mapping between token and original value
- Format-preserving tokens: maintain data format for legacy system compatibility
- Detokenization: restricted to authorized services with audit logging

## Data Encryption

### Field-Level Encryption (FLE)
- Encrypt specific sensitive fields before database storage
- Fields to encrypt: account numbers, SSN/TIN, date of birth, card data
- Application-level encryption: data encrypted before reaching database
- Separate encryption keys per field type or data classification
- Searchable encryption: use blind index (HMAC) for equality searches on encrypted fields

### Encryption at Rest
- Database-level TDE (Transparent Data Encryption) as baseline
- Application-level FLE for defense-in-depth above TDE
- Backup encryption: all backups encrypted with separate key from production
- Key storage: never store encryption keys alongside encrypted data

### Encryption in Transit
- TLS 1.3 preferred, TLS 1.2 minimum (disable 1.0, 1.1, SSLv3)
- mTLS for all internal service-to-service communication
- Certificate management: automated renewal (Let's Encrypt, ACME), short validity
- Perfect forward secrecy: ECDHE key exchange
