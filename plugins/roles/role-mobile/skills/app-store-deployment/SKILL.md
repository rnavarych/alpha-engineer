---
name: role-mobile:app-store-deployment
description: Expert guidance on mobile app deployment — App Store Connect and Google Play Console configuration, code signing and provisioning profiles, Fastlane automation, app review guidelines compliance, phased rollout strategies, and crash reporting integration (Crashlytics, Sentry). Use when preparing, submitting, or managing mobile app releases.
allowed-tools: Read, Grep, Glob, Bash
---

# App Store Deployment

## When to use
- Configuring App Store Connect or Google Play Console for a new app
- Setting up TestFlight or Play testing tracks for beta distribution
- Implementing Fastlane lanes for automated builds and submissions
- Debugging code signing, provisioning profiles, or keystore issues
- Preparing a submission and ensuring review guideline compliance
- Rolling out a release with phased/staged rollout controls
- Integrating Crashlytics or Sentry for symbolicated crash reporting

## Core principles
1. **Automate signing** — manual certificate juggling in CI is how you lose a signing key at 2 AM
2. **Fastlane match** — Git-encrypted certificates; the whole team uses one source of truth
3. **Two pins minimum** — primary + backup certificate pin; never ship pinning that can lock users out
4. **Phased rollout always** — 1% first; monitor crash rate before widening; pausing beats rolling back
5. **dSYM/mapping upload is not optional** — unreadable stack traces in production are unacceptable

## Reference Files

- `references/store-configuration.md` — App Store Connect setup, TestFlight internal/external testing, submission flow and rejection responses, Google Play Console configuration, testing tracks, AAB release management, review guideline compliance (iOS and Android), phased rollout controls
- `references/signing-fastlane-crash.md` — iOS code signing and distribution certificates, Android keystore and Play App Signing, provisioning profile types (Development, Ad Hoc, App Store, Enterprise), Fastlane core tools (match, gym, deliver, supply, pilot), recommended Fastlane lanes, CI/CD integration, Firebase Crashlytics setup, Sentry symbolication
