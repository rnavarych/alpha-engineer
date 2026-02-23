# Store Configuration & Submission

## When to load
Load when setting up App Store Connect or Google Play Console for the first time, configuring app metadata, managing TestFlight/test tracks, or preparing a submission for review.

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
