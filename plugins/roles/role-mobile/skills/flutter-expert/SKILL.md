---
name: role-mobile:flutter-expert
description: Expert guidance on Flutter 3.27+ (Impeller default on all platforms, Material 3, WASM web, DevTools, Flame), Dart 3.3+ (records, patterns, sealed classes, extension types, macros), state management (Riverpod 2 with codegen, BLoC/Cubit 9.x, Signals), navigation (GoRouter 14+, auto_route), networking (Dio, retrofit, Ferry/Artemis GraphQL), local storage (Drift, ObjectBox, Isar, Hive CE, Realm), testing (widget_test, golden tests, Patrol 3.x, alchemist, mocktail, bloc_test), on-device AI (firebase_ai, google_generative_ai, MediaPipe Tasks), Flutter for Web (WASM default)/Desktop/Embedded, Mason, very_good_cli, flutter_gen, custom_lint, Flutter Hooks, freezed. Use when building or optimizing Flutter apps.
allowed-tools: Read, Grep, Glob, Bash
---

# Flutter Expert

## When to use
- Building or optimizing a Flutter application for mobile, web, or desktop
- Choosing or migrating state management (Riverpod 2, BLoC, Signals)
- Selecting a local database (Drift, ObjectBox, Isar, Hive CE, Realm)
- Setting up navigation with GoRouter 14+ or auto_route
- Writing widget tests, golden tests, or integration tests with Patrol 3.x
- Using Dart 3.3+ features: records, patterns, sealed classes, extension types, macros
- Targeting Flutter for Web (WASM), Desktop, or building a game with Flame
- Integrating on-device AI with firebase_ai, google_generative_ai, or MediaPipe Tasks
- Optimizing widget rebuilds, memory usage, and Impeller-based frame rendering

## Core principles
1. **Const everywhere** — `const` constructors skip rebuilds; Flutter can only optimize what it knows is stable
2. **BLoC/Cubit as the default state manager** — most stable API in the ecosystem, unchanged for years; use `setState + composition` for simple cases; consider Riverpod only after understanding its framework-level weight
3. **Sealed classes + pattern matching** — exhaustive state modeling; prefer native Dart 3 sealed over freezed for simple unions
4. **`http` for networking baseline, Dio only when needed** — interceptors, cancellation, and FormData are real reasons; don't add Dio speculatively
5. **Drift for structured data, SharedPreferences for primitives** — Hive/Isar have known in-memory risks and no isolate support; use them with eyes open
6. **Isolate heavy work** — `Isolate.run()` for CPU-intensive tasks; never block the main isolate
7. **Pigeon over raw MethodChannels** — type-safe platform interop; eliminate stringly-typed method names
8. **Extension types for domain safety** — zero-cost wrappers: `extension type UserId(String _) implements String {}` prevents primitive obsession
9. **WASM for Flutter Web** — `flutter build web --wasm` is the production default; CanvasKit is legacy

## Reference Files

- `references/dart3-state-navigation.md` — widget composition best practices, Dart 3.3+ records/patterns/sealed classes/extension types/macros, Riverpod 2 with codegen, BLoC/Cubit 9.x, Signals, GoRouter 14+ with StatefulShellRoute, auto_route
- `references/networking-storage-testing.md` — Dio interceptors and cancellation, retrofit code-gen, Ferry/Artemis GraphQL, Drift reactive ORM, ObjectBox, Isar, Hive CE, Realm, SharedPreferences, widget tests, golden tests, Patrol 3.x native automation, alchemist golden tests, Mocktail, bloc_test
- `references/platform-tooling-performance.md` — Flutter Web WASM (default), Desktop (macOS/Windows/Linux), on-device AI (firebase_ai, google_generative_ai, MediaPipe Tasks), Flame game engine, Serverpod 2.x, Dart Frog, Mason bricks, very_good_cli, flutter_gen, custom_lint, Pigeon type-safe channels, FFI, Flutter Hooks, freezed, Impeller performance checklist
