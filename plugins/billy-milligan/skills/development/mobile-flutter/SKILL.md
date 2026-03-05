---
name: mobile-flutter
description: Flutter 3.27+ patterns — Riverpod 2 state with codegen, GoRouter 14+ navigation, Impeller rendering (default on all platforms), WASM web, extension types, on-device AI (firebase_ai, MediaPipe), Patrol 3.x testing, platform channels, performance
allowed-tools: Read, Grep, Glob, Bash
---

# Mobile Flutter Skill

## Core Principles
- **const widgets everywhere**: `const` constructor = compile-time constant = O(1) rebuild check.
- **Riverpod 2 with codegen**: `@riverpod` annotation — generated code is the contract; never manual provider wiring.
- **GoRouter 14+ for navigation**: Declarative routing, type-safe `@TypedGoRoute`, `StatefulShellRoute` for tab state.
- **AsyncValue pattern**: Typed loading/error/data states — never manual `isLoading`/`hasError` bools.
- **Extension types for domain safety**: `extension type UserId(String _) implements String {}` — zero-cost, compile-time safe.
- **WASM for web**: `flutter build web --wasm` is the production default; `dart:js_interop` replaces `dart:html`.
- **Impeller is the default**: No SkSL pre-warming needed; consistent 60/120fps on iOS (Metal) and Android (Vulkan).

## References
- `references/state-management.md` — Riverpod 2 codegen, BLoC 9.x, Provider comparison, Signals
- `references/navigation.md` — GoRouter 14+, StatefulShellRoute, type-safe routes, deep linking, auth guards
- `references/platform-channels.md` — Pigeon (recommended), MethodChannel, EventChannel, dart:ffi
- `references/performance.md` — Widget rebuild optimization, ListView.builder, isolates, Impeller profiling
- `references/flutter-profiling.md` — DevTools frame timeline, memory leak detection, RepaintBoundary, Impeller vs Skia, platform channel overhead
