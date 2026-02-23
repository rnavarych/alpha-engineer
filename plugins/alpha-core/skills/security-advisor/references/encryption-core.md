# Encryption Core: Algorithms, Key Management, and TLS

## When to load
Load when selecting encryption algorithms, implementing password hashing, configuring TLS, managing keys with KMS or Vault, or implementing envelope encryption.

## Symmetric Encryption
- **AES-256-GCM**: Authenticated encryption (confidentiality + integrity + authenticity). Preferred for data at rest. 96-bit random nonce, never reuse nonce with same key.
- **ChaCha20-Poly1305**: IETF standard alternative to AES-GCM. Better on systems without AES-NI hardware acceleration (mobile, ARM, embedded). Used in TLS 1.3 and WireGuard.
- **XChaCha20-Poly1305**: Extended nonce (192-bit) — safe for random nonce generation at scale.
- Never use: DES, 3DES, RC4, Blowfish, ECB mode (exposes patterns), CBC without MAC

## Asymmetric Encryption
- **RSA-2048+ (OAEP padding)**: Key exchange and signatures. Prefer 4096-bit for long-term keys. Never PKCS#1 v1.5.
- **Ed25519**: Modern EdDSA over Curve25519. Fast, deterministic, constant-time. Preferred for new systems. Used in SSH, TLS 1.3, Sigstore.
- **X25519 / X448**: ECDH key agreement using Curve25519/Curve448 for ephemeral key exchange.
- **ECDSA (P-256 / P-384)**: Smaller keys, equivalent security. P-384 for NSA Suite B / high-assurance.

## Password Hashing
- **Argon2id**: Winner of Password Hashing Competition. Memory-hard + CPU-hard. Parameters: m=65536 (64MB), t=3, p=4.
- **bcrypt**: Well-tested, widely supported. Cost factor 12+. 72-byte input limit — pre-hash with SHA-512 for longer passwords.
- **scrypt**: Memory-hard alternative. N=32768, r=8, p=1 minimum.
- **PBKDF2-SHA-256**: FIPS 140 compliant. 600,000+ iterations minimum (2023 NIST recommendation).
- Never use: MD5, SHA1, SHA256 (without key stretching), unsalted hashes

## Key Management

### Cloud KMS
- **AWS KMS**: CMKs, key policies, grants, CloudTrail audit, automatic rotation, multi-region keys, XKS (HYOK)
- **GCP Cloud KMS**: Key rings, key versions, HSM keys, External Key Manager, automatic rotation
- **Azure Key Vault / HSM**: Keys, secrets, certificates, managed HSM for FIPS 140-3 Level 3, BYOK
- **HashiCorp Vault**: On-prem or cloud, Transit engine, seal/unseal with Shamir's Secret Sharing or auto-unseal

### Envelope Encryption Pattern
```
Plaintext data
  → encrypted with Data Encryption Key (DEK, ephemeral AES-256)
  → DEK encrypted with Key Encryption Key (KEK) stored in KMS
  → store: { encrypted_data, encrypted_dek, kms_key_id }
To decrypt:
  → call KMS to decrypt encrypted_dek using KEK
  → use DEK to decrypt data (DEK only in memory during operation)
```

### Key Rotation
- Automate rotation; support multiple active key versions during transition
- Re-encrypt data with new key version in background batch job
- Separate encryption keys from encrypted data — different storage, different access controls

## TLS Configuration
- Minimum TLS 1.2; prefer TLS 1.3 exclusively
- HSTS header: `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload`
- Submit to HSTS preload list: hstspreload.org
- Certificate Transparency monitoring: crt.sh, Google CT Policy
- Automated certificate renewal: Let's Encrypt (ACME), AWS ACM auto-renewal
- OCSP stapling: server includes signed OCSP response in TLS handshake

## HashiCorp Vault Transit Engine
```bash
vault secrets enable transit
vault write -f transit/keys/payments type=aes256-gcm96
vault write transit/encrypt/payments plaintext=$(base64 <<< "sensitive-data")
# Returns: vault:v1:8SDd3WHD...
vault write transit/decrypt/payments ciphertext=vault:v1:8SDd3WHD...
vault write -f transit/keys/payments/rotate  # key rotation
vault write transit/rewrap/payments ciphertext=vault:v1:...  # rewrap to latest version
```
Keys never leave Vault; audit log of all crypto operations.
