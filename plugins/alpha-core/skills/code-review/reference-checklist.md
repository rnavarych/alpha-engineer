# Code Review Detailed Checklist

## Language-Specific Checks

### TypeScript/JavaScript
- Strict mode enabled (`"strict": true` in tsconfig), no `any` types without justification
- Proper null/undefined handling (optional chaining `?.`, nullish coalescing `??`)
- Async/await used consistently (no mixing with `.then` chains in same function)
- Proper error handling in async functions -- `try/catch` or `.catch()`, never unhandled
- No prototype pollution risks -- don't use `Object.assign` with user input, validate keys
- Dependencies imported correctly (no circular imports -- use `madge` to detect)
- `===` over `==` for comparisons (no implicit type coercion)
- No dynamic code evaluation with user data
- Proper cleanup in `useEffect` return / event listener removal
- Enums: prefer `as const` objects over TypeScript enums for tree-shaking

### Python
- Type hints on function signatures (use `mypy --strict` or `pyright` for verification)
- Context managers for resources (`with open()`, database connections, locks)
- List comprehensions over loops where readable -- don't nest more than 2 levels
- f-strings over `format()` or `%` -- but never f-strings with user input in SQL/shell
- Proper exception handling (specific exceptions, not bare `except:` or `except Exception:`)
- `__all__` defined for public modules to control exports
- Use `dataclasses` or `pydantic` for data structures, not plain dicts
- Avoid mutable default arguments (`def f(items=[])` -- use `None` with conditional)
- Use `pathlib.Path` over `os.path` for filesystem operations
- `logging` module over `print()` -- structured logging with proper levels

### Go
- Errors are checked and handled (not ignored with `_`) -- `golangci-lint` catches this
- Context is propagated for cancellation -- `ctx context.Context` as first parameter
- Goroutine leaks are prevented -- use `errgroup`, `context.WithCancel`, or `sync.WaitGroup`
- Interfaces are small and focused -- accept interfaces, return structs
- `defer` for cleanup operations -- but beware `defer` in loops (resource exhaustion)
- Error wrapping with `fmt.Errorf("operation failed: %w", err)` for stack context
- No `init()` functions unless absolutely necessary (testing difficulty, hidden coupling)
- Struct field alignment for memory efficiency on hot-path structs
- Table-driven tests with descriptive subtest names (`t.Run("when input is empty", ...)`)
- Channel direction annotations (`chan<-`, `<-chan`) for type safety

### Java
- Null safety with `Optional<T>` -- never return null from methods, use `Optional.empty()`
- Resource management with try-with-resources (`try (var conn = getConnection())`)
- Thread safety for shared state -- `ConcurrentHashMap`, `AtomicReference`, `volatile`
- Proper exception hierarchy -- checked for recoverable, runtime for programming errors
- Builder pattern or record types (Java 16+) for complex object construction
- Streams used appropriately -- don't chain more than 4-5 operations, avoid side effects
- No raw types (`List` without generics) -- always parameterize
- `@Override` on all overridden methods
- Immutable collections (`List.of()`, `Map.of()`) where mutation is not needed
- Sealed classes/interfaces (Java 17+) for exhaustive pattern matching

### Kotlin
- Nullable types (`String?`) used intentionally -- avoid `!!` (non-null assertion) except in tests
- `data class` for value objects, `sealed class/interface` for exhaustive hierarchies
- Extension functions over utility classes -- but don't overuse (keep discoverable)
- Coroutines: structured concurrency with `coroutineScope`, proper `SupervisorJob` for independence
- `when` expressions are exhaustive (sealed class branches)
- `val` over `var` by default -- mutability only when necessary
- Use `require()`, `check()`, `error()` for preconditions and invariants
- Scope functions used appropriately: `let` for null checks, `apply` for configuration, `also` for side effects

### Rust
- Ownership and borrowing are correct -- no unnecessary `.clone()` to satisfy the borrow checker
- Error handling: `Result<T, E>` with `?` operator, custom error types with `thiserror`
- `unwrap()` / `expect()` only in tests or with documented invariant justification
- Lifetimes are minimal -- don't over-annotate, let the compiler infer where possible
- `clippy` lints addressed (`cargo clippy -- -W clippy::all -W clippy::pedantic`)
- `unsafe` blocks justified with `// SAFETY:` comment explaining invariants
- `derive` macros used consistently (`Debug`, `Clone`, `PartialEq` where appropriate)
- Pattern matching is exhaustive -- no catch-all `_` that hides new variants
- Proper use of `Arc<Mutex<T>>` vs `Rc<RefCell<T>>` -- thread safety vs single-thread

