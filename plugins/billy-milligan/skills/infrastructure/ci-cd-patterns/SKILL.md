---
name: ci-cd-patterns
description: |
  CI/CD pipeline patterns for GitHub Actions, GitLab CI, Jenkins. Covers caching, matrix builds, OIDC secrets, deployment strategies, pipeline optimization.
allowed-tools: Read, Grep, Glob
---

# CI/CD Patterns

## When to use

Use when designing, optimizing, or troubleshooting CI/CD pipelines. Covers workflow structure, caching strategies, deployment automation, and cross-platform pipeline patterns.

## Core principles

1. Pipeline as code — version-controlled, reproducible, reviewable
2. Fast feedback — fail fast with parallel jobs and test splitting
3. Immutable artifacts — build once, deploy many
4. Secret hygiene — OIDC federation over static secrets
5. Progressive delivery — automated gates between environments

## References available

- `references/github-actions-patterns.md` — Reusable workflows, matrix builds, caching, OIDC secrets, composite actions
- `references/gitlab-ci-patterns.md` — DAG pipelines, includes/extends, environments, review apps, auto DevOps
- `references/pipeline-optimization.md` — Parallel jobs, test splitting, artifact caching, incremental builds, build matrix
- `references/deployment-strategies.md` — Blue-green, canary, rolling for k8s, Vercel, AWS ECS

## Scripts available

- `scripts/detect-ci.sh` — Detects CI platform from project files (.github/workflows, .gitlab-ci.yml, Jenkinsfile, etc.)

## Assets available

- `assets/github-actions-template.yaml` — Lint, test, build, deploy workflow template
- `assets/gitlab-ci-template.yaml` — Equivalent pipeline for GitLab CI
