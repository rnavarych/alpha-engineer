# Pipeline Design Patterns

## When to load
Load when designing pipeline structure, stage ordering, optimization strategies, or environment promotion flows.

## Standard Pipeline
```
Code Push → Lint → Build → Unit Test → Integration Test → Security Scan → Deploy Staging → E2E Test → Deploy Production
```

## Pipeline Principles
- **Fail fast**: Run fastest checks first (lint 30s, unit tests 2m) before slow checks (integration 5m, E2E 10m)
- **Parallelize independent stages**: Lint, type-check, and unit tests can run simultaneously
- **Artifact-based promotion**: Build once, deploy the same artifact to every environment
- **Immutable artifacts**: Never modify after build — tag with git SHA, sign for verification
- **Environment parity**: Staging mirrors production in infrastructure, data volume, and configuration
- **Deterministic builds**: Pin dependency versions, use lockfiles, reproducible container builds

## Pipeline Design Patterns

### Sequential (Simple)
```
Lint → Build → Test → Deploy
```
Best for: Small projects, single service, fast test suites.

### Fan-Out / Fan-In
```
         ┌─ Lint ──────┐
Build ───┼─ Unit Test ──┼─── Integration Test → Deploy
         └─ Type Check ─┘
```
Best for: Multiple independent validation steps that can run in parallel.

### Diamond
```
         ┌─ Build Frontend ─┐
Checkout ┤                  ├─ Integration Test → Deploy
         └─ Build Backend  ─┘
```
Best for: Multi-component applications (frontend + backend).

### Matrix Builds
```
Build × [Node 18, 20, 22] × [ubuntu, macos, windows]
```
Best for: Libraries and SDKs that must work across multiple platforms/versions.

## Per-Stage Best Practices

| Stage | Duration Target | What to Check | Failure Action |
|-------|----------------|---------------|----------------|
| **Lint/Format** | < 30s | Code style, import order, formatting | Block merge |
| **Type Check** | < 1m | Type errors, unused exports | Block merge |
| **Unit Test** | < 3m | Logic correctness, edge cases | Block merge |
| **Build** | < 5m | Compilation, bundling, asset generation | Block merge |
| **Integration Test** | < 10m | DB queries, API contracts, service boundaries | Block merge |
| **Security Scan** | < 5m | SAST, SCA, secret detection | Block merge (critical), warn (medium) |
| **E2E Test** | < 15m | Critical user flows, smoke tests | Block deploy (not merge) |
| **Deploy Staging** | < 5m | Infrastructure provisioning, health checks | Block production deploy |
| **Deploy Production** | < 10m | Rolling update, health checks, smoke tests | Auto-rollback |

## Pipeline Optimization

### Caching Strategies
```yaml
# GitHub Actions -- dependency caching
- uses: actions/cache@v4
  with:
    path: |
      node_modules
      ~/.cache/pip
      ~/.gradle/caches
    key: ${{ runner.os }}-deps-${{ hashFiles('**/package-lock.json', '**/requirements.txt') }}
    restore-keys: ${{ runner.os }}-deps-

# Docker layer caching
- uses: docker/build-push-action@v5
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

### Build Skip Conditions
```yaml
on:
  push:
    paths-ignore:
      - '**.md'
      - 'docs/**'

if: "!contains(github.event.head_commit.message, '[skip ci]')"
```

### Incremental Builds
- **TypeScript**: `tsc --incremental`, `tsconfig.tsBuildInfoFile`
- **Gradle**: Build cache, incremental compilation, configuration cache
- **Rust**: `cargo build` with sccache for distributed caching
- **Docker**: Multi-stage builds with layer caching, `--cache-from`

## Environment Strategy

```
Local → Dev → Staging → Preview (per-PR) → Production
```

- **Local**: Docker-compose, hot reload, mock external services
- **Dev**: Shared, frequent deploys, relaxed stability
- **Staging**: Production mirror, same infrastructure, anonymized data volume
- **Preview (per-PR)**: Ephemeral environments per pull request for review
- **Production**: Live traffic, monitored, SLO-bound, change management
