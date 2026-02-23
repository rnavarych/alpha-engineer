---
name: release-strategies
description: |
  Release strategy patterns. Feature flags (LaunchDarkly, Unleash), semantic versioning, conventional commits, changelog generation, rollback procedures per platform (k8s, Vercel, AWS).
allowed-tools: Read, Grep, Glob
---

# Release Strategies

## When to use

Use when planning production releases, implementing feature flags, setting up versioning automation, or designing rollback procedures. Covers the full release lifecycle from code merge to production validation.

## Core principles

1. Feature flags decouple deploy from release — ship dark, enable gradually
2. Semantic versioning communicates intent — breaking vs feature vs fix
3. Every release must have a rollback plan — if it cannot be rolled back, gate it behind a flag
4. Conventional commits enable automation — changelog and version bump without manual work
5. Flag cleanup is part of the lifecycle — stale flags are tech debt

## References available

- `references/feature-flags.md` — LaunchDarkly, Unleash, homegrown implementation, lifecycle, cleanup
- `references/semantic-versioning.md` — Semver, conventional commits, semantic-release, changelog generation
- `references/rollback-procedures.md` — Per-platform rollback (k8s, Vercel, AWS), DB rollback, feature flag kill switch
