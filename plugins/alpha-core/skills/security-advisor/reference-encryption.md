# Encryption Reference

## Symmetric Encryption

- **AES-256-GCM**: Authenticated encryption (confidentiality + integrity + authenticity). Preferred for data at rest. 96-bit random nonce, never reuse nonce with same key.
- **AES-256-CBC**: Requires separate HMAC for integrity (Encrypt-then-MAC). Avoid if GCM is available.
- **ChaCha20-Poly1305**: IETF standard alternative to AES-GCM. Better on systems without AES-NI hardware acceleration (mobile, ARM, embedded). Used in TLS 1.3 and WireGuard.
- **XChaCha20-Poly1305**: Extended nonce (192-bit) variant — safe for random nonce generation at scale without nonce collision risk.
- Never use: DES, 3DES, RC4, Blowfish, ECB mode (exposes patterns), CBC without MAC

## Asymmetric Encryption

- **RSA-2048+ (OAEP padding)**: Key exchange, digital signatures. Minimum 2048-bit; prefer 4096-bit for long-term keys. Use OAEP padding, never PKCS#1 v1.5 (vulnerable to padding oracle).
- **ECDSA (P-256 / secp256k1 / P-384)**: Smaller keys, equivalent security. P-256 for general use, P-384 for NSA Suite B / high-assurance. secp256k1 for blockchain compatibility.
- **Ed25519**: Modern EdDSA over Curve25519. Fast, deterministic, constant-time, compact 64-byte signatures. Preferred for new systems. Used in SSH, TLS 1.3, Sigstore.
- **Ed448**: Higher-security EdDSA. 57-byte keys, 114-byte signatures. For long-term, high-security contexts.
- **X25519 / X448**: ECDH key agreement using Curve25519/Curve448. Use for ephemeral key exchange in TLS, Signal Protocol, Noise Protocol.

## Password Hashing

- **Argon2id**: Winner of Password Hashing Competition. Memory-hard + CPU-hard. Recommended for new systems. Parameters: m=65536 (64MB), t=3 (iterations), p=4 (parallelism).
- **bcrypt**: Well-tested, widely supported. Cost factor 12+ (higher on powerful hardware). 72-byte input limit — pre-hash with SHA-512 for longer passwords.
- **scrypt**: Memory-hard alternative. N=32768, r=8, p=1 minimum. Good hardware-resistance. Used in Litecoin, many wallets.
- **PBKDF2-SHA-256**: FIPS 140 compliant, NIST approved. Use when FIPS compliance required. 600,000+ iterations minimum (2023 NIST recommendation).
- Never use: MD5, SHA1, SHA256 (without key stretching), unsalted hashes, plain text storage

## Post-Quantum Cryptography (PQC)

NIST finalized first PQC standards in 2024. Plan migration for long-lived keys and data now.

### Key Encapsulation Mechanisms (KEM)
- **CRYSTALS-Kyber (ML-KEM / FIPS 203)**: Lattice-based KEM. Primary recommendation for key exchange and encryption. Security levels: Kyber-512 (L1), Kyber-768 (L3), Kyber-1024 (L5).
- **BIKE**: Code-based KEM. Smaller keys. NIST Round 4 candidate.
- **HQC**: Code-based KEM. Alternative to Kyber.

### Digital Signatures
- **CRYSTALS-Dilithium (ML-DSA / FIPS 204)**: Lattice-based signatures. Primary recommendation. Levels: Dilithium2/3/5.
- **FALCON (FN-DSA / FIPS 206)**: Lattice-based NTRU signatures. Smaller signatures than Dilithium.
- **SPHINCS+ (SLH-DSA / FIPS 205)**: Hash-based signatures. Stateless. More conservative (no lattice math). Larger signatures but minimal assumptions.

### Hybrid Approach (Recommended for Transition)
- Combine classical + PQC: X25519 + Kyber768 for key exchange, ECDSA + Dilithium for signatures
- TLS 1.3 hybrid groups: X25519Kyber768Draft00 (Google/Cloudflare deployed)
- Libraries: liboqs (Open Quantum Safe), PQClean, Bouncy Castle 1.78+, Go's `x/crypto/mlkem`

## Homomorphic Encryption (HE)

Enables computation on encrypted data without decryption. Still computationally expensive for general use.

