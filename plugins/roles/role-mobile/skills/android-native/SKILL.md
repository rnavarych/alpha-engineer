---
name: android-native
description: Expert guidance on Android native development — Kotlin idioms, Jetpack Compose UI, Room database, Hilt dependency injection, Coroutines and Flow for async work, WorkManager for background tasks, Gradle build configuration (KTS), Material Design 3 theming, and Navigation Compose. Use when building or optimizing native Android applications.
allowed-tools: Read, Grep, Glob, Bash
---

# Android Native

## When to use
- Building or optimizing a native Android application with Kotlin and Jetpack Compose
- Setting up Hilt dependency injection and scoping
- Writing Room DAOs with reactive Flow queries and migrations
- Implementing Coroutines and Flow for async work and UI state management
- Scheduling background tasks with WorkManager (sync, uploads, cleanup)
- Configuring Gradle KTS build files with version catalogs and product flavors
- Implementing Navigation Compose with type-safe routes and deep links

## Core principles
1. **Sealed classes for state** — exhaustive `when` over brittle string/enum checks; the compiler catches missing cases
2. **StateFlow for UI, SharedFlow for events** — mixing them up means missing emissions or replaying stale events
3. **repeatOnLifecycle, not lifecycleScope.launch** — collecting in the wrong lifecycle state silently drains battery
4. **Hilt scopes are contracts** — `@Singleton` shared across the whole app; `@ViewModelScoped` dies with the VM; get it wrong and you leak
5. **R8 in release, always** — unminified Android release builds are a gift to reverse engineers

## Reference Files

- `references/kotlin-compose-room.md` — Kotlin idioms (data classes, sealed classes, scope functions, value classes), Jetpack Compose core concepts, layout system, theming with Material You, Room entity/DAO/database setup, reactive Flow queries, migrations, TypeConverters, Material Design 3 components and navigation patterns
- `references/hilt-coroutines-workmanager-gradle.md` — Hilt annotations and scoping, Coroutines dispatchers and cancellation, Flow operators (StateFlow, SharedFlow, callbackFlow, collectAsStateWithLifecycle), WorkManager request types and constraints, work chaining, Gradle KTS with version catalogs and product flavors, Navigation Compose type-safe routes and nested graphs
