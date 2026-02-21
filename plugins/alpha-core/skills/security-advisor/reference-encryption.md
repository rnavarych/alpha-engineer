# Encryption Reference

## Symmetric Encryption
- **AES-256-GCM**: Authenticated encryption (confidentiality + integrity). Preferred for data at rest.
- **ChaCha20-Poly1305**: Alternative to AES-GCM, better on systems without AES hardware acceleration.
- Never use: DES, 3DES, RC4, ECB mode

## Asymmetric Encryption
- **RSA-2048+**: Key exchange, digital signatures. Minimum 2048-bit keys.
- **ECDSA (P-256, P-384)**: Smaller keys, equivalent security. Preferred for TLS.
- **Ed25519**: Modern signature algorithm. Fast, secure, compact.

## Password Hashing
- **Argon2id**: Winner of Password Hashing Competition. Recommended. Memory-hard.
- **bcrypt**: Well-tested, widely supported. Cost factor 12+.
- **scrypt**: Memory-hard alternative. Good for hardware resistance.
- Never use: MD5, SHA1, SHA256 (without key stretching), plain text

## Key Management
- Use cloud KMS (AWS KMS, Google Cloud KMS, Azure Key Vault)
- Envelope encryption: data key encrypts data, master key encrypts data key
- Key rotation: automate, support multiple active versions during transition
- Separate encryption keys from encrypted data
- Audit key access with logging

## TLS Configuration
- Minimum TLS 1.2, prefer TLS 1.3
- Strong cipher suites: ECDHE + AES-GCM or ChaCha20
- HSTS header with long max-age and includeSubDomains
- Certificate transparency monitoring
- Automated certificate renewal (Let's Encrypt, ACME)

## Data Classification
- **Public**: No encryption required
- **Internal**: Encryption in transit (TLS)
- **Confidential**: Encryption in transit + at rest
- **Restricted**: Encryption in transit + at rest + field-level encryption + access audit logging
