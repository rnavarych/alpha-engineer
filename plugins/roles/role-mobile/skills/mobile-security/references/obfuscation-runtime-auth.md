# Obfuscation, Runtime Integrity & Authentication

## When to load
Load when implementing code obfuscation, root/jailbreak detection, biometric authentication, or securing inter-process communication channels.

## Code Obfuscation

### Android (ProGuard / R8)
- Enable R8 in release builds: `isMinifyEnabled = true` in `build.gradle.kts`
- Write ProGuard rules to keep entry points, serialization models, and reflection targets
- Use `-obfuscationdictionary` for custom naming
- Enable resource shrinking: `isShrinkResources = true`
- Verify obfuscation with `mapping.txt` and retrace tool for crash reports

### iOS
- Swift compilation provides baseline symbol obfuscation
- Use bitcode (pre-Xcode 14) or post-build obfuscation tools for additional protection
- Strip debug symbols in release: `STRIP_SWIFT_SYMBOLS = YES`
- Remove `DWARF with dSYM File` only after uploading symbols to crash reporter

### React Native / Flutter
- Hermes bytecode provides moderate JavaScript obfuscation
- Dart AOT compilation provides moderate obfuscation for Flutter
- Do not embed API keys or secrets in JavaScript/Dart bundles — use runtime config

## Root / Jailbreak Detection

### Detection Strategies
- Check for known root/jailbreak files: `/Applications/Cydia.app`, `su` binary, Magisk paths
- Verify file system integrity: attempt to write outside sandbox
- Check for hooking frameworks (Frida, Xposed, Substrate) via library inspection
- Validate code signing integrity at runtime

### Implementation
- iOS: check for Cydia, `fork()` behavior, sandbox integrity, dylib injection
- Android: SafetyNet/Play Integrity API for server-verified device attestation
- Use multi-layered detection — no single check is sufficient
- Respond gracefully: warn user, restrict features, or block access based on risk profile
- Detection can be bypassed by sophisticated attackers — never rely solely on client-side checks

## Biometric Authentication

### iOS (Face ID / Touch ID)
- Use `LAContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)`
- Check `canEvaluatePolicy` before prompting
- Set `localizedReason` string explaining why biometrics are needed
- Fall back to device passcode with `.deviceOwnerAuthentication` policy
- Combine with Keychain: `kSecAccessControlBiometryCurrentSet`

### Android (BiometricPrompt)
- Use `BiometricPrompt` API with `CryptoObject` for cryptographic operations
- Define `BiometricPrompt.PromptInfo` with allowed authenticators
- `BIOMETRIC_STRONG` for Class 3 biometrics (fingerprint, face with hardware)
- Fall back to device credential: `setAllowedAuthenticators(BIOMETRIC_STRONG or DEVICE_CREDENTIAL)`

## Secure IPC

- iOS: validate URL scheme callbacks, use Universal Links over custom URL schemes
- Android: use explicit intents over implicit; set `exported=false` on internal components
- Validate all incoming intent data — treat as untrusted input
- Use `ContentProvider` with signature-level permissions for inter-app data sharing
- Encrypt data passed through IPC channels for sensitive information
