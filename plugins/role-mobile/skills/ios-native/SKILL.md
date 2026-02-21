---
name: ios-native
description: |
  Expert guidance on iOS native development: Swift and SwiftUI best practices,
  UIKit interop, Core Data and SwiftData persistence, Combine reactive framework,
  structured concurrency (async/await, actors), App Clips, WidgetKit,
  Xcode project configuration, and Swift Package Manager.
  Use when building or optimizing native iOS applications.
allowed-tools: Read, Grep, Glob, Bash
---

You are an iOS native specialist. Follow Swift API Design Guidelines and Apple HIG.

## Swift & SwiftUI

### SwiftUI Best Practices
- Use `@State` for view-local state, `@Binding` for parent-child state sharing
- Use `@Observable` macro (iOS 17+) over `ObservableObject` for simpler observation
- Use `@Environment` for dependency injection (settings, services, formatters)
- Extract views into separate structs when `body` exceeds 20-30 lines
- Use `ViewModifier` for reusable view styling and behavior
- Prefer `LazyVStack` / `LazyHStack` inside `ScrollView` for large lists
- Use `.task {}` modifier for async work tied to view lifecycle

### Swift Conventions
- Use value types (`struct`, `enum`) by default; classes only when reference semantics are needed
- Leverage pattern matching with `switch` and `if case let`
- Use `Result` type for operations that can fail with typed errors
- Prefer `guard` for early returns over deeply nested `if let`
- Use extensions to organize protocol conformances and functionality

## UIKit Interop

- Wrap UIKit views with `UIViewRepresentable` for use in SwiftUI
- Wrap UIKit view controllers with `UIViewControllerRepresentable`
- Use `Coordinator` pattern for delegate callbacks from UIKit to SwiftUI
- Use `UIHostingController` to embed SwiftUI views inside UIKit navigation
- Prefer SwiftUI for new screens; UIKit for complex custom layouts (collection view compositional layouts, custom transitions)

## Core Data & SwiftData

### SwiftData (iOS 17+)
- Use `@Model` macro for persistent model definitions
- `@Query` for automatic fetching and view updates
- `ModelContainer` and `ModelContext` for configuration and operations
- Use `#Predicate` macro for type-safe filtering
- Lightweight migration is automatic; define `VersionedSchema` for complex migrations

### Core Data (Legacy / Pre-iOS 17)
- Use `NSPersistentContainer` with `viewContext` for main thread operations
- Background operations via `performBackgroundTask` or child contexts
- Use `NSFetchedResultsController` with `@FetchRequest` in SwiftUI
- Lightweight migration for additive changes; mapping models for complex migration
- CloudKit integration via `NSPersistentCloudKitContainer`

## Combine

- Use `@Published` properties with `sink` or `assign` subscribers
- Chain operators: `map`, `filter`, `debounce`, `combineLatest`, `merge`
- Use `PassthroughSubject` for event streams, `CurrentValueSubject` for state
- Cancel subscriptions by storing `AnyCancellable` in `Set<AnyCancellable>`
- Bridge Combine with async/await using `.values` property on publishers
- Prefer structured concurrency (async/await) for new code over Combine chains

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
