# Code Smells, Performance Patterns, and Concurrency Review

## When to load
Load when identifying code smells, analyzing performance issues, reviewing concurrent code, assessing automated tooling choices, or applying refactoring strategies.

## Code Smell Catalog

| Smell | Symptom | Refactoring |
|-------|---------|-------------|
| **Long Method** | Function > 30 lines, multiple responsibilities | Extract Method, decompose into helpers |
| **Feature Envy** | Method uses more data from another class than its own | Move Method to the class it envies |
| **God Class** | Class with 500+ lines, 20+ methods, knows too much | Extract Class, apply SRP |
| **Shotgun Surgery** | One change requires edits in 5+ files | Move related logic together, consolidate |
| **Primitive Obsession** | Using strings for emails, money, phone numbers | Extract Value Object (Email, Money) |
| **Data Clumps** | Same 3+ params passed together to multiple functions | Extract Parameter Object |
| **Speculative Generality** | Abstractions with only one implementation | Inline Class, YAGNI |
| **Dead Code** | Unreachable code, unused variables, commented-out blocks | Delete it — version control has history |

## Security Review — OWASP Top 10 Table

| # | Vulnerability | What to Check |
|---|---------------|---------------|
| A01 | Broken Access Control | IDOR without authz, path traversal (`../`), metadata manipulation |
| A02 | Cryptographic Failures | Weak algorithms (MD5, SHA1), hardcoded keys, missing TLS, PII in logs |
| A03 | Injection | SQL/NoSQL injection, LDAP, OS command, template injection, XSS |
| A04 | Insecure Design | Missing rate limiting on auth, business logic flaws, no abuse cases |
| A05 | Security Misconfiguration | Default credentials, verbose errors in production, missing security headers |
| A06 | Vulnerable Components | Outdated dependencies with known CVEs, unpinned versions |
| A07 | Auth Failures | Credential stuffing susceptibility, weak password policy, session fixation |
| A10 | SSRF | Unvalidated URL fetching, internal IP access, cloud metadata (169.254.169.254) |

### Auth Bypass Patterns to Watch For
- Missing authorization check on newly added endpoints
- IDOR: `/api/users/123/orders` accessible by user 456 without ownership check
- JWT `alg: none` accepted by verification logic
- Role escalation via mass assignment (`{ "role": "admin" }` in request body)

## Performance Review Patterns

### Hot Path Analysis
- Identify the critical execution path for the most common request
- Profile before optimizing — don't guess where bottlenecks are
- Look for O(n^2) or worse algorithms operating on unbounded input

### Memory Leak Indicators
- Event listeners added without corresponding removal
- Growing caches without eviction policy or TTL
- Goroutines/threads spawned without lifecycle management
- Subscriptions (RxJS, Kafka consumers) not unsubscribed on cleanup

### Unnecessary Allocations
- String concatenation in loops — use StringBuilder (Java), strings.Builder (Go), join (Python)
- Copying large structs instead of passing pointers (Go, Rust)

## Concurrency Review

### General Patterns
- [ ] Shared mutable state protected by locks, atomics, or message passing
- [ ] No TOCTOU races — check-then-act must be atomic
- [ ] Deadlock potential analyzed — locks acquired in consistent order, timeouts in place

### Language-Specific Concurrency

| Language | Common Issues | Safe Patterns |
|----------|---------------|---------------|
| **Go** | Goroutine leak, data race on shared map, channel deadlock | `sync.Mutex`, `sync.WaitGroup`, `context.WithCancel` |
| **Java** | Unsynchronized HashMap, missing volatile, thread pool exhaustion | `ConcurrentHashMap`, `AtomicReference`, `CompletableFuture` |
| **TypeScript** | `Promise.all` unhandled rejection, event loop blocking | `Promise.allSettled`, worker threads for CPU |
| **Python** | GIL misconceptions, asyncio event loop blocking | `asyncio.Lock`, `threading.Lock`, `queue.Queue` |
| **Rust** | Deadlock with nested Mutex, Arc<Mutex> contention | `tokio::sync::Mutex`, `RwLock`, channels (`mpsc`) |
| **.NET** | async void, `Task.Result` deadlock | `SemaphoreSlim`, `Channel<T>`, `async`/`await` all the way |

## Automated Review Tools

| Tool | Languages | Focus |
|------|-----------|-------|
| **SonarQube / SonarCloud** | 30+ languages | Code quality, security, duplication, complexity |
| **ESLint** | JavaScript, TypeScript | Linting, formatting, best practices |
| **Pylint / Ruff** | Python | Linting, type checking, import sorting |
| **golangci-lint** | Go | Meta-linter (50+ linters), unused, errcheck, govet |
| **Clippy** | Rust | Idiomatic Rust, performance, correctness |
| **Semgrep** | Multi-language | Security patterns, custom rules, OWASP |

## PR Size Guidelines
- **Ideal**: < 200 lines changed (reviewable in one session)
- **Acceptable**: 200-400 lines (may need multiple passes)
- **Too large**: > 400 lines — request splitting into stacked PRs
- Exception: auto-generated code, migrations, dependency lockfiles