### Schemes
- **Partial HE (PHE)**: Supports one operation (add OR multiply) — fast. RSA (mult), Paillier (add), ElGamal (mult).
- **Somewhat HE (SHE)**: Limited operations before noise accumulates.
- **Fully HE (FHE)**: Arbitrary computation. Expensive but improving rapidly.
  - **CKKS** (Cheon-Kim-Kim-Song): Approximate arithmetic on real/complex numbers. Best for ML inference on encrypted data.
  - **BFV/BGV**: Exact integer arithmetic. Suitable for database queries, statistics.
  - **TFHE** (Fast Fully HE): Boolean circuit evaluation. Fast gate bootstrapping (~1ms).

### Libraries
- **Microsoft SEAL**: C++ library, CKKS + BFV, widely used in research and production
- **HElib** (IBM): BGV scheme, C++, focuses on batching efficiency
- **TFHE-rs** (Zama): Rust implementation of TFHE, used for confidential smart contracts
- **OpenFHE**: Successor to PALISADE, multiple schemes, C++
- **Concrete** (Zama): Python/Rust, compiles Python to FHE circuits, ML-focused

### Use Cases
- Privacy-preserving ML inference: run model on encrypted user data
- Encrypted database queries: search without decrypting records
- Genome analysis without exposing patient data

## Secure Enclaves and Confidential Computing

### Trusted Execution Environments (TEE)
- **Intel SGX (Software Guard Extensions)**: Hardware-isolated memory enclaves. Remote attestation. Used in Azure Confidential Computing, Fortanix.
  - Limitations: Side-channel attacks (Spectre variants), complex programming model, limited memory (EPC).
  - Attestation: DCAP (Data Center Attestation Primitives) for cloud deployments.
- **AMD SEV (Secure Encrypted Virtualization)**: Encrypts entire VM memory. SEV-SNP adds integrity protection and stronger attestation. Used in Azure/GCP confidential VMs.
- **ARM TrustZone**: Splits processor into Secure World / Normal World. Used in mobile (TEE for biometric keys), IoT (secure boot, attestation).
- **Apple Secure Enclave**: Dedicated security chip on Apple Silicon and T-chip devices. Stores keys for Face ID, Touch ID, Apple Pay. Keys never leave enclave.
- **AWS Nitro Enclaves**: Isolated EC2 compute environments with no persistent storage, no interactive access, cryptographic attestation. KMS integration for key delivery to attested enclave.
- **GCP Confidential VMs**: AMD SEV-based, Confidential GKE Nodes, Confidential Dataflow.

### Attestation
- Remote attestation: TEE generates cryptographic proof of code + environment state
- Attestation report signed by hardware vendor root; verifier checks against expected measurements (PCR values / measurements)
- AWS Nitro: attestation document from EC2 Nitro hypervisor, signed by AWS root CA
- RATS (Remote ATtestation procedureS) — IETF standard for attestation protocols

## Format-Preserving Encryption (FPE)

Encrypts data while preserving the format/length of the plaintext. Essential for tokenizing data in legacy systems.

- **FF1 (NIST SP 800-38G)**: NIST-standardized FPE based on Feistel network. Input: string over alphabet. Used for credit card numbers, SSNs, phone numbers.
- **FF3-1 (NIST SP 800-38G Rev 1)**: Revised after tweakable block cipher attacks. Narrower tweak range. Use FF1 for new implementations.
- **AES-FFX**: Earlier academic standard, precursor to NIST standards.
- Libraries: Botan, Bouncy Castle, mysto/fpe (Go), ff3 (Python)
- Use cases: Encrypt SSNs in database while keeping format, tokenize credit card numbers for test environments

## Tokenization Platforms

Replace sensitive values with non-sensitive tokens. Token is format-preserving but cryptographically irreversible without the vault.

- **Basis Theory**: API-first tokenization, PCI DSS Level 1, HIPAA, multiple token formats, proxies, reactors (serverless functions on token data)
- **VGS (Very Good Security)**: Proxy-based tokenization, intercepts HTTP traffic, PCI-compliant vault, PAN storage and forwarding
- **Skyflow**: Data privacy vault, purpose-bound governance, differential privacy, fine-grained access, SOC 2 / HIPAA / PCI
- **Protegrity**: Enterprise data-centric security, tokenization + FPE, policy engine, integrates with databases and big data platforms
- **Evervault**: Simple API, Relay (HTTP proxy), Cages (Nitro Enclaves), PCI-focused
- Comparison: Basis Theory for developer-friendly APIs; VGS for payment proxy; Skyflow for data privacy as platform; Protegrity for enterprise/legacy

