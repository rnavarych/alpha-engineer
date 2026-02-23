# Network Security & Secure Storage

## When to load
Load when implementing certificate pinning, configuring App Transport Security, or storing secrets and tokens securely using platform keystores.

## Certificate Pinning

### Why Pin
- Prevents MITM attacks even on compromised networks with rogue CA certificates
- Required for fintech, healthcare, and any app handling sensitive data

### iOS Implementation
- Use `URLSession` delegate method `urlSession(_:didReceive:completionHandler:)` to validate server certificates
- Pin public key hashes (SPKI) rather than full certificates — survives certificate rotation
- Configure in `Info.plist` with `NSPinnedDomains` (iOS 14+) for declarative pinning
- Use TrustKit library for easier management and reporting

### Android Implementation
- Declarative pinning in `res/xml/network_security_config.xml`
- Pin SHA-256 of SubjectPublicKeyInfo: `<pin digest="SHA-256">base64hash=</pin>`
- Include backup pins for certificate rotation
- Use `CertificatePinner` (OkHttp) for programmatic pinning

### Cross-Platform
- React Native: configure native-side pinning or use `react-native-ssl-pinning`
- Flutter: use `SecurityContext` with trusted certificate or `http_certificate_pinning`
- Always include at least 2 pins (primary + backup) to avoid lockout on rotation

## Secure Storage

### iOS Keychain
- Store tokens, passwords, API keys, and encryption keys in Keychain Services
- Use `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` for sensitive items
- Set `kSecAttrAccessControl` with biometric requirement for high-security items
- Use Keychain Access Groups for sharing between app and extensions
- Never store secrets in `UserDefaults`, plist files, or plain files

### Android KeyStore
- Use Android KeyStore system for cryptographic key generation and storage
- Keys are hardware-backed on devices with Secure Element or TEE
- Use `EncryptedSharedPreferences` (Jetpack Security) for encrypted key-value storage
- Require user authentication: `setUserAuthenticationRequired(true)` on key generation
- Use `BiometricPrompt` to gate access to KeyStore-backed keys

### Cross-Platform
- React Native: `react-native-keychain` or `expo-secure-store`
- Flutter: `flutter_secure_storage` (wraps Keychain and EncryptedSharedPreferences)
- Never store secrets in AsyncStorage, SharedPreferences, or local files unencrypted

## App Transport Security (iOS)

- ATS enforces HTTPS by default — do not disable globally
- If exceptions are needed, use per-domain exceptions in `Info.plist`
- Require TLS 1.2+ with forward secrecy ciphers
- Apple reviews ATS exceptions during App Review — provide justification
- Use `nscurl --ats-diagnostics` to verify server ATS compliance
