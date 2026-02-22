---
name: fintech-security
description: |
  Guides fintech security: HSM integration (key generation, signing, encryption),
  cryptographic key management (BYOK, rotation, key ceremony), PCI DSS for fintech,
  data encryption (field-level, tokenization), secure multi-party computation,
  zero-knowledge proofs, and SOC 2 Type II requirements.
  Use when implementing security controls for financial systems.
allowed-tools: Read, Grep, Glob, Bash
---

You are a fintech security specialist. Financial systems are high-value targets — security must be defense-in-depth with no single point of failure.

## HSM Integration (Hardware Security Modules)

### Key Generation
- Generate all cryptographic keys inside the HSM boundary — keys never exist in plaintext outside
- RSA 2048+ for signing and key wrapping, AES-256 for symmetric encryption
- Elliptic curve (P-256, P-384) for modern signing and key agreement
- Key generation ceremony: multi-custodian, dual-control, audited event

### Signing Operations
- Transaction signing: HSM signs payment instructions before submission
- Code signing: release artifacts signed with HSM-held keys
- Document signing: regulatory filings, contracts, audit reports
- Use PKCS#11 or vendor SDK (Thales Luna, AWS CloudHSM, Azure Dedicated HSM)

### Encryption with HSM
- Envelope encryption: HSM encrypts data encryption keys (DEKs), DEKs encrypt data
- Never send bulk data to HSM — only key material and small payloads
- HSM throughput planning: operations per second varies by key type and operation
- High-availability: HSM clustering with automatic failover

### Cloud HSM Options
- **AWS CloudHSM**: FIPS 140-2 Level 3, dedicated single-tenant
- **AWS KMS**: multi-tenant, lower cost, sufficient for most use cases
- **Azure Dedicated HSM**: Thales Luna, FIPS 140-2 Level 3
- **Azure Key Vault Managed HSM**: FIPS 140-2 Level 3, multi-tenant control plane
- **GCP Cloud HSM**: FIPS 140-2 Level 3, integrated with Cloud KMS

## Cryptographic Key Management

### Key Lifecycle
```
Generation -> Distribution -> Storage -> Usage -> Rotation -> Revocation -> Destruction
```
- Document each stage with policies, procedures, and audit evidence
- Automate rotation with zero-downtime key rollover
- Maintain key inventory: key ID, purpose, algorithm, creation date, expiry, custodian

### BYOK (Bring Your Own Key)
- Customer-managed keys for multi-tenant SaaS platforms
- Key wrapping: customer's key encrypts a platform key, which encrypts data
- Key escrow considerations: who can recover data if customer loses their key?
- Regulatory requirement in some jurisdictions (e.g., EU data sovereignty)

### Key Rotation
- Symmetric keys: rotate every 90 days (or per regulatory requirement)
- Asymmetric signing keys: rotate annually, revoke via CRL/OCSP
- Data re-encryption: schedule batch re-encryption after key rotation
- Dual-key period: decrypt with old key, encrypt with new key during transition

### Key Ceremony
- Multi-person control: minimum 3 of 5 custodians required (quorum)
- Air-gapped environment: offline key generation workstation
- Witnessed and recorded: video recording, signed ceremony log
- Key share distribution: each custodian receives encrypted key share
- Recovery testing: verify key reconstruction from shares annually

## PCI DSS for Fintech

### Beyond E-Commerce PCI
- **Scope reduction**: tokenize card data at the earliest point
- Network segmentation: isolate cardholder data environment (CDE)
- If you store card data (rare): PCI DSS Level 1 with annual QSA audit
- If you use tokens only: SAQ A or SAQ A-EP (reduced scope)

### Key PCI Requirements for Fintech
- Requirement 3: protect stored cardholder data (tokenization, encryption, masking)
- Requirement 4: encrypt transmission (TLS 1.2+, no fallback to older versions)
- Requirement 6: secure development (SAST, DAST, dependency scanning, code review)
- Requirement 7: restrict access (need-to-know, role-based, least privilege)
- Requirement 8: authentication (MFA for all access to CDE, unique IDs)
- Requirement 10: logging and monitoring (all access to cardholder data logged)
- Requirement 11: regular testing (quarterly ASV scans, annual pen test)

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

## Secure Multi-Party Computation (SMPC)

### Use Cases in Fintech
- **Fraud consortium**: banks share fraud signals without revealing customer data
- **Credit scoring**: compute credit score from multiple data sources without sharing raw data
- **AML network analysis**: identify suspicious patterns across institutions without data pooling
- **Benchmark calculations**: compute industry averages without revealing individual positions

### Implementation Approaches
- Secret sharing (Shamir's): split data into shares, compute on shares
- Garbled circuits: encode computation as encrypted circuit
- Homomorphic encryption: compute on encrypted data directly
- Trusted execution environments (TEE): Intel SGX, ARM TrustZone
- Trade-off: security guarantees vs computational overhead

## Zero-Knowledge Proofs (ZKP)

### Identity Verification
- Prove age >= 18 without revealing exact date of birth
- Prove income >= threshold without revealing exact income
- Prove account balance >= payment amount without revealing balance
- Prove KYC completion without sharing KYC documents

### ZKP Protocols for Fintech
- **zk-SNARKs**: succinct proofs, fast verification, requires trusted setup
- **zk-STARKs**: no trusted setup, larger proofs, post-quantum secure
- **Bulletproofs**: no trusted setup, efficient range proofs (balance >= 0)
- Consider practical deployment: proof generation time, verification cost, circuit complexity

## SOC 2 Type II Requirements

### Trust Service Criteria
- **Security** (mandatory): logical/physical access controls, encryption, vulnerability management
- **Availability**: uptime SLA, disaster recovery, incident response, capacity planning
- **Processing Integrity**: data processing accuracy, error handling, reconciliation
- **Confidentiality**: data classification, encryption, access controls, retention
- **Privacy**: PII handling, consent, disclosure, data subject rights

### SOC 2 for Fintech Specifics
- Continuous monitoring: replace point-in-time checks with automated evidence collection
- Audit period: Type II covers minimum 6 months of operating effectiveness
- Evidence automation: pull access logs, change records, test results automatically
- Policy management: version-controlled policies with annual review cadence
- Third-party management: assess sub-service organizations (cloud providers, BaaS partners)
- Penetration testing: annual external pen test, quarterly internal vulnerability scans