## Field-Level Encryption (FLE)

Encrypt specific fields in documents/records, leaving non-sensitive fields in plaintext for querying.

### MongoDB FLE (Client-Side FLE 2)
```javascript
// Schema-level encryption configuration
const encryptedFieldsMap = {
  "users.ssn": { encrypt: { bsonType: "string", algorithm: "AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic" } },
  "users.salary": { encrypt: { bsonType: "double", algorithm: "AEAD_AES_256_CBC_HMAC_SHA_512-Random" } }
};
// Deterministic: same plaintext → same ciphertext (allows equality queries)
// Random: different ciphertext each time (more secure, no equality queries)
```

### Prisma Field Encryption
- `@encrypted` Prisma field attribute with prisma-field-encryption extension
- Transparent encryption/decryption via Prisma middleware
- Key rotation with encrypted key in KMS

### Database-Level Column Encryption
- PostgreSQL: `pgcrypto` extension, `encrypt()` / `decrypt()` functions
- MySQL: `AES_ENCRYPT()` / `AES_DECRYPT()` built-in functions
- SQL Server: Always Encrypted — client-side, keys never reach SQL Server
- Oracle: Transparent Data Encryption (TDE) for tablespace-level encryption

## Client-Side Encryption (CSE)

Encrypt data in the client before sending to server. Server stores only ciphertext.

- **libsodium (Sodium)**: High-level, safe defaults, available in all major languages. Use `crypto_secretbox_easy` (symmetric), `crypto_box_easy` (asymmetric), `crypto_pwhash` (password hashing).
- **age** (Actually Good Encryption): Simple, modern file encryption. Recipients: age public keys, SSH keys, passphrase. Format: clear headers, encrypted payload. Replace GPG for file encryption.
  ```bash
  # Encrypt
  age -r age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p file.txt > file.txt.age
  # Decrypt
  age -d -i private-key.txt file.txt.age > file.txt
  ```
- **Browser WebCrypto API**: Native browser encryption without external libraries.
  ```javascript
  const key = await crypto.subtle.generateKey({ name: "AES-GCM", length: 256 }, true, ["encrypt", "decrypt"]);
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const ciphertext = await crypto.subtle.encrypt({ name: "AES-GCM", iv }, key, plaintext);
  ```

## SOPS (Secrets Operations)

Encrypt secrets files (YAML, JSON, ENV, INI) keeping structure visible, encrypting only values.

```yaml
# .sops.yaml configuration
creation_rules:
  - path_regex: environments/prod/.*\.yaml$
    kms: arn:aws:kms:us-east-1:123456:key/abc-def
    gcp_kms: projects/myproject/locations/global/keyRings/sops/cryptoKeys/sops-key
    age: age1ql3z7...
  - path_regex: environments/dev/.*\.yaml$
    age: age1ql3z7...

# Encrypted file preserves YAML structure:
database_password: ENC[AES256_GCM,data:tIZsd...,iv:...,tag:...,type:str]
```

Key management backends: AWS KMS, GCP KMS, Azure Key Vault, HashiCorp Vault, age keys, PGP.
Use in CI/CD: `sops -d secrets.yaml | kubectl apply -f -`

## HashiCorp Vault Transit Engine

Server-side encryption as a service. Keys stored in Vault, data encrypted/decrypted via API.

```bash
# Enable transit engine
vault secrets enable transit

# Create named key (never exported)
vault write -f transit/keys/payments type=aes256-gcm96

# Encrypt
vault write transit/encrypt/payments plaintext=$(base64 <<< "4111111111111111")
# Returns: vault:v1:8SDd3WHDOjf7mq69CyCqYjBXAiQQAVZRkFM13ok484zL...

# Decrypt
vault write transit/decrypt/payments ciphertext=vault:v1:8SDd3WHD...
# Returns base64-decoded plaintext

# Key rotation (old versions still decrypt, new encrypts with v2)
vault write -f transit/keys/payments/rotate

# Rewrap ciphertexts to latest key version
vault write transit/rewrap/payments ciphertext=vault:v1:...
```

