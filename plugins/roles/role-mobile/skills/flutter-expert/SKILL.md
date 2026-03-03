---
name: role-mobile:flutter-expert
description: Expert guidance on Flutter 3.x (Impeller, Material 3, DevTools, Flame), Dart 3.x (records, patterns, sealed classes, macros), state management (Riverpod 2 with codegen, BLoC/Cubit, Signals), navigation (GoRouter, auto_route), networking (Dio, Chopper, Ferry/Artemis GraphQL), local storage (Drift, ObjectBox, Isar, Hive), testing (widget_test, golden tests, patrol, mocktail, bloc_test), Flutter for Web/Desktop/Embedded, Mason, very_good_cli, DCM, custom_lint, Flutter Hooks, freezed. Use when building or optimizing Flutter apps.
allowed-tools: Read, Grep, Glob, Bash
---

# Flutter Expert

## When to use
- Building or optimizing a Flutter application for mobile, web, or desktop
- Choosing or migrating state management (Riverpod 2, BLoC, Signals)
- Selecting a local database (Drift, ObjectBox, Isar, Hive)
- Setting up navigation with GoRouter or auto_route
- Writing widget tests, golden tests, or integration tests with Patrol
- Using Dart 3 features: records, patterns, sealed classes, macros
- Targeting Flutter for Web, Desktop, or building a game with Flame
- Optimizing widget rebuilds, memory usage, and frame rendering

## Core principles
1. **Const everywhere** — `const` constructors skip rebuilds; Flutter can only optimize what it knows is stable
2. **Riverpod 2 with codegen** — `@riverpod` annotation over manual provider wiring; generated code is the contract
3. **Sealed classes + pattern matching** — exhaustive state modeling; `when` over nested if-chains
4. **Isolate heavy work** — `Isolate.run()` for CPU-intensive tasks; never block the main isolate
5. **Pigeon over raw MethodChannels** — type-safe platform interop; eliminate stringly-typed method names

## Reference Files

- `references/dart3-state-navigation.md` — widget composition best practices, Dart 3 records/patterns/sealed classes/macros, Riverpod 2 with codegen, BLoC/Cubit patterns, Signals, GetX caveats, GoRouter with StatefulShellRoute, auto_route
- `references/networking-storage-testing.md` — Dio interceptors and cancellation, Chopper code-gen, Ferry/Artemis GraphQL, Drift reactive ORM, ObjectBox, Isar, Hive TypeAdapters, SharedPreferences, widget tests, golden tests, integration tests, Patrol native automation, Mocktail, bloc_test
- `references/platform-tooling-performance.md` — Flutter for Web (CanvasKit/WASM), Desktop (macOS/Windows/Linux), Flame game engine, Serverpod, Dart Frog, Mason bricks, very_good_cli, DCM, custom_lint, Pigeon type-safe channels, FFI, Flutter Hooks, freezed, performance checklist
