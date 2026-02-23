# Review Process, Checklists, and Communication

## When to load
Load when conducting a code review, establishing review standards, or needing the core review checklists for correctness, security, performance, maintainability, testing, and API/database changes.

## Review Priorities (ordered)

1. **Correctness**: Does the code do what it's supposed to? Check logic, edge cases, error handling failure modes.
2. **Security**: Injection, auth bypass, data exposure, SSRF, insecure deserialization, path traversal.
3. **Performance**: N+1 queries, memory leaks, missing pagination, unindexed queries.
4. **Maintainability**: Single responsibility, clear naming, minimal coupling, appropriate abstraction.
5. **Testing**: Critical paths tested, meaningful assertions, edge cases covered.
6. **Style**: Follows project conventions. Automate with tooling rather than manual review.

## Core Checklist

### Correctness
- [ ] Edge cases handled (null, empty, boundary values, negative numbers, empty strings vs null)
- [ ] Error handling appropriate — not swallowed, not over-caught with generic `catch (Exception e)`
- [ ] Async operations properly awaited — no fire-and-forget without explicit justification
- [ ] Race conditions addressed in concurrent code
- [ ] Off-by-one errors checked in loops, slices, pagination boundaries
- [ ] Return values checked — especially for operations that can fail silently
- [ ] Backwards compatibility preserved — callers of modified functions still work correctly

### Security
- [ ] User input validated and sanitized at the boundary (server-side, not just client-side)
- [ ] Database queries use parameterized statements — no string interpolation in SQL
- [ ] Auth enforced on every endpoint — no reliance on client-side checks
- [ ] Sensitive data not logged, not in error responses, not stored in plain text
- [ ] CORS configured restrictively — no wildcard origins in production
- [ ] No hardcoded secrets, API keys, or credentials

### Performance
- [ ] No N+1 database queries — use eager loading, JOINs, or DataLoader
- [ ] Large datasets paginated — cursor-based preferred for feeds, offset for admin panels
- [ ] Database indexes exist for query patterns introduced by this change
- [ ] No synchronous I/O on hot paths — use async operations for file, network, DB access
- [ ] Regex patterns not vulnerable to ReDoS (catastrophic backtracking)

### Maintainability
- [ ] Functions have single responsibility — does one thing well
- [ ] Names clearly convey intent — `calculateOrderTotal` not `calc`
- [ ] No magic numbers or hardcoded strings — extract to named constants
- [ ] DRY without over-abstraction — duplication is better than the wrong abstraction
- [ ] Feature flags wrap new behavior when rolling out incrementally

### Testing
- [ ] New functionality has tests — unit for logic, integration for boundaries
- [ ] Edge cases tested — nulls, empty collections, boundary values, error paths
- [ ] Tests are readable — clear arrange/act/assert, descriptive names
- [ ] No test interdependence — each test can run independently in any order
- [ ] Regression tests for bugs — if fixing a bug, add a test that would have caught it

## API Review Checklist
- [ ] Backward compatibility: no breaking changes without versioned migration
- [ ] Error responses: consistent format (RFC 9457 Problem Details), meaningful error codes
- [ ] Pagination implemented for all list endpoints
- [ ] Rate limiting headers present (`RateLimit-Limit`, `RateLimit-Remaining`, `RateLimit-Reset`)
- [ ] Idempotency keys supported for POST/PUT safe retries

## Database Review Checklist
- [ ] Migration has a corresponding rollback (`down` migration)
- [ ] No destructive operations without data backup verification
- [ ] `ALTER TABLE` on large tables uses online DDL (gh-ost, pt-online-schema-change, pgroll)
- [ ] Index creation uses `CONCURRENTLY` (PostgreSQL) for zero-downtime
- [ ] Transaction boundaries: operations that must be atomic are wrapped in transactions

## Review Communication

### Comment Prefixes
- `[blocker]` — Must fix before merge. Security, correctness, data integrity issues.
- `[suggestion]` — Would improve the code but not blocking.
- `[nit]` — Trivial style or naming preference. Author's discretion.
- `[question]` — Seeking understanding. May reveal an issue.
- `[praise]` — Highlighting good work. Reinforces positive patterns.

### What NOT to Do
- Don't bikeshed on style that linters can catch automatically
- Don't rewrite the PR in comments — if that much needs to change, pair instead
- Don't approve with unresolved blockers
