# Dart 3, State Management & Navigation

## When to load
Load when using Dart 3 language features (records, patterns, sealed classes, macros), choosing or implementing state management (Riverpod 2, BLoC/Cubit, Signals, GetX), or configuring navigation with GoRouter or auto_route.

## Widget Composition

- Prefer composition over inheritance — build complex widgets from small, focused widgets
- Extract widget subtrees into separate classes (not methods) for rebuild optimization
- Use `const` constructors wherever possible to enable widget caching
- Separate stateless presentation widgets from stateful container widgets
- Use `Key` appropriately: `ValueKey` for list items, `GlobalKey` sparingly
- Keep `build()` methods lean — move logic to separate classes or extensions
- `InheritedWidget` for efficient data propagation without rebuilding the full tree

## Dart 3.x Features

### Records
- Anonymous immutable value types: `(String name, int age)` or named `({String name, int age})`
- Pattern-based destructuring: `final (name, age) = record;`
- Record types in function return for multiple-value returns without custom classes

### Patterns
- Switch expressions with pattern matching: `switch (shape) { Circle(:var radius) => ..., ... }`
- Object patterns: `case Circle(radius: var r) when r > 0`
- List and map patterns for destructuring collections
- Guard clauses in patterns with `when` keyword
- `if-case` statements for inline pattern matching

### Sealed Classes
- `sealed class Shape {}` — compiler guarantees exhaustive switch coverage
- All subclasses must be in the same library as the sealed class
- Pair with pattern matching for type-safe, exhaustive state modeling

### Class Modifiers
- `final` class: cannot be extended or implemented outside the library
- `base` class: can be extended but not implemented outside the library
- `interface` class: can be implemented but not extended outside the library
- `mixin` class: can be used as both a mixin and a class

### Macros (Preview / Experimental)
- Compile-time code generation without `build_runner`
- `@JsonCodable()` macro generates `fromJson`/`toJson` without manual boilerplate
- Currently available behind `--enable-experiment=macros` flag

## State Management

### Riverpod 2 with Code Generation
- Use `@riverpod` annotation — `build_runner` generates provider definitions
- `@riverpod` on a function → `FutureProvider` or `Provider`
- `@riverpod` on a class extending `Notifier` → `NotifierProvider`
- `ref.watch(provider)` in build methods for reactive subscriptions
- `ref.read(provider)` in callbacks for one-time reads (no subscription)
- `ref.listen(provider, (prev, next) {...})` for side effects on value change
- `@riverpod` with `keepAlive: true` to prevent auto-disposal
- `ProviderScope.overrides` for testing with mock implementations

### BLoC / Cubit
- `flutter_bloc` package: `Bloc<Event, State>` and `Cubit<State>`
- Sealed event classes for exhaustive event handling in `on<EventType>(handler)`
- `Cubit<State>` for simpler state without event mapping overhead
- `BlocProvider` for DI, `BlocBuilder` for UI, `BlocListener` for side effects
- `BlocSelector` for rebuilding only when a specific derived value changes
- `blocTest` from `bloc_test` for unit testing BLoC/Cubit in isolation

### Signals (Preact Signals port)
- Fine-grained reactivity without provider scoping
- `signal(value)` creates a reactive primitive; `computed(() => ...)` for derived values
- `Watch` widget rebuilds only the subtree that reads a signal
- Lower boilerplate than Riverpod for simple local-ish state

### GetX (Lightweight Alternative)
- `GetxController` with `obs` variables for reactive state
- Avoid for large teams — implicit magic makes testing and reasoning harder

## Navigation

### GoRouter
- `GoRouter` with `routes` list of `GoRoute` and `ShellRoute` definitions
- Type-safe routes via `@TypedGoRoute` annotation + `build_runner` code generation
- `ShellRoute` for persistent bottom navigation bar across tabs
- `StatefulShellRoute` for preserving scroll and state across bottom nav tabs (GoRouter 7+)
- `redirect` callback for authentication guards: return `/login` if not authenticated
- `context.go()`, `context.push()`, `context.pop()` via `GoRouterHelper` extension

### auto_route
- Code-generated routing with `@RoutePage()` annotation on screen widgets
- Type-safe navigation: `context.router.push(HomeRoute())`
- `AutoRouteGuard` for auth flows
- Less boilerplate in complex nested navigation scenarios vs. manual GoRouter config
