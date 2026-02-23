# Conventional Commits

## When to load
Load when setting up commit conventions, automated changelogs, or semantic versioning.

## Commit Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Types

```
feat:     New feature (MINOR version bump)
fix:      Bug fix (PATCH version bump)
docs:     Documentation only
style:    Formatting, semicolons (no code change)
refactor: Code change that neither fixes nor adds feature
perf:     Performance improvement
test:     Adding or fixing tests
build:    Build system or dependencies
ci:       CI configuration
chore:    Other changes (no src or test)

BREAKING CHANGE: in footer → MAJOR version bump
feat!: or fix!: → shorthand for BREAKING CHANGE
```

## Examples

```bash
# Simple feature
feat: add user avatar upload

# Scoped fix
fix(auth): resolve token refresh race condition

# With body
feat(api): add pagination to user list endpoint

Implements cursor-based pagination for the /api/users endpoint.
Default page size is 20, maximum 100.

# Breaking change
feat(api)!: change authentication to Bearer tokens

BREAKING CHANGE: API now requires Bearer token in Authorization header.
Basic auth is no longer supported. Migrate by exchanging credentials
for a token via POST /api/auth/token.

Closes #234

# Multiple footers
fix(payments): handle failed webhook retry

Stripe webhooks were silently failing when the payment intent
had already been processed by a concurrent request.

Fixes #567
Reviewed-by: Alice
Co-Authored-By: Bob <bob@example.com>
```

## Semantic Versioning Integration

```
Commit type         → Version bump
fix: ...            → 1.0.0 → 1.0.1 (PATCH)
feat: ...           → 1.0.0 → 1.1.0 (MINOR)
BREAKING CHANGE     → 1.0.0 → 2.0.0 (MAJOR)

Pre-1.0.0 (0.x.x): breaking changes = MINOR bump
  feat!: ... → 0.1.0 → 0.2.0
```

## Tooling Setup

```json
// commitlint.config.js (enforce at commit time)
{
  "extends": ["@commitlint/config-conventional"],
  "rules": {
    "type-enum": [2, "always", [
      "feat", "fix", "docs", "style", "refactor",
      "perf", "test", "build", "ci", "chore"
    ]],
    "subject-max-length": [2, "always", 72],
    "body-max-line-length": [1, "always", 100]
  }
}
```

```json
// package.json — husky + commitlint
{
  "scripts": {
    "prepare": "husky"
  },
  "devDependencies": {
    "@commitlint/cli": "^19.0.0",
    "@commitlint/config-conventional": "^19.0.0",
    "husky": "^9.0.0"
  }
}
```

```bash
# .husky/commit-msg
npx --no -- commitlint --edit $1
```

## Automated Changelog

```bash
# Using semantic-release (fully automated)
# .releaserc.json
{
  "branches": ["main"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/changelog",
    "@semantic-release/npm",
    "@semantic-release/github",
    "@semantic-release/git"
  ]
}

# Or using standard-version (manual trigger)
npx standard-version              # auto-detect version bump
npx standard-version --release-as minor  # force minor
npx standard-version --first-release     # initial release
```

## Generated Changelog Example

```markdown
# Changelog

## [1.3.0] - 2024-02-15

### Features
- **api**: add pagination to user list endpoint (#234)
- **auth**: implement OAuth2 PKCE flow (#245)

### Bug Fixes
- **payments**: handle failed webhook retry (#567)
- **auth**: resolve token refresh race condition (#512)

### BREAKING CHANGES
- **api**: change authentication to Bearer tokens
```

## Anti-patterns
- Generic messages ("fix stuff", "updates", "WIP") → no traceability
- Mixing multiple changes in one commit → can't revert or bisect
- Not using scopes consistently → hard to filter changelogs
- Forgetting BREAKING CHANGE footer → wrong version bump

## Quick reference
```
Format: type(scope): description
Types: feat (MINOR), fix (PATCH), BREAKING CHANGE (MAJOR)
Scope: optional, component name (auth, api, ui)
Subject: imperative, lowercase, no period, ≤72 chars
Body: explain what and why, wrap at 100 chars
Footer: BREAKING CHANGE:, Fixes #N, Co-Authored-By:
Tooling: commitlint + husky (enforce), semantic-release (automate)
Changelog: auto-generated from commit types
```
