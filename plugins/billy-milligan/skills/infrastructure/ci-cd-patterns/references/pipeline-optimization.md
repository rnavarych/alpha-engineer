# Pipeline Optimization

## Parallel Jobs

Split work across multiple runners for linear speedup:

```yaml
# GitHub Actions: parallel test shards
test:
  strategy:
    matrix:
      shard: [1, 2, 3, 4]
  steps:
    - run: npx jest --shard=${{ matrix.shard }}/4
```

Expected improvement: **N shards = ~Nx faster** (minus overhead ~30s per shard).

## Test Splitting Strategies

| Strategy | Best for | Tool |
|---|---|---|
| File-based sharding | Unit tests | Jest `--shard`, pytest-split |
| Timing-based | Balanced shards | CircleCI test splitting, Knapsack |
| Changed-file detection | Large monorepos | `nx affected`, Turborepo `--filter` |

```bash
# Timing-based with Jest
# Step 1: generate timing data
npx jest --json --outputFile=test-results.json
# Step 2: split by timing
npx jest --shard=1/4 --testPathPattern=$(cat shard-1-files.txt)
```

## Artifact Caching

Layer caching by change frequency:

```yaml
# Slow-changing (weekly): OS packages, base images
# Medium (daily): node_modules, pip packages
# Fast (per-commit): build outputs, .next/cache

cache:
  paths:
    - node_modules/
    - .next/cache/
  key:
    files:
      - package-lock.json  # Invalidate on lockfile change
```

Cache hit saves **1-5 minutes** per job. Target: **>90% hit rate**.

## Incremental Builds

```bash
# Turborepo: only rebuild changed packages
npx turbo run build --filter='...[HEAD~1]'

# Nx: affected projects only
npx nx affected --target=build --base=main

# Gradle: built-in incremental
./gradlew build --build-cache
```

Monorepo savings: **60-80%** of build time on typical PRs.

## Build Matrix Optimization

```yaml
# Run full matrix on main, reduced on PRs
strategy:
  matrix:
    node: ${{ github.ref == 'refs/heads/main'
      && fromJSON('[18,20,22]')
      || fromJSON('[20]') }}
    os: ${{ github.ref == 'refs/heads/main'
      && fromJSON('["ubuntu-latest","macos-latest"]')
      || fromJSON('["ubuntu-latest"]') }}
```

## Decision Criteria

| Symptom | Solution |
|---|---|
| Pipeline > 15 min | Add parallelism, enable caching |
| Flaky tests blocking deploy | Quarantine flaky tests, add retries (max 2) |
| Redundant builds on every push | Use path filters or `[skip ci]` |
| Slow Docker builds | Multi-stage + BuildKit cache mount |
| Full test suite on typo fix | Path-based job triggers |

## Quick Reference

- Target pipeline time: **< 10 minutes** for PR checks
- Cache warming: run on `main` merges to pre-warm caches
- Retry budget: max **2 retries** per flaky job before quarantine
- Artifact size: keep under **100 MB** for fast upload/download
- Monorepo: use `nx affected` or `turbo --filter` to skip unchanged packages
