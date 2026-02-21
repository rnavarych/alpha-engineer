---
name: app-store-deployment
description: |
  Expert guidance on mobile app deployment: App Store Connect and Google Play Console
  configuration, code signing and provisioning profiles, Fastlane automation,
  app review guidelines compliance, phased rollout strategies, and crash reporting
  integration (Crashlytics, Sentry). Use when preparing, submitting, or managing
  mobile app releases.
allowed-tools: Read, Grep, Glob, Bash
---

You are a mobile deployment specialist. Ensure smooth, reliable, and compliant app releases.

## App Store Connect (iOS)

### App Configuration
- Set bundle ID, SKU, and primary language during initial setup
- Configure App Privacy details (data collection, tracking, linked data)
- Set age rating via the questionnaire (violence, mature content, gambling)
- Add screenshots for all required device sizes: iPhone 6.7", 6.5", 5.5", iPad Pro

### TestFlight
- Internal testing: up to 100 testers, builds available immediately after processing
- External testing: up to 10,000 testers, requires Beta App Review
- Create test groups for organized feedback collection
- Set build expiration and auto-notify testers on new builds

### Submission
- Submit for review with release type: Manual, Automatic, or Scheduled
- In-App Purchases and Subscriptions must be submitted with binary
- Provide demo credentials for reviewer if app requires login
- Respond to rejections in Resolution Center with specific fixes

## Google Play Console (Android)

### App Configuration
- Set package name (cannot be changed after first upload)
- Complete Data Safety questionnaire (equivalent to App Privacy)
- Content rating questionnaire via IARC
- Set target audience and content declarations

### Testing Tracks
- Internal testing: up to 100 testers, immediate availability
- Closed testing: invite-based, limited rollout for beta feedback
- Open testing: publicly available beta with opt-in
- Promote builds between tracks: internal -> closed -> open -> production

### Release Management
- Use Android App Bundle (AAB) format — required for new apps
- Set managed publishing for controlled release timing
- Country/region availability configuration
- Pre-launch reports: automated testing on Firebase Test Lab devices

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

## Review Guidelines Compliance

### Common Rejection Reasons (iOS)
- **Guideline 2.1**: App completeness — crashes, placeholder content, broken links
- **Guideline 2.3**: Accurate metadata — screenshots must match current UI
- **Guideline 4.0**: Design — apps must follow HIG, no web-view-only apps
- **Guideline 5.1.1**: Data collection — privacy policy required, usage descriptions for permissions
- **Guideline 3.1.1**: In-app purchases — digital goods must use Apple IAP

### Common Rejection Reasons (Android)
- Missing privacy policy for apps accessing sensitive permissions
- Deceptive behavior or misleading functionality descriptions
- Improper use of background location or accessibility services
- Violation of Families Policy for apps targeting children

## Phased Rollout

### iOS
- Phased release over 7 days: 1%, 2%, 5%, 10%, 20%, 50%, 100%
- Pause phased release if critical issues emerge
- Users who manually check for updates can still get it immediately
- Cannot speed up the phased schedule — only pause or halt

### Android
- Staged rollout with custom percentages: start at 1%, increase manually
- Monitor crash rate, ANRs, and user reviews at each stage
- Halt and rollback if crash rate exceeds baseline
- Use Firebase Remote Config for feature flags alongside rollout

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