### Swift
- Optionals handled safely -- `guard let` / `if let` over force unwrapping `!`
- Value types (struct) preferred over reference types (class) unless identity semantics needed
- Protocol-oriented design -- prefer protocol conformance over class inheritance
- `@MainActor` and `Sendable` for concurrency safety (Swift 6 strict concurrency)
- Access control: `private` by default, `internal` for module, `public` for API surface
- Error handling with `do/try/catch` -- typed throws in Swift 6
- `async/await` over completion handlers for new async code

### Ruby
- Frozen string literals enabled (`# frozen_string_literal: true`)
- `raise` specific exception classes, not generic `RuntimeError`
- Use `&.` (safe navigation) for nil-safe method calls
- `freeze` constants to prevent mutation
- Prefer `each_with_object` over `inject`/`reduce` when building collections
- Use `Struct` or `Data` (Ruby 3.2+) for simple value objects
- Block style: `{}` for single-line, `do/end` for multi-line

## Security Vulnerability Patterns by Language

### TypeScript/JavaScript
- **Prototype pollution**: `merge(target, userInput)` modifying `Object.prototype` -- use `Object.create(null)` or validate keys
- **ReDoS**: Regex with nested quantifiers on user input -- `/(a+)+$/` -- use `re2` library
- **Path traversal**: `fs.readFile(userInput)` -- validate against allowlist, use `path.resolve` + prefix check
- **XSS**: Rendering user HTML -- use DOMPurify, avoid rendering raw user content
- **SSRF**: `fetch(userProvidedUrl)` -- validate URL scheme and host against allowlist

### Python
- **Unsafe deserialization**: Loading untrusted binary-serialized objects -- remote code execution risk; use JSON instead
- **Template injection**: `template.render(user_string)` in Jinja2 -- use sandboxed environment
- **YAML deserialization**: `yaml.load(data)` -- use `yaml.safe_load()` always
- **Command injection**: Spawning shell with user input -- use `subprocess.run([cmd, arg], shell=False)` with list args
- **SQL injection**: String interpolation in SQL -- use parameterized queries with `%s` placeholders

### Go
- **SQL injection**: `fmt.Sprintf("SELECT * FROM users WHERE id = '%s'", id)` -- use `db.Query("...WHERE id = $1", id)`
- **Path traversal**: `filepath.Join(base, userInput)` -- check result starts with base after `filepath.Clean`
- **Integer overflow**: Unchecked `int` arithmetic -- use `math.MaxInt` bounds checks
- **Goroutine leak**: Missing `context.Cancel()` -- always `defer cancel()` after `context.WithCancel`

### Java
- **Deserialization**: `ObjectInputStream.readObject()` -- use allowlist filter or avoid Java serialization
- **XXE**: XML parsing without disabling external entities -- `factory.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true)`
- **Log injection**: User input in log messages without sanitization -- newlines enable log forging
- **SSRF**: `new URL(userInput).openConnection()` -- validate host, scheme, port

### Rust
- **Unsafe blocks**: Memory safety guarantees suspended -- review all `unsafe` for UB (use `miri` to check)
- **Panic in libraries**: `unwrap()` in library code -- return `Result` instead, let caller decide
- **Integer overflow**: Release builds wrap by default -- use `checked_add`, `saturating_add` for critical math

### Kotlin
- **Serialization**: Kotlinx.serialization is safe, but Jackson with `@JsonTypeInfo` can lead to deserialization attacks
- **Coroutine exception swallowing**: Exceptions in `launch` without handler are silently dropped -- use `CoroutineExceptionHandler`
- **Null assertion**: `!!` on user-controlled input -- use safe calls or explicit validation

### Swift
- **Force unwrapping**: `userInput!` crashes on nil -- use `guard let` or `if let`
- **Insecure storage**: `UserDefaults` for sensitive data -- use Keychain Services instead
- **ATS bypass**: `NSAppTransportSecurity` exceptions -- minimize `NSAllowsArbitraryLoads`

