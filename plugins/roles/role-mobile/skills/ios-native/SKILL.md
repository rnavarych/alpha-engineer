---
name: role-mobile:ios-native
description: Expert guidance on iOS native development — Swift and SwiftUI best practices, UIKit interop, Core Data and SwiftData persistence, Combine reactive framework, structured concurrency (async/await, actors), App Clips, WidgetKit, Xcode project configuration, and Swift Package Manager. Use when building or optimizing native iOS applications.
allowed-tools: Read, Grep, Glob, Bash
---

# iOS Native

## When to use
- Building or optimizing a native iOS application with Swift and SwiftUI
- Wrapping UIKit components or embedding SwiftUI inside UIKit navigation
- Implementing Core Data or SwiftData persistence with migrations
- Replacing Combine chains with structured concurrency (async/await, actors)
- Building App Clips, WidgetKit extensions, or interactive widgets (iOS 17+)
- Configuring Xcode build settings per environment with .xcconfig files
- Managing dependencies with Swift Package Manager and local package modules

## Core principles
1. **@Observable over ObservableObject** — iOS 17+ macro is less boilerplate and more precise observation; stop using `@Published` everywhere
2. **async let for parallelism** — sequential awaits are serialized; independent async work should run concurrently
3. **Actors for shared mutable state** — `@MainActor` for UI; custom actors for domain isolation; Sendable for cross-boundary types
4. **SwiftData for new apps, Core Data for existing** — do not start a new project on a pre-iOS 17 ORM if you can avoid it
5. **SPM over CocoaPods** — local packages for feature modules; the build system integration is first-class now

## Reference Files

- `references/swift-swiftui-data.md` — SwiftUI property wrappers (@State, @Binding, @Observable, @Environment), UIKit interop (UIViewRepresentable, UIHostingController, Coordinator), SwiftData @Model/@Query/ModelContainer, Core Data NSPersistentContainer and NSFetchedResultsController, Combine operators and AnyCancellable lifecycle
- `references/concurrency-extensions-config.md` — async/await patterns (async let, withTaskGroup, Task.detached), actor isolation (@MainActor, GlobalActor, nonisolated, Sendable), App Clips invocation and limitations, WidgetKit TimelineProvider and interactive widgets, Xcode .xcconfig per-environment configuration, SPM Package.swift local modules and binary targets
