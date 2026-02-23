# HSM Integration and Cryptographic Key Management

## When to load
Load when implementing HSM-backed key generation, signing operations, envelope encryption, or
managing full key lifecycle including rotation, BYOK, and key ceremonies.

## HSM Integration

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

## Cryptographic Key Lifecycle

```
Generation -> Distribution -> Storage -> Usage -> Rotation -> Revocation -> Destruction
```
Document each stage with policies, procedures, and audit evidence. Automate rotation with
zero-downtime key rollover. Maintain key inventory: key ID, purpose, algorithm, creation date,
expiry, custodian.

## BYOK (Bring Your Own Key)

- Customer-managed keys for multi-tenant SaaS platforms
- Key wrapping: customer's key encrypts a platform key, which encrypts data
- Key escrow considerations: who can recover data if customer loses their key?
- Regulatory requirement in some jurisdictions (e.g., EU data sovereignty)

## Key Rotation

- Symmetric keys: rotate every 90 days (or per regulatory requirement)
- Asymmetric signing keys: rotate annually, revoke via CRL/OCSP
- Data re-encryption: schedule batch re-encryption after key rotation
- Dual-key period: decrypt with old key, encrypt with new key during transition

## Key Ceremony

- Multi-person control: minimum 3 of 5 custodians required (quorum)
- Air-gapped environment: offline key generation workstation
- Witnessed and recorded: video recording, signed ceremony log
- Key share distribution: each custodian receives encrypted key share
- Recovery testing: verify key reconstruction from shares annually