### Ruby
- **Mass assignment**: `User.new(params)` -- use strong parameters (`permit(:name, :email)`)
- **Command injection**: Backtick execution with user input -- use `Open3.capture3` with array args
- **Template injection**: Rendering raw user input in ERB -- use auto-escaping or `sanitize` helper

## Database Migration Review Checklist

- [ ] Migration has a corresponding rollback (`down` migration)
- [ ] Rollback tested locally before merging
- [ ] No `DROP TABLE` or `DROP COLUMN` without confirming data is backed up or migrated
- [ ] `ALTER TABLE` on large tables uses online DDL (gh-ost, pt-online-schema-change, pgroll)
- [ ] New columns have `DEFAULT` values or are nullable -- avoids locking entire table
- [ ] Index creation uses `CONCURRENTLY` (PostgreSQL) or equivalent for zero-downtime
- [ ] Data migrations separated from schema migrations -- run in distinct deployment steps
- [ ] Foreign key constraints don't create cascading deletes that could wipe related data
- [ ] Enum type additions are backward-compatible -- new values added, none removed
- [ ] Migration is idempotent -- can be safely re-run without error
- [ ] Performance tested on a dataset approximating production size

### Migration Safety by Database

| Operation | PostgreSQL | MySQL | MongoDB |
|-----------|-----------|-------|---------|
| Add column (nullable) | Fast, no lock | Fast (8.0+), brief lock (5.7) | No schema change needed |
| Add column (with default) | Fast (11+), full rewrite (<11) | Brief lock | N/A |
| Add index | `CREATE INDEX CONCURRENTLY` | `ALGORITHM=INPLACE` | `background: true` |
| Rename column | Fast, but breaks queries | Fast (8.0+) | Update all documents |
| Drop column | Fast, but irreversible | Brief lock | Remove field from docs |
| Change column type | Full table rewrite | May require copy | Update documents |

## API Contract Review Checklist

- [ ] OpenAPI/GraphQL schema updated to match implementation changes
- [ ] No breaking changes to response structure (removed fields, type changes)
- [ ] New required request fields have backward-compatible defaults
- [ ] Deprecation warnings added for fields/endpoints being phased out
- [ ] Error responses follow the project's standard format (RFC 9457 / custom)
- [ ] Content-Type and Accept headers handled correctly
- [ ] Authentication requirements documented for new endpoints
- [ ] Rate limit tier documented for new endpoints
- [ ] Webhook payloads versioned if applicable
- [ ] Consumer contract tests updated (Pact, Spring Cloud Contract)

## Automated Linting Tool Configuration

### ESLint (TypeScript/JavaScript)
```json
{
  "extends": ["eslint:recommended", "plugin:@typescript-eslint/strict-type-checked"],
  "rules": {
    "no-console": "warn",
    "no-unused-vars": "off",
    "@typescript-eslint/no-unused-vars": ["error", { "argsIgnorePattern": "^_" }],
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/strict-boolean-expressions": "error"
  }
}
```

### Ruff (Python)
```toml
# pyproject.toml
[tool.ruff]
target-version = "py312"
line-length = 100
[tool.ruff.lint]
select = ["E", "F", "W", "I", "N", "UP", "S", "B", "A", "C4", "SIM", "TCH", "RUF"]
ignore = ["E501"]  # line length handled by formatter
[tool.ruff.lint.per-file-ignores]
"tests/**" = ["S101"]  # allow assert in tests
```

### golangci-lint (Go)
```yaml
# .golangci.yml
linters:
  enable:
    - errcheck
    - govet
    - staticcheck
    - unused
    - gosec
    - gocritic
    - gofumpt
    - exhaustive
    - prealloc
    - noctx
linters-settings:
  govet:
    check-shadowing: true
  errcheck:
    check-type-assertions: true
```

### Clippy (Rust)
```toml
# clippy.toml or in Cargo.toml
[lints.clippy]
all = "warn"
pedantic = "warn"
nursery = "warn"
unwrap_used = "deny"
expect_used = "warn"
```

### Detekt (Kotlin)
```yaml
# detekt.yml
complexity:
  LongMethod:
    threshold: 30
  ComplexMethod:
    threshold: 15
  TooManyFunctions:
    threshold: 15
style:
  ForbiddenComment:
    values: ['TODO', 'FIXME', 'HACK']
  MagicNumber:
    ignoreNumbers: ['-1', '0', '1', '2']
```

