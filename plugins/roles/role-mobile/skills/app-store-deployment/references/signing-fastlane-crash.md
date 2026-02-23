# Code Signing, Fastlane & Crash Reporting

## When to load
Load when setting up code signing certificates, automating release pipelines with Fastlane, or integrating crash reporting tools (Crashlytics, Sentry) into the release process.

## Code Signing

### iOS
- Development certificate: local testing on physical devices
- Distribution certificate: App Store and Ad Hoc distribution
- Use automatic signing in Xcode when possible
- For CI/CD: export certificates as `.p12`, store securely in CI secrets
- Apple Developer account supports up to 3 distribution certificates

### Android
- Generate upload keystore: `keytool -genkey -v -keystore upload.jks -keyalg RSA`
- Enroll in Google Play App Signing (recommended): Google manages the app signing key
- Upload key is used by developer; signing key is managed by Google
- Store keystore file and passwords securely — losing them means losing the app
- Migrate to Play App Signing from self-managed signing if needed

## Provisioning Profiles (iOS)

- **Development**: links dev certificate + device UDIDs + app ID
- **Ad Hoc**: distribution to specific registered devices (up to 100)
- **App Store**: distribution via App Store (no device restrictions)
- **Enterprise**: in-house distribution (requires Enterprise Program membership)
- Profiles expire annually — automate renewal in CI/CD
- Use Xcode Managed Profiles for development; manual for CI/CD

## Fastlane Automation

### Core Tools
- `fastlane match`: code signing management with Git-encrypted certificates
- `fastlane gym` / `build_app`: build IPA with specified configuration
- `fastlane deliver`: upload metadata, screenshots, and binary to App Store Connect
- `fastlane supply`: upload APK/AAB and metadata to Google Play
- `fastlane pilot`: manage TestFlight uploads and tester groups
- `fastlane snapshot`: automated screenshot capture using UI tests

### Recommended Lanes
```ruby
lane :beta do
  increment_build_number
  match(type: "appstore")
  build_app(scheme: "MyApp")
  upload_to_testflight
end

lane :release do
  increment_build_number
  match(type: "appstore")
  build_app(scheme: "MyApp")
  deliver(submit_for_review: true)
end
```

### CI/CD Integration
- Store credentials in CI environment variables (MATCH_PASSWORD, APP_STORE_CONNECT_API_KEY)
- Use App Store Connect API key (`.p8`) for non-interactive authentication
- Cache derived data and pods/packages for faster builds

## Crash Reporting

### Firebase Crashlytics
- Automatic crash capture with symbolicated stack traces
- dSYM upload for iOS: via Fastlane plugin or build phase script
- Mapping file upload for Android: automatic with Gradle plugin
- Custom keys and logs for crash context: `Crashlytics.setCustomKey`
- Non-fatal error reporting: `Crashlytics.recordError` (iOS) / `recordException` (Android)

### Sentry
- Source map upload for React Native JavaScript crashes
- Dart symbolication for Flutter crash reports
- Breadcrumbs for event trail leading to crash
- Release health: crash-free sessions and users metrics
- Performance monitoring with distributed tracing
