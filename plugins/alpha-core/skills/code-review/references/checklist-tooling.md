# Security Vulnerability Patterns, Linting Configs, and PR Templates

## When to load
Load when checking language-specific security vulnerabilities, configuring linters (ESLint, Ruff, golangci-lint, Clippy, Detekt), reviewing database migrations, API contracts, deployment checklists, or using the PR template.

## Security Vulnerability Patterns by Language

### TypeScript/JavaScript
- **Prototype pollution**: `merge(target, userInput)` modifying `Object.prototype` — use `Object.create(null)`
- **ReDoS**: Regex with nested quantifiers on user input `/(a+)+$/` — use `re2` library
- **Path traversal**: `fs.readFile(userInput)` — validate against allowlist, use `path.resolve` + prefix check
- **SSRF**: `fetch(userProvidedUrl)` — validate URL scheme and host against allowlist

### Python
- **Unsafe deserialization**: Loading untrusted binary-serialized objects — use JSON instead
- **YAML deserialization**: `yaml.load(data)` — always use `yaml.safe_load()`
- **Command injection**: Spawning shell with user input — use `subprocess.run([cmd, arg], shell=False)`
- **Template injection**: `template.render(user_string)` in Jinja2 — use sandboxed environment

### Go
- **SQL injection**: `fmt.Sprintf("SELECT...%s", id)` — use `db.Query("...WHERE id = $1", id)`
- **Path traversal**: Check result starts with base after `filepath.Clean(filepath.Join(base, input))`
- **Goroutine leak**: Missing `context.Cancel()` — always `defer cancel()` after `context.WithCancel`

### Java
- **Deserialization**: `ObjectInputStream.readObject()` — use allowlist filter or avoid Java serialization
- **XXE**: XML parsing without disabling external entities — `factory.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true)`
- **SSRF**: `new URL(userInput).openConnection()` — validate host, scheme, port

### Rust
- **Unsafe blocks**: Review all `unsafe` for undefined behavior — use `miri` to check
- **Integer overflow**: Release builds wrap by default — use `checked_add`, `saturating_add` for critical math

## Linting Tool Configurations

### ESLint (TypeScript/JavaScript)
```json
{
  "extends": ["eslint:recommended", "plugin:@typescript-eslint/strict-type-checked"],
  "rules": {
    "no-console": "warn",
    "@typescript-eslint/no-unused-vars": ["error", { "argsIgnorePattern": "^_" }],
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/strict-boolean-expressions": "error"
  }
}
```

### Ruff (Python)
```toml
[tool.ruff]
target-version = "py312"
line-length = 100
[tool.ruff.lint]
select = ["E", "F", "W", "I", "N", "UP", "S", "B", "A", "C4", "SIM", "TCH", "RUF"]
[tool.ruff.lint.per-file-ignores]
"tests/**" = ["S101"]  # allow assert in tests
```

### golangci-lint (Go)
```yaml
linters:
  enable: [errcheck, govet, staticcheck, unused, gosec, gocritic, gofumpt, exhaustive]
linters-settings:
  govet:
    check-shadowing: true
  errcheck:
    check-type-assertions: true
```

### Clippy (Rust)
```toml
[lints.clippy]
all = "warn"
pedantic = "warn"
unwrap_used = "deny"
```

### Detekt (Kotlin)
```yaml
complexity:
  LongMethod:
    threshold: 30
  ComplexMethod:
    threshold: 15
style:
  MagicNumber:
    ignoreNumbers: ['-1', '0', '1', '2']
```

## Database Migration Review
- [ ] Migration has a corresponding rollback and rollback has been tested
- [ ] No `DROP TABLE` or `DROP COLUMN` without confirmed backup
- [ ] Index creation uses `CONCURRENTLY` (PostgreSQL) for zero-downtime
- [ ] New columns have `DEFAULT` values or are nullable
- [ ] Data migrations separated from schema migrations — run in distinct deployment steps
- [ ] Migration is idempotent — can be safely re-run without error
- [ ] Performance tested on a dataset approximating production size

## API Contract Review
- [ ] OpenAPI/GraphQL schema updated to match implementation
- [ ] No breaking changes to response structure (removed fields, type changes)
- [ ] Deprecation warnings added for fields/endpoints being phased out
- [ ] Consumer contract tests updated (Pact, Spring Cloud Contract)

## PR Template
```markdown
## Description
Closes #TICKET_NUMBER

## Changes
- [ ] Change 1

## Type of Change
- [ ] Bug fix  [ ] New feature  [ ] Breaking change  [ ] Refactoring  [ ] Docs

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing performed

## Deployment Notes
<!-- Migrations, feature flags, env vars, special steps -->
```

## Deployment Review
- [ ] Feature flags wrap new functionality for gradual rollout
- [ ] Database migrations run before/after code deployment (order verified)
- [ ] Monitoring/alerting set up for new features (dashboards, alerts, SLOs)
- [ ] Rollback plan exists and tested in staging
- [ ] Backward compatibility maintained during rolling deployment