### SwiftLint (Swift)
```yaml
# .swiftlint.yml
disabled_rules:
  - trailing_whitespace
opt_in_rules:
  - force_unwrapping
  - implicitly_unwrapped_optional
  - private_over_fileprivate
  - closure_spacing
line_length:
  warning: 120
  error: 200
type_body_length:
  warning: 300
  error: 500
```

### RuboCop (Ruby)
```yaml
# .rubocop.yml
AllCops:
  NewCops: enable
  TargetRubyVersion: 3.3
Style/FrozenStringLiteralComment:
  Enabled: true
Metrics/MethodLength:
  Max: 20
Metrics/AbcSize:
  Max: 20
```

## PR Template

```markdown
## Description
<!-- What does this PR do? Link to the ticket/issue. -->

Closes #TICKET_NUMBER

## Changes
- [ ] Change 1
- [ ] Change 2

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Refactoring (no functional changes)
- [ ] Documentation update

## Testing
<!-- How was this tested? Include test commands, screenshots, etc. -->
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing performed

## Deployment Notes
<!-- Any special deployment steps, migrations, feature flags, env vars? -->

## Screenshots (if applicable)
<!-- Before/after for UI changes -->
```

## Common Code Smells with Refactoring Strategies

### Long Parameter List (> 3 parameters)
```typescript
// BAD
function createUser(name: string, email: string, role: string, department: string, managerId: string) { }

// GOOD -- introduce parameter object
interface CreateUserRequest { name: string; email: string; role: string; department: string; managerId: string; }
function createUser(request: CreateUserRequest) { }
```

### Boolean Parameters (flag arguments)
```python
# BAD -- caller cannot understand True/False without reading implementation
process_order(order, True, False)

# GOOD -- use named arguments or separate methods
process_order(order, expedited=True, gift_wrapped=False)
# or
process_expedited_order(order)
```

### Deeply Nested Conditionals
```go
// BAD -- deeply nested
func process(r Request) error {
    if r.IsValid() {
        if r.HasPermission() {
            if r.HasStock() {
                // actual logic buried here
            }
        }
    }
}

// GOOD -- guard clauses (early return)
func process(r Request) error {
    if !r.IsValid() { return ErrInvalidRequest }
    if !r.HasPermission() { return ErrForbidden }
    if !r.HasStock() { return ErrOutOfStock }
    // actual logic at top level
}
```

### Temporal Coupling (methods must be called in specific order)
```java
// BAD -- caller must know to call init() before process()
processor.init();
processor.loadConfig();
processor.process();

// GOOD -- constructor or factory handles initialization
var processor = Processor.create(config);
processor.process();
```

## Architecture Review
- [ ] Changes align with existing architecture patterns (hexagonal, clean, layered)
- [ ] No new coupling introduced between unrelated modules
- [ ] API contracts are backward compatible (or properly versioned with deprecation timeline)
- [ ] Database migrations are reversible and tested
- [ ] Configuration changes are documented in deployment notes
- [ ] Service boundaries respected -- no reaching into another service's database
- [ ] Dependency direction follows the dependency rule (inner layers don't depend on outer)
- [ ] Feature toggles in place for gradual rollout of significant changes

## Documentation Review
- [ ] Public APIs have clear documentation (JSDoc, docstrings, Javadoc, GoDoc)
- [ ] Breaking changes are noted in changelog with migration guide
- [ ] README is updated if setup steps, environment variables, or dependencies changed
- [ ] Complex algorithms have explanatory comments with references to design docs
- [ ] API documentation (OpenAPI, GraphQL schema) is updated and matches implementation
- [ ] Architecture Decision Records (ADRs) created for significant design choices
- [ ] Runbook updated if operational procedures changed

## Deployment Review
- [ ] Feature flags wrap new functionality if needed for gradual rollout
- [ ] Database migrations run before/after code deployment (order verified)
- [ ] Environment variables are documented and added to deployment config
- [ ] Monitoring/alerting is set up for new features (dashboards, alerts, SLOs)
- [ ] Rollback plan exists for critical changes -- tested in staging
- [ ] Backward compatibility maintained during rolling deployment (old + new code coexist)
- [ ] Load testing performed if change affects hot paths or introduces new endpoints
- [ ] Cache invalidation strategy considered if caching behavior changes
