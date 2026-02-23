# Kotlin Idioms, Jetpack Compose & Room Database

## When to load
Load when writing Kotlin code, building Jetpack Compose UI, or implementing Room database persistence with reactive queries and migrations.

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

## Material Design 3

- Use Material 3 components: `TopAppBar`, `NavigationBar`, `FloatingActionButton`
- Dynamic color theming with `dynamicDarkColorScheme` / `dynamicLightColorScheme`
- Follow M3 elevation system: tonal elevation instead of shadow elevation
- Use M3 navigation patterns: NavigationBar (bottom), NavigationRail (medium), NavigationDrawer (expanded)
- Implement predictive back gesture support (Android 14+)
