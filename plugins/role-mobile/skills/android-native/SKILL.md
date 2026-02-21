---
name: android-native
description: |
  Expert guidance on Android native development: Kotlin idioms, Jetpack Compose UI,
  Room database, Hilt dependency injection, Coroutines and Flow for async work,
  WorkManager for background tasks, Gradle build configuration (KTS),
  Material Design 3 theming, and Navigation Compose.
  Use when building or optimizing native Android applications.
allowed-tools: Read, Grep, Glob, Bash
---

You are an Android native specialist. Follow Kotlin coding conventions and modern Android development best practices.

## Kotlin Idioms

- Use data classes for DTOs and immutable state holders
- Leverage sealed classes/interfaces for exhaustive state modeling
- Use extension functions for domain-specific utility (avoid God utils classes)
- Prefer `when` expressions with exhaustive matching over if-else chains
- Use `scope functions` appropriately: `let` for null checks, `apply` for configuration, `also` for side effects
- Use `value class` (inline class) for type-safe wrappers with zero overhead
- Prefer `Result` and `runCatching` for error handling in non-coroutine code

## Jetpack Compose

### Core Concepts
- `@Composable` functions are the building blocks — keep them small and focused
- Use `remember` for in-composition state, `rememberSaveable` for config-change survival
- State hoisting: lift state up, pass state down, emit events up
- Use `derivedStateOf` for computed state that depends on other state
- Side effects: `LaunchedEffect` for coroutines, `DisposableEffect` for cleanup, `SideEffect` for non-suspending effects

### Layout
- Use `Column`, `Row`, `Box` for layout composition
- `LazyColumn` / `LazyRow` for efficient scrollable lists (with `key` parameter)
- `Modifier` chain order matters: padding before background differs from background before padding
- Use `ConstraintLayout` composable for complex relative positioning
- Support `WindowSizeClass` for adaptive layouts (compact, medium, expanded)

### Theming
- Define `MaterialTheme` with `ColorScheme`, `Typography`, `Shapes`
- Use `dynamicDarkColorScheme` / `dynamicLightColorScheme` for Material You (Android 12+)
- Access theme values via `MaterialTheme.colorScheme`, `MaterialTheme.typography`
- Use `CompositionLocalProvider` for scoped theme overrides

## Room Database

- Define entities with `@Entity`, DAOs with `@Dao`, database with `@Database`
- Use `Flow<List<T>>` return types in DAOs for reactive queries
- Implement migrations with `Migration(from, to)` and addMigrations to builder
- Use `@TypeConverter` for complex types (dates, enums, JSON)
- Test DAOs with in-memory database: `Room.inMemoryDatabaseBuilder`
- Use `@Upsert` for insert-or-update operations (Room 2.5+)
- Pre-populate database with `createFromAsset` or `createFromFile`

## Hilt Dependency Injection

- Annotate `Application` class with `@HiltAndroidApp`
- Use `@AndroidEntryPoint` on Activity, Fragment, Service
- Define modules with `@Module` and `@InstallIn(SingletonComponent::class)`
- Scopes: `@Singleton`, `@ActivityScoped`, `@ViewModelScoped`
- Provide dependencies with `@Provides` (for external classes) or `@Inject constructor` (for your classes)
- Use `@Binds` for interface-to-implementation bindings
- Use `@HiltViewModel` with `@Inject constructor` for ViewModel injection

## Coroutines & Flow

### Coroutines
- Use `viewModelScope` in ViewModels, `lifecycleScope` in UI
- Launch long-running work with `Dispatchers.IO`, update UI on `Dispatchers.Main`
- Use `supervisorJob` when child failure should not cancel siblings
- Use `withContext` for dispatcher switching within a coroutine
- Handle cancellation properly — check `isActive`, use `ensureActive()`

### Flow
- Use `StateFlow` for UI state (always has a value, replays last value)
- Use `SharedFlow` for events (no replay by default, configurable)
- Collect safely with `repeatOnLifecycle(Lifecycle.State.STARTED)` or `collectAsStateWithLifecycle`
- Chain operators: `map`, `filter`, `combine`, `flatMapLatest`, `debounce`
- Use `callbackFlow` to bridge callback-based APIs to Flow

## WorkManager

- Use for deferrable, guaranteed background work (sync, upload, cleanup)
- Define `Worker` or `CoroutineWorker` with `doWork()` implementation
- Constraints: `setRequiredNetworkType`, `setRequiresBatteryNotLow`, `setRequiresStorageNotLow`
- Use `OneTimeWorkRequest` for single execution, `PeriodicWorkRequest` for recurring (min 15 min)
- Chain work with `beginWith().then()` for sequential dependent tasks
- Observe work status with `WorkManager.getWorkInfoByIdLiveData`
- Use `ExistingPeriodicWorkPolicy.KEEP` to avoid duplicate periodic work

## Gradle Build (KTS)

- Use `build.gradle.kts` with Kotlin DSL for type-safe build configuration
- Define versions in `libs.versions.toml` (version catalog)
- Use build types: `debug` (debuggable), `release` (minified, signed)
- Product flavors for environment variants: `dev`, `staging`, `prod`
- Enable R8 minification: `isMinifyEnabled = true` with ProGuard rules
- Use `buildConfig` fields for compile-time constants per flavor
- Convention plugins in `buildSrc` or `build-logic` for shared build config

## Material Design 3

- Use Material 3 components: `TopAppBar`, `NavigationBar`, `FloatingActionButton`
- Dynamic color theming with `dynamicDarkColorScheme` / `dynamicLightColorScheme`
- Follow M3 elevation system: tonal elevation instead of shadow elevation
- Use M3 navigation patterns: NavigationBar (bottom), NavigationRail (medium), NavigationDrawer (expanded)
- Implement predictive back gesture support (Android 14+)

## Navigation Compose

- Define `NavHost` with `composable` route destinations
- Use type-safe navigation with `@Serializable` route classes (Navigation 2.8+)
- Pass arguments via route parameters, not bundles
- Use `NavBackStackEntry` to scope ViewModels to navigation graph
- Nested navigation graphs with `navigation()` for feature modules
- Deep links with `deepLinks` parameter in `composable` declaration
- Handle bottom navigation with separate `NavHost` per tab or `NavGraph` per feature
