# Advanced Encryption: PQC, FHE, Enclaves, Tokenization, Field-Level

## When to load
Load when working with post-quantum cryptography migration, homomorphic encryption, secure enclaves/confidential computing, tokenization platforms, field-level encryption, or SOPS secret management.

## Post-Quantum Cryptography (PQC)

NIST finalized first PQC standards in 2024. Plan migration for long-lived keys and data now.

### Key Encapsulation Mechanisms (KEM)
- **CRYSTALS-Kyber (ML-KEM / FIPS 203)**: Lattice-based KEM. Primary recommendation. Security levels: Kyber-512 (L1), Kyber-768 (L3), Kyber-1024 (L5).
- **BIKE / HQC**: Code-based KEM alternatives.

### Digital Signatures
- **CRYSTALS-Dilithium (ML-DSA / FIPS 204)**: Lattice-based signatures. Primary recommendation. Levels: Dilithium2/3/5.
- **FALCON (FN-DSA / FIPS 206)**: Smaller signatures than Dilithium.
- **SPHINCS+ (SLH-DSA / FIPS 205)**: Hash-based, stateless, conservative assumptions.

### Hybrid Approach (Recommended for Transition)
- Combine classical + PQC: X25519 + Kyber768 for key exchange, ECDSA + Dilithium for signatures
- TLS 1.3 hybrid groups: X25519Kyber768Draft00 (Google/Cloudflare deployed)
- Libraries: liboqs (Open Quantum Safe), Bouncy Castle 1.78+, Go's `x/crypto/mlkem`

## Homomorphic Encryption (HE)
- **CKKS**: Approximate arithmetic on real/complex numbers — best for ML inference on encrypted data
- **BFV/BGV**: Exact integer arithmetic — suitable for database queries, statistics
- **TFHE**: Boolean circuit evaluation, fast gate bootstrapping (~1ms)
- Libraries: **Microsoft SEAL** (CKKS + BFV), **TFHE-rs** (Zama, Rust), **Concrete** (Python/Rust, ML-focused)

## Secure Enclaves and Confidential Computing

### Trusted Execution Environments (TEE)
- **Intel SGX**: Hardware-isolated memory enclaves, remote attestation. Used in Azure Confidential Computing.
- **AMD SEV-SNP**: Encrypts entire VM memory with integrity protection and attestation.
- **ARM TrustZone**: Secure World / Normal World split. Used in mobile (biometric keys) and IoT.
- **Apple Secure Enclave**: Dedicated chip on Apple Silicon. Stores Face ID / Touch ID keys — never leaves enclave.
- **AWS Nitro Enclaves**: Isolated EC2 compute, no persistent storage, cryptographic attestation, KMS integration.
- **GCP Confidential VMs**: AMD SEV-based, Confidential GKE Nodes.

## Format-Preserving Encryption (FPE)
- **FF1 (NIST SP 800-38G)**: NIST-standardized FPE for credit card numbers, SSNs, phone numbers.
- **FF3-1**: Revised standard; use FF1 for new implementations.
- Libraries: Botan, Bouncy Castle, `mysto/fpe` (Go), `ff3` (Python)

## Tokenization Platforms
- **Basis Theory**: API-first, PCI DSS Level 1, HIPAA, multiple token formats, reactors
- **VGS (Very Good Security)**: Proxy-based, PCI-compliant vault, PAN storage and forwarding
- **Skyflow**: Data privacy vault, purpose-bound governance, differential privacy, fine-grained access
- **Evervault**: Simple API, Relay (HTTP proxy), Cages (Nitro Enclaves), PCI-focused

## Field-Level Encryption (FLE)
```javascript
// MongoDB Client-Side FLE 2
const encryptedFieldsMap = {
  "users.ssn": { encrypt: { bsonType: "string",
    algorithm: "AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic" } },  // allows equality queries
  "users.salary": { encrypt: { bsonType: "double",
    algorithm: "AEAD_AES_256_CBC_HMAC_SHA_512-Random" } }  // no equality queries, more secure
};
```
- **Prisma**: `@encrypted` field attribute with `prisma-field-encryption` extension
- **PostgreSQL**: `pgcrypto` extension; **SQL Server**: Always Encrypted (client-side)

## SOPS (Secrets Operations)
```yaml
# .sops.yaml — encrypts values, preserves YAML structure
creation_rules:
  - path_regex: environments/prod/.*\.yaml$
    kms: arn:aws:kms:us-east-1:123456:key/abc-def
    age: age1ql3z7...
# Result: database_password: ENC[AES256_GCM,data:tIZsd...,type:str]
```
Key management backends: AWS KMS, GCP KMS, Azure Key Vault, HashiCorp Vault, age keys.
Use in CI/CD: `sops -d secrets.yaml | kubectl apply -f -`

## Data Classification and Encryption Matrix

| Classification | In Transit | At Rest | Field Level | Key Management |
|---------------|------------|---------|-------------|----------------|
| Public | TLS optional | None required | No | N/A |
| Internal | TLS 1.2+ | AES-256 recommended | No | Cloud KMS |
| Confidential | TLS 1.3 | AES-256-GCM required | No | Cloud KMS + rotation |
| Restricted | TLS 1.3 + mTLS | AES-256-GCM required | Yes | HSM + envelope |
| Regulated (PII/PHI/PAN) | TLS 1.3 + mTLS | AES-256-GCM + FPE/tokenization | Yes | HSM + BYOK |
