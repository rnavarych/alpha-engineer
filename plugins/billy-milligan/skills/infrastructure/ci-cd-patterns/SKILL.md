---
name: ci-cd-patterns
description: |
  CI/CD patterns: GitHub Actions production config with parallel jobs, test sharding (4 shards),
  Docker layer caching, OIDC for cloud auth (no long-lived secrets), deployment workflows,
  branch strategies, rollback procedures. DORA metrics targets.
  Use when designing CI/CD pipelines, optimizing build times, implementing deployments.
allowed-tools: Read, Grep, Glob
---

# CI/CD Patterns

## When to Use This Skill
- Designing GitHub Actions workflows from scratch
- Optimizing slow CI pipelines (target: <10 minutes)
- Implementing secure cloud deployments without long-lived credentials
- Test parallelization and sharding
- Deployment strategies and rollback procedures

## Core Principles

1. **CI pipeline target: under 10 minutes** — slower pipelines get skipped, not fixed
2. **OIDC for cloud auth** — no long-lived secrets in CI environment variables
3. **Fail fast** — lint before tests, type-check before expensive tests
4. **Test sharding** — 4 shards typically brings 4× speedup on 4 CPU runners
5. **Separate build and deploy** — build once, deploy artifact multiple times

---

## Patterns ✅

### Production GitHub Actions Workflow

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true  # Cancel outdated runs on new push

jobs:
  # Fast checks first — fail early
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'pnpm' }
      - run: pnpm install --frozen-lockfile
      - run: pnpm lint
      - run: pnpm typecheck

  # Unit tests — parallelized
  test-unit:
    runs-on: ubuntu-latest
    needs: [lint]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'pnpm' }
      - run: pnpm install --frozen-lockfile
      - run: pnpm test:unit --coverage
      - uses: actions/upload-artifact@v4
        with:
          name: coverage
          path: coverage/

  # Integration tests with sharding
  test-integration:
    runs-on: ubuntu-latest
    needs: [lint]
    strategy:
      matrix:
        shard: [1, 2, 3, 4]  # 4 parallel shards
    services:
      postgres:
        image: postgres:16
        env: { POSTGRES_DB: test, POSTGRES_PASSWORD: test }
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-retries 5
      redis:
        image: redis:7
        options: --health-cmd "redis-cli ping"
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'pnpm' }
      - run: pnpm install --frozen-lockfile
      - run: pnpm test:integration --shard=${{ matrix.shard }}/4
        env:
          DATABASE_URL: postgresql://postgres:test@localhost/test
          REDIS_URL: redis://localhost:6379

  # Build Docker image (after tests pass)
  build:
    runs-on: ubuntu-latest
    needs: [test-unit, test-integration]
    permissions:
      id-token: write   # OIDC
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v5
        with:
          push: ${{ github.ref == 'refs/heads/main' }}
          tags: ghcr.io/${{ github.repository }}:${{ github.sha }}
          cache-from: type=gha          # GitHub Actions cache
          cache-to: type=gha,mode=max

  # Deploy to staging (on main only)
  deploy-staging:
    runs-on: ubuntu-latest
    needs: [build]
    if: github.ref == 'refs/heads/main'
    environment: staging
    permissions:
      id-token: write  # OIDC for AWS
      contents: read
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789:role/github-actions-staging
          aws-region: us-east-1
          # No long-lived AWS_ACCESS_KEY_ID needed — OIDC token exchange
      - run: |
          aws ecs update-service \
            --cluster staging \
            --service myapp \
            --force-new-deployment \
            --task-definition myapp:$(aws ecs describe-task-definition \
              --task-definition myapp --query 'taskDefinition.revision')
```

### OIDC Cloud Authentication (No Long-Lived Secrets)

```yaml
# Configure AWS role to trust GitHub Actions OIDC
# In Terraform:
resource "aws_iam_role" "github_actions" {
  name = "github-actions-deploy"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:myorg/myrepo:ref:refs/heads/main"
        }
      }
    }]
  })
}
```

```yaml
# GitHub Actions step — no AWS keys in secrets
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789:role/github-actions-deploy
    aws-region: us-east-1
```

**Why OIDC**: No credentials to rotate, no credentials to leak, short-lived tokens (1h), per-repo and per-branch scoping.

### Docker Build Caching

```dockerfile
# Multi-stage build with optimal layer ordering
# Most-changing layers last = better cache hits

FROM node:20-alpine AS base
WORKDIR /app
# Layer 1: Install dependencies (slow, rarely changes)
COPY package.json pnpm-lock.yaml ./
RUN npm install -g pnpm && pnpm install --frozen-lockfile

FROM base AS builder
# Layer 2: Build (source code changes often, but deps cached)
COPY . .
RUN pnpm build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
# Layer 3: Production dependencies only
COPY package.json pnpm-lock.yaml ./
RUN npm install -g pnpm && pnpm install --frozen-lockfile --prod

COPY --from=builder /app/dist ./dist
USER node
EXPOSE 3000
CMD ["node", "dist/server.js"]
```

```yaml
# GitHub Actions cache config
- uses: docker/build-push-action@v5
  with:
    cache-from: type=gha                 # Load from cache
    cache-to: type=gha,mode=max          # Save all layers
    # Alternative: registry cache
    # cache-from: type=registry,ref=ghcr.io/myorg/myapp:buildcache
    # cache-to: type=registry,ref=ghcr.io/myorg/myapp:buildcache,mode=max
```

---

## Anti-Patterns ❌

### Long-Lived Cloud Credentials in CI
**What it is**: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` stored as GitHub secrets.
**What breaks**: Credentials never rotate. If leaked (e.g., printed in logs, compromised repo), attacker has permanent access until manually rotated.
**Fix**: OIDC — tokens are generated per-workflow-run and expire in 1 hour.

### No Concurrency Cancellation
**What it is**: Every push triggers a CI run. 5 rapid pushes = 5 concurrent CI runs.
**What breaks**: Wastes runner minutes. Old runs complete after new ones. Multiple concurrent deploys possible.
**Fix**: `concurrency: cancel-in-progress: true` — only the latest run matters.

### Sequential Jobs When Parallel Is Possible
**What it is**: lint → typecheck → unit tests → integration tests → build (all sequential).
**What breaks**: 2-minute lint blocks 15-minute integration tests. Total time = sum of all times.
**Fix**: Run lint and tests in parallel where dependencies allow. `needs:` only what actually depends on the previous step.

### No Test Result Caching
**What it is**: Re-running all tests even when source files haven't changed.
**What breaks**: Full CI run on documentation-only changes. Wasted time.
**Fix**: Paths filtering: `on: push: paths: ['src/**', 'tests/**', 'package.json']` to skip CI for docs changes.

---

## DORA Metrics Targets

```
Elite performers (industry benchmark):
  Deployment frequency:  Multiple times per day
  Lead time for changes: Less than 1 hour
  MTTR:                  Less than 1 hour
  Change failure rate:   Less than 5%

Good targets for most teams:
  Deployment frequency:  Multiple times per week
  Lead time for changes: Less than 1 day
  MTTR:                  Less than 1 day
  Change failure rate:   Less than 15%
```

## Quick Reference

```
CI target time: under 10 minutes total
Test sharding: 4 shards = 4× speedup on 4-CPU runners
OIDC: no long-lived credentials, tokens expire in 1h
Docker cache: type=gha for GitHub Actions, type=registry for external
Concurrency: cancel-in-progress: true on all workflows
Fail fast: lint/typecheck before tests (seconds vs minutes)
Build once: build Docker image once, promote artifact through environments
```
