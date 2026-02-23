# Structured Concurrency, Extensions & Project Configuration

## When to load
Load when implementing async/await and actors, building App Clips or WidgetKit extensions, or configuring Xcode project settings and Swift Package Manager.

## Structured Concurrency

### async/await
- Mark functions `async` and call with `await` — no completion handler nesting
- Use `async let` for concurrent execution of independent async work
- `Task {}` to bridge from synchronous to async context
- `Task.detached {}` for work with no inherited context (rare, use carefully)
- Use `withTaskGroup` / `withThrowingTaskGroup` for dynamic parallelism

### Actors
- Use `actor` to protect mutable state from data races
- `@MainActor` for UI-bound state and view models
- `nonisolated` for computed properties and functions that don't access state
- `GlobalActor` for domain-specific isolation (e.g., database actor)
- Prefer `Sendable` conformance for types shared across concurrency domains

## App Clips

- Lightweight app experience under 15MB (10MB recommended)
- Invoked via NFC, QR codes, App Clip Codes, Safari banners, Maps, Messages
- Use `NSUserActivity` and associated domains for invocation handling
- Share data with full app via App Group container
- Prompt migration to full app with `SKOverlay`
- Limit frameworks — App Clips cannot use background modes, CallKit, or HealthKit

## WidgetKit

- Use `TimelineProvider` to supply widget entries with `getTimeline`
- Define `TimelineEntry` with date and display data
- Use `StaticConfiguration` (no user config) or `IntentConfiguration` (user-configurable)
- Interactive widgets (iOS 17+) with `Button` and `Toggle` via `AppIntent`
- Keep widget views simple — no scroll views, no animations, limited interactivity
- Shared data with main app via App Group and `UserDefaults(suiteName:)`

## Xcode Project Configuration

- Use `.xcconfig` files for build settings per environment (Debug, Staging, Release)
- Separate Info.plist values per configuration (bundle ID, display name, API URLs)
- Enable `-warnings-as-errors` in Release for strict compilation
- Configure App Thinning: bitcode (deprecated in Xcode 14+), slicing, on-demand resources
- Use build phases for SwiftLint, SwiftFormat, and code generation scripts

## Swift Package Manager (SPM)

- Prefer SPM over CocoaPods / Carthage for dependency management
- Define `Package.swift` for shared modules and internal frameworks
- Use local packages for modularized project structure (feature modules)
- Specify version constraints: `.upToNextMajor(from:)`, `.upToNextMinor(from:)`
- Use binary targets (`.xcframework`) for closed-source dependencies
- Create package plugins for build tools (SwiftGen, SwiftLint integration)
