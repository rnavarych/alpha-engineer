# Feature Flags and Release Management

## When to load
Load when implementing feature flags, setting up gradual rollouts, managing semantic versioning, or automating releases.

## Feature Flag Architecture

### Evaluation Engine
```typescript
interface FeatureFlag {
  key: string;
  defaultValue: boolean;
  rules: TargetingRule[];
  percentageRollout?: { percentage: number; attribute: string };
  killSwitch: boolean;  // override -- always off when true
}

// Evaluation order:
// 1. Kill switch (if true, always return false)
// 2. User targeting rules (specific users/segments)
// 3. Percentage rollout (gradual rollout by user attribute hash)
// 4. Default value
```

### Flag Lifecycle
1. **Created**: Flag defined with `defaultValue: false`, no targeting rules
2. **Development**: Enabled for developers and QA via targeting rules
3. **Staging**: Enabled in staging environment for validation
4. **Gradual rollout**: 5% -> 25% -> 50% -> 100% in production
5. **Fully launched**: Flag permanently `true`, code path is the default
6. **Cleanup**: Remove flag checks from code, delete flag definition

### Feature Flag Tools

| Tool | Hosting | Pricing Model | Key Features |
|------|---------|---------------|-------------|
| **LaunchDarkly** | SaaS | Per-seat + MAU | Enterprise, SDKs for 25+ languages, experimentation |
| **Unleash** | Self-hosted or SaaS | Open-source core | Strategy types, constraints, variants, K8s operator |
| **Flagsmith** | Self-hosted or SaaS | Open-source core | Remote config, A/B testing, audit logs |
| **ConfigCat** | SaaS | Per-config reads | Simple, percentage rollout, targeting, webhooks |
| **OpenFeature** | Standard | N/A (spec only) | Vendor-neutral SDK spec, provider pattern, hooks |
| **Statsig** | SaaS | Per-event | Feature gates, experiments, metrics, warehouse-native |
| **Custom** | Self-hosted | Engineering cost | Database/Redis-backed, simple but limited |

### Kill Switch Pattern
- Every feature flag should have a kill switch capability
- Kill switch must be evaluable without network call (cached locally)
- Test kill switch behavior in staging before production launch
- Document kill switch procedures in runbooks

## Monorepo CI/CD

### Tool Comparison

| Tool | Language | Affected Detection | Remote Cache | Task Orchestration |
|------|----------|-------------------|--------------|-------------------|
| **Turborepo** | JS/TS | Hash-based, git diff | Vercel Remote Cache | Topological, parallel |
| **Nx** | JS/TS (+ plugins) | Dependency graph, git diff | Nx Cloud | Distributed task execution |
| **Bazel** | Multi-language | Hermetic, content-addressable | Remote execution | Fine-grained, parallel |
| **Moon** | JS/TS, Rust | Hash-based | moonbase | Topological, parallel |

### Affected Detection
```bash
npx turbo run build test --filter=...[HEAD~1]
npx nx affected --target=build --base=origin/main --head=HEAD
```

## Semantic Versioning
- `MAJOR.MINOR.PATCH` — `2.1.0`
- **MAJOR**: Breaking changes (API incompatibility)
- **MINOR**: New features (backward-compatible)
- **PATCH**: Bug fixes (backward-compatible)
- Pre-release: `2.1.0-beta.1`, `2.1.0-rc.1`

## Release Automation Tools

| Tool | Ecosystem | Versioning | Changelog |
|------|-----------|-----------|-----------|
| **semantic-release** | npm (any language via plugins) | Conventional Commits | Auto-generated from commits |
| **changesets** | npm monorepos | Manual version bumps | Aggregated from changeset descriptions |
| **release-please** | GitHub-native | Conventional Commits | Auto-generated PR with changelog |
| **goreleaser** | Go | Git tags | Auto-generated |
| **cargo-release** | Rust | Cargo.toml version | Changelog updates |

## Conventional Commits
```
feat: add user registration endpoint
fix: prevent duplicate email registration
perf: optimize user search query with index
refactor!: rename UserService to AccountService

BREAKING CHANGE: UserService has been renamed to AccountService
```

- Commit types: `feat`, `fix`, `perf`, `docs`, `refactor`, `test`, `chore`, `ci`, `build`
- `!` after type indicates breaking change
- Automated version bumping: `feat` -> minor, `fix` -> patch, `BREAKING CHANGE` -> major
- Enforced with commitlint in pre-commit hook or CI
