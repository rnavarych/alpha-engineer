---
name: mobile-flutter
description: Flutter patterns — Riverpod state, GoRouter navigation, platform channels, performance
allowed-tools: Read, Grep, Glob, Bash
---

# Mobile Flutter Skill

## Core Principles
- **const widgets everywhere**: `const` constructor = compile-time constant = O(1) rebuild check.
- **Riverpod for state**: Testable, type-safe, no BuildContext dependency for providers.
- **GoRouter for navigation**: Declarative routing with redirect guards.
- **AsyncValue pattern**: Typed loading/error/data states — never manual bool flags.
- **ListView.builder for lists**: Lazy rendering, not Column with list.map().

## References
- `references/state-management.md` — Riverpod, BLoC, Provider comparison
- `references/navigation.md` — GoRouter, deep linking, auth guards
- `references/platform-channels.md` — MethodChannel, EventChannel, FFI
- `references/performance.md` — Widget rebuild optimization, ListView.builder, isolates for background computation
- `references/flutter-profiling.md` — DevTools, frame budget, memory leak detection, RepaintBoundary, Impeller vs Skia, platform channel overhead
