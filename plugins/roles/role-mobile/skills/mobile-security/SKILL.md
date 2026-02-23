---
name: mobile-security
description: Expert guidance on mobile application security — certificate pinning, secure storage (Keychain on iOS, KeyStore on Android), code obfuscation (ProGuard, R8), root/jailbreak detection, biometric authentication, secure inter-process communication, and App Transport Security. Use when hardening mobile apps or implementing security features.
allowed-tools: Read, Grep, Glob, Bash
---

# Mobile Security

## When to use
- Implementing certificate pinning to prevent MITM attacks
- Storing tokens, keys, or credentials securely on-device
- Enabling R8/ProGuard obfuscation and verifying the mapping file
- Adding root/jailbreak detection with layered strategies
- Integrating biometric authentication (Face ID, Touch ID, BiometricPrompt)
- Hardening IPC: intent validation, Universal Links, ContentProvider permissions
- Auditing App Transport Security exceptions before App Store submission

## Core principles
1. **Device is hostile by default** — assume the attacker has physical access and a debugger
2. **Two pins, always** — a single certificate pin that expires locks out every user in production
3. **Keychain/KeyStore, not files** — hardware-backed key storage exists; use it
4. **Multi-layer detection** — one jailbreak check is bypassable in 30 seconds; five is a weekend project
5. **Never trust client-side alone** — client detection is delay, not prevention; validate on the server too

## Reference Files

- `references/network-storage-security.md` — certificate pinning rationale, iOS URLSession/NSPinnedDomains/TrustKit implementation, Android network_security_config.xml and OkHttp CertificatePinner, cross-platform pinning libraries, iOS Keychain Services access controls, Android KeyStore hardware-backed keys and EncryptedSharedPreferences, cross-platform secure storage libraries, App Transport Security configuration
- `references/obfuscation-runtime-auth.md` — Android R8/ProGuard configuration and resource shrinking, iOS symbol stripping, React Native/Flutter obfuscation caveats, root/jailbreak detection strategies and evasion limits, iOS LAContext biometrics, Android BiometricPrompt with CryptoObject, secure IPC patterns (explicit intents, Universal Links, ContentProvider permissions)
