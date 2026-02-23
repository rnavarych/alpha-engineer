# Hilt, Coroutines, WorkManager, Gradle & Navigation

## When to load
Load when setting up Hilt dependency injection, writing coroutines and Flow, scheduling background tasks with WorkManager, configuring Gradle build files, or implementing Navigation Compose.

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

## Navigation Compose

- Define `NavHost` with `composable` route destinations
- Use type-safe navigation with `@Serializable` route classes (Navigation 2.8+)
- Pass arguments via route parameters, not bundles
- Use `NavBackStackEntry` to scope ViewModels to navigation graph
- Nested navigation graphs with `navigation()` for feature modules
- Deep links with `deepLinks` parameter in `composable` declaration
- Handle bottom navigation with separate `NavHost` per tab or `NavGraph` per feature
