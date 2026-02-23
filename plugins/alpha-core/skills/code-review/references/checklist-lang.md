# Language-Specific Review Checks

## When to load
Load when reviewing code in a specific language: TypeScript/JavaScript, Python, Go, Java, Kotlin, Rust, Swift, or Ruby, to apply language-idiomatic review criteria.

## TypeScript / JavaScript
- Strict mode enabled (`"strict": true` in tsconfig), no `any` types without justification
- Proper null/undefined handling (optional chaining `?.`, nullish coalescing `??`)
- Async/await used consistently (no mixing with `.then` chains in same function)
- Proper error handling in async functions — `try/catch` or `.catch()`, never unhandled
- No prototype pollution risks — validate keys before `Object.assign` with user input
- `===` over `==` for comparisons; no dynamic code evaluation with user data
- Proper cleanup in `useEffect` return / event listener removal
- Enums: prefer `as const` objects over TypeScript enums for tree-shaking

## Python
- Type hints on function signatures (`mypy --strict` or `pyright` for verification)
- Context managers for resources (`with open()`, database connections, locks)
- Proper exception handling (specific exceptions, not bare `except:`)
- `__all__` defined for public modules; use `dataclasses` or `pydantic` for data structures
- Avoid mutable default arguments (`def f(items=[])` — use `None` with conditional)
- `logging` module over `print()`; `pathlib.Path` over `os.path`

## Go
- Errors are checked and handled — not ignored with `_` (`golangci-lint` catches this)
- Context propagated for cancellation — `ctx context.Context` as first parameter
- Goroutine leaks prevented — use `errgroup`, `context.WithCancel`, or `sync.WaitGroup`
- Interfaces are small and focused — accept interfaces, return structs
- `defer` for cleanup — but beware `defer` in loops (resource exhaustion)
- Error wrapping: `fmt.Errorf("operation failed: %w", err)` for stack context
- Table-driven tests with descriptive subtest names (`t.Run("when input is empty", ...)`)

## Java
- Null safety with `Optional<T>` — never return null from methods
- Resource management with try-with-resources (`try (var conn = getConnection())`)
- Thread safety for shared state — `ConcurrentHashMap`, `AtomicReference`, `volatile`
- Builder pattern or record types (Java 16+) for complex object construction
- No raw types (`List` without generics); `@Override` on all overridden methods
- Immutable collections (`List.of()`, `Map.of()`) where mutation is not needed

## Kotlin
- Nullable types (`String?`) used intentionally — avoid `!!` except in tests
- `data class` for value objects; `sealed class/interface` for exhaustive hierarchies
- Coroutines: structured concurrency with `coroutineScope`, `SupervisorJob` for independence
- `val` over `var` by default — mutability only when necessary
- Scope functions: `let` for null checks, `apply` for configuration, `also` for side effects

## Rust
- Ownership and borrowing are correct — no unnecessary `.clone()` to satisfy borrow checker
- Error handling: `Result<T, E>` with `?` operator, custom error types with `thiserror`
- `unwrap()` / `expect()` only in tests or with documented invariant justification
- `unsafe` blocks justified with `// SAFETY:` comment explaining invariants
- `clippy` lints addressed (`cargo clippy -- -W clippy::all -W clippy::pedantic`)
- Pattern matching is exhaustive — no catch-all `_` that hides new variants

## Swift
- Optionals handled safely — `guard let` / `if let` over force unwrapping `!`
- Value types (struct) preferred over reference types (class) unless identity semantics needed
- `@MainActor` and `Sendable` for concurrency safety (Swift 6 strict concurrency)
- Access control: `private` by default, `internal` for module, `public` for API surface
- `async/await` over completion handlers for new async code

## Ruby
- Frozen string literals enabled (`# frozen_string_literal: true`)
- `raise` specific exception classes; use `&.` (safe navigation) for nil-safe calls
- `freeze` constants to prevent mutation
- Use `Struct` or `Data` (Ruby 3.2+) for simple value objects
- Block style: `{}` for single-line, `do/end` for multi-line
