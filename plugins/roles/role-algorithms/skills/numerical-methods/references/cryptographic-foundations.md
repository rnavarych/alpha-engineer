# Cryptographic Foundations

## When to load
When implementing or reviewing cryptographic primitives — hash functions, symmetric encryption, asymmetric key operations, or safe implementation patterns to avoid timing attacks and side channels.

## Hash Functions

- Properties: pre-image resistance, second pre-image resistance, collision resistance.
- Secure hashes: SHA-256, SHA-3, BLAKE2/BLAKE3 (fast, secure).
- Do NOT use MD5 or SHA-1 for security (collision attacks exist).
- HMAC: Keyed hash for message authentication. HMAC-SHA256 is standard.

## Symmetric Encryption

- AES-256-GCM: Authenticated encryption (confidentiality + integrity). Standard choice.
- ChaCha20-Poly1305: Alternative to AES-GCM. Faster in software without AES-NI.
- Always use authenticated encryption (GCM, CCM, Poly1305). Never use ECB mode.
- Key derivation: Use PBKDF2, bcrypt, scrypt, or Argon2 for password-based keys.

## Asymmetric Primitives

- RSA: Key exchange, digital signatures. Minimum 2048-bit keys. Prefer 4096 for long-term.
- ECDSA/EdDSA: Elliptic curve signatures. Smaller keys, faster operations than RSA.
- Diffie-Hellman / ECDH: Key exchange. Use X25519 curve for modern implementations.

## Implementation Safety

- **Never implement your own crypto**: Use vetted libraries (libsodium, OpenSSL, Web Crypto API).
- **Timing-safe comparisons**: Use constant-time comparison for secrets (prevent timing attacks).
- **Secure random generation**: Use OS CSPRNG (`/dev/urandom`, `crypto.getRandomValues`, `secrets` module).
- **Zeroize secrets**: Clear sensitive data from memory after use (prevent memory dumps).
- **Side-channel awareness**: Avoid data-dependent branches or memory access patterns with secret data.
