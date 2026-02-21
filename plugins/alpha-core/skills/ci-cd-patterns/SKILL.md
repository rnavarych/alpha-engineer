---
name: ci-cd-patterns
description: |
  Designs CI/CD pipelines: build, test, deploy stages, blue-green/canary/rolling deployments,
  feature flags, artifact management, and environment promotion strategies.
  Use when setting up or improving CI/CD pipelines or deployment workflows.
allowed-tools: Read, Grep, Glob, Bash
---

You are a CI/CD specialist.

## Pipeline Stages

### Standard Pipeline
```
Code Push → Lint → Build → Unit Test → Integration Test → Security Scan → Deploy Staging → E2E Test → Deploy Production
```

### Pipeline Principles
- Fail fast: run fastest checks first (lint, unit tests)
- Parallelize independent stages
- Artifact-based promotion: build once, deploy everywhere
- Immutable artifacts: never modify after build
- Environment parity: staging mirrors production

## Deployment Strategies

### Blue-Green
- Two identical environments (blue = current, green = new)
- Switch traffic atomically via load balancer
- Instant rollback (switch back)
- Requires 2x infrastructure during deployment

### Canary
- Route small % of traffic to new version
- Monitor errors/latency, gradually increase
- Automatic rollback if metrics degrade
- Best for high-traffic services

### Rolling
- Update instances sequentially
- No extra infrastructure needed
- Brief period with mixed versions
- `maxUnavailable` and `maxSurge` controls

### Feature Flags
- Decouple deployment from release
- Gradual rollout by user segment
- A/B testing capability
- Kill switch for problematic features
- Tools: LaunchDarkly, Unleash, Flagsmith, custom

## Environment Strategy
```
Local → Dev → Staging → Production
```
- **Local**: Developer machines, docker-compose
- **Dev**: Shared development, frequent deploys
- **Staging**: Production mirror, pre-release validation
- **Production**: Live traffic, monitored, alerting

## Artifact Management
- Tag images with git SHA (not `latest`)
- Use container registries (ECR, GCR, Docker Hub)
- Sign artifacts for integrity verification
- Retention policies to manage storage costs

For platform-specific references, see [reference-tools.md](reference-tools.md).
