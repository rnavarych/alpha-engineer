# Swift, SwiftUI & Data Persistence

## When to load
Load when writing Swift/SwiftUI code, handling UIKit interop, or implementing Core Data and SwiftData persistence with migrations and reactive fetching.

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