Benefits: Keys never leave Vault, audit log of all crypto operations, automatic key rotation, convergent encryption option for searchable ciphertext.

## Key Management

### Cloud KMS
- **AWS KMS**: CMKs (Customer Managed Keys), key policies, grants, CloudTrail audit, automatic rotation, multi-region keys, XKS (external key store for HYOK)
- **GCP Cloud KMS**: Key rings, key versions, HSM keys, External Key Manager, automatic rotation, CMEK for GCP services
- **Azure Key Vault / HSM**: Keys, secrets, certificates, managed HSM for FIPS 140-3 Level 3, Bring Your Own Key (BYOK)
- **HashiCorp Vault**: On-prem or cloud, seal/unseal with Shamir's Secret Sharing or auto-unseal (KMS), namespaces, audit devices

### Envelope Encryption Pattern
```
Plaintext data
  → encrypted with Data Encryption Key (DEK, ephemeral AES-256)
  → DEK encrypted with Key Encryption Key (KEK) stored in KMS
  → store: { encrypted_data, encrypted_dek, kms_key_id }
To decrypt:
  → call KMS to decrypt encrypted_dek using KEK
  → use DEK to decrypt data
  → DEK only in memory during operation
```

### Key Rotation
- Automate rotation (AWS KMS: annual automatic rotation for symmetric keys)
- Support multiple active key versions during transition period
- Re-encrypt data with new key version in background batch job
- Separate encryption keys from encrypted data — different storage, different access controls
- Audit all key access: who, when, what operation, from where

## TLS Configuration

- Minimum TLS 1.2 (many standards now require 1.3 or 1.2+); prefer TLS 1.3 exclusively
- TLS 1.3 cipher suites (not configurable): TLS_AES_128_GCM_SHA256, TLS_AES_256_GCM_SHA384, TLS_CHACHA20_POLY1305_SHA256
- TLS 1.2 strong cipher suites: ECDHE-ECDSA-AES256-GCM-SHA384, ECDHE-RSA-AES256-GCM-SHA384
- HSTS header: `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload`
- Submit to HSTS preload list: hstspreload.org
- Certificate Transparency (CT) monitoring: crt.sh, Facebook CT Monitor, Google CT Policy
- Automated certificate renewal: Let's Encrypt (ACME), ZeroSSL, AWS ACM auto-renewal
- OCSP stapling: server includes signed OCSP response in TLS handshake (reduces latency, privacy)
- Certificate pinning for mobile: pin SubjectPublicKeyInfo hash, not certificate hash; include backup pins; plan rotation

## Confidential Computing Stack

| Layer | Technology |
|-------|-----------|
| Hardware TEE | Intel SGX, AMD SEV-SNP, ARM TrustZone, Apple Secure Enclave |
| Cloud Services | AWS Nitro Enclaves, Azure Confidential VMs, GCP Confidential VMs |
| Orchestration | Kubernetes Confidential Containers (CoCo), Kata Containers |
| Attestation | Intel DCAP, AMD SEV-SNP attestation, AWS Nitro Attestation, IETF RATS |
| Key Release | Microsoft Azure SKR (Secure Key Release), Enarx, Gramine |
| Frameworks | Gramine (SGX LibOS), Enarx (multi-TEE), Occlum (SGX LibOS), Teaclave |

### Use Cases
- Process health data without exposing to cloud provider
- Multi-party computation: combine datasets from multiple parties without revealing inputs
- Secure model inference: run proprietary ML models on client data without exposing either
- Blockchain smart contract privacy (Oasis Network, Secret Network)

## Data Classification and Encryption Matrix

| Classification | In Transit | At Rest | Field Level | Key Management | Access Logging |
|---------------|------------|---------|-------------|----------------|----------------|
| Public | TLS optional | None required | No | N/A | No |
| Internal | TLS 1.2+ | AES-256 recommended | No | Cloud KMS | Optional |
| Confidential | TLS 1.3 | AES-256-GCM required | No | Cloud KMS + rotation | Yes |
| Restricted | TLS 1.3 + mTLS | AES-256-GCM required | Yes | HSM + envelope | Yes, all access |
| Regulated (PII/PHI/PAN) | TLS 1.3 + mTLS | AES-256-GCM + FPE/tokenization | Yes | HSM + BYOK | Yes, immutable |
