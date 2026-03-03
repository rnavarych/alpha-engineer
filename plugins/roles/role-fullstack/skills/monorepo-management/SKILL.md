---
name: role-fullstack:monorepo-management
description: Manage monorepos with Turborepo (pipelines, local/remote caching, task graph) or Nx (generators, affected commands, module boundaries). Covers pnpm workspaces setup, shared packages (ui, types, utils, config, database, validators), cross-project dependency rules, and CI optimization via change detection and parallel execution. Use when setting up or maintaining a monorepo, creating shared packages, or optimizing CI build times.
allowed-tools: Read, Grep, Glob, Bash
---

# Monorepo Management

## When to use
- Setting up a new monorepo with multiple apps and shared packages
- Configuring Turborepo pipelines or Nx task orchestration
- Creating or extracting a shared `ui`, `types`, `utils`, or `config` package
- Optimizing CI by enabling remote caching or change detection
- Diagnosing circular dependency issues between packages
- Managing internal `workspace:*` dependencies and version consistency

## Core principles
1. **`^build` is topological order** — Turborepo resolves dependency graph automatically; always use `dependsOn: ["^build"]` so packages build in the right sequence
2. **Cache outputs explicitly** — if `outputs` is not configured, Turborepo cannot cache; always declare build artifacts including `.next/**` and `dist/**`
3. **Keep the graph acyclic** — if two packages need each other, extract the shared logic into a third; `nx graph` or `madge` surfaces cycles before they become painful
4. **Types-only package has zero runtime code** — `packages/types` exports interfaces and enums only; both frontend and backend import from it for contract consistency
5. **Remote cache cuts CI time by 40-70%** — connect Turborepo to Vercel remote cache or self-host; every developer and CI run benefits from shared build artifacts

## Reference Files

- `references/turborepo-setup.md` — tool comparison table, recommended monorepo directory structure, turbo.json configuration with task pipeline, pnpm workspace setup and catalog version pinning
- `references/shared-packages-ci.md` — packages/ui barrel exports and subpath exports, packages/types rules, packages/config sharing pattern, Nx generators and affected commands, CI optimization steps, cross-project dependency rules, common pitfalls
