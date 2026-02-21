# Code Review Detailed Checklist

## Language-Specific Checks

### TypeScript/JavaScript
- Strict mode enabled, no `any` types without justification
- Proper null/undefined handling (optional chaining, nullish coalescing)
- Async/await used consistently (no mixing with .then chains)
- Proper error handling in async functions
- No prototype pollution risks
- Dependencies imported correctly (no circular imports)

### Python
- Type hints on function signatures
- Context managers for resources (files, connections)
- List comprehensions over loops where readable
- f-strings over format() or %
- Proper exception handling (specific exceptions, not bare except)

### Go
- Errors are checked and handled (not ignored with `_`)
- Context is propagated for cancellation
- Goroutine leaks are prevented
- Interfaces are small and focused
- defer for cleanup operations

### Java/Kotlin
- Null safety (Optional in Java, nullable types in Kotlin)
- Resource management (try-with-resources)
- Thread safety for shared state
- Proper exception hierarchy
- Builder pattern for complex object construction

## Architecture Review
- [ ] Changes align with existing architecture patterns
- [ ] No new coupling introduced between unrelated modules
- [ ] API contracts are backward compatible (or versioned)
- [ ] Database migrations are reversible
- [ ] Configuration changes are documented

## Documentation Review
- [ ] Public APIs have clear documentation
- [ ] Breaking changes are noted in changelog
- [ ] README is updated if setup steps changed
- [ ] Complex algorithms have explanatory comments
- [ ] API documentation (OpenAPI, GraphQL schema) is updated

## Deployment Review
- [ ] Feature flags wrap new functionality if needed
- [ ] Database migrations run before/after code deployment (order correct)
- [ ] Environment variables are documented
- [ ] Monitoring/alerting is set up for new features
- [ ] Rollback plan exists for critical changes
