# Testing Pyramid

## When to load
Load when discussing test layer distribution, evaluating why a test suite is slow, or justifying
test investment to stakeholders.

## The Pyramid

```
              /\
             /E2E\           2–10% of tests
            /─────\          <30s each | run on main branch + nightly
           /  Integ \        20–30% of tests
          /──────────\       <500ms each | run on every PR
         / Unit Tests \      60–80% of tests
        /──────────────\     <5ms each | run on every file save
```

The pyramid shape is intentional: wide base of fast tests, narrow top of slow tests.
Ice cream cone (inverted pyramid, lots of E2E) = slow CI, flaky tests, expensive maintenance.

## Layer Definitions and Boundaries

| Layer | Tests | Scope | Speed | Cost to maintain |
|-------|-------|-------|-------|-----------------|
| Unit | Pure functions, isolated classes | Single function/class | <5ms | Low |
| Integration | Service + DB, service + external API | Multiple real components | <500ms | Medium |
| E2E | Full user journey through UI | Entire system | <30s | High |
| Contract | API shape between services | Network boundary | <200ms | Medium |

### Unit test: what qualifies
- No file I/O, no network, no database
- No `setTimeout` or real timers
- Deterministic: same input = same output, always
- All dependencies are injected (or pure functions need no injection)

### Integration test: what qualifies
- Uses a real database (Testcontainers or CI service container)
- Tests an HTTP handler end-to-end through the stack (without UI)
- Verifies that a queue consumer processes a message correctly
- Does NOT mock the database — mocking DB in integration tests defeats the purpose

### E2E test: what qualifies
- Uses a real browser (Playwright, Cypress)
- Tests a complete user journey (register → verify email → purchase → receive receipt)
- Covers critical happy paths only — not every edge case
- Should NOT be written for every feature

## Coverage Targets by Layer

```
Business logic (domain services, use cases):     >90% line, >80% branch
Data access layer (repositories):               >80% line
HTTP handlers / controllers:                    >70% line
UI components:                                  >60% line
Third-party integrations (Stripe, AWS, etc.):   Contract tests only — not unit/integration
Generated code (Prisma client, OpenAPI types):  0% — never test generated code
Migration files:                                0% — tested by running them
```

## Anti-patterns

**Ice cream cone (inverted pyramid)**
Too many E2E, too few unit tests. Suite takes 45 minutes. Every UI refactor breaks 30 tests.
Fix: add unit tests for all business logic, delete redundant E2E that duplicate lower-level tests.

**Trophy shape (integration-heavy)**
Popularized as "test trophy" — mostly integration tests. Works well for API-first applications.
Not wrong, but integration tests are slower — watch your total CI time.

**Hourglass (many unit + many E2E, no integration)**
Unit tests pass, E2E tests pass, but system integration is broken because nobody tests the
middle layer. Common in teams that fear database tests.
Fix: Testcontainers — real DB in integration tests, no SQLite shortcuts.

## Quick reference

```
Unit     : <5ms, no I/O, deterministic, run on save
Integr.  : <500ms, real DB/queue, run on PR
E2E      : <30s, real browser, run on main branch
Contract : <200ms, API shape only, run on PR affecting API consumers

Ratios   : 70% unit / 20% integration / 8% e2e / 2% contract (rough guide)
When to skip / cost per test : see test-selection.md
```
