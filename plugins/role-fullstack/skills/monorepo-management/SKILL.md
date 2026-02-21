---
name: monorepo-management
description: |
  Manage monorepos with Turborepo (pipelines, caching, remote cache) or Nx
  (generators, executors, affected). Covers pnpm workspaces, shared packages
  (ui, utils, types, config), cross-project deps, and CI optimization.
allowed-tools: Read, Grep, Glob, Bash
---

# Monorepo Management

## When to Use

Activate when setting up or maintaining a monorepo structure, configuring build orchestration, creating shared packages, optimizing CI pipelines with caching, or managing cross-project dependencies.

## Tool Selection

| Tool      | Learning Curve | Caching       | Code Generation | Best For                     |
|-----------|---------------|---------------|-----------------|------------------------------|
| Turborepo | Low           | Local + Remote| No              | Simple monorepos, startups   |
| Nx        | Medium        | Local + Remote| Yes (generators)| Large monorepos, enterprise  |
| Lerna      | Low           | Via Nx        | No              | Publishing npm packages      |

## Recommended Structure

```
├── apps/
│   ├── web/              # Next.js frontend
│   ├── api/              # Express/Fastify backend
│   ├── admin/            # Admin panel
│   └── mobile/           # React Native app
├── packages/
│   ├── ui/               # Shared React components
│   ├── types/            # Shared TypeScript types/interfaces
│   ├── utils/            # Shared utility functions
│   ├── config/           # Shared configs (ESLint, Tailwind, TS)
│   ├── database/         # Prisma schema, client, migrations
│   └── validators/       # Shared Zod schemas
├── turbo.json
├── pnpm-workspace.yaml
├── package.json
└── tsconfig.base.json
```

## pnpm Workspaces Setup

```yaml
# pnpm-workspace.yaml
packages:
  - "apps/*"
  - "packages/*"
```

- Use `workspace:*` protocol for internal dependencies.
- Run commands across workspaces: `pnpm --filter web dev`, `pnpm --filter "./packages/*" build`.
- Use `catalog:` in `pnpm-workspace.yaml` to pin shared dependency versions across the monorepo.

## Turborepo Configuration

```json
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": ["**/.env.*local"],
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", ".next/**", "!.next/cache/**"]
    },
    "lint": { "dependsOn": ["^build"] },
    "test": { "dependsOn": ["^build"] },
    "dev": { "cache": false, "persistent": true }
  }
}
```

- `^build` means "build my dependencies first" (topological ordering).
- `outputs` defines what to cache -- always include build artifacts.
- Enable remote caching with Vercel (`turbo login && turbo link`) or self-hosted (Ducktape, Turborepo Remote Cache).

## Shared Packages Best Practices

### packages/ui
- Export components with barrel files (`index.ts`).
- Include a `package.json` with `"main"` and `"types"` fields pointing to source (for internal consumption) or built output.
- Use `"exports"` field for subpath exports (`@repo/ui/button`).

### packages/types
- Define shared interfaces, enums, and type aliases.
- Never include runtime code -- types-only package.
- Both frontend and backend import from here for contract consistency.

### packages/config
- Share ESLint configs (`@repo/eslint-config`), Tailwind presets, and `tsconfig` base files.
- Apps extend these: `"extends": "@repo/config/tsconfig.base.json"`.

## Nx-Specific Features

- **Generators** -- scaffold new apps and libraries with consistent structure: `nx generate @nx/react:app admin`.
- **Affected** -- only build/test/lint packages affected by the current changes: `nx affected --target=test`.
- **Module boundaries** -- enforce dependency rules with `@nx/enforce-module-boundaries` ESLint rule.
- **Task graph** -- visualize task dependencies with `nx graph`.

## CI Optimization

1. **Change detection** -- only run tasks for affected packages. Turborepo: automatic with caching. Nx: `nx affected`.
2. **Remote caching** -- share build caches across CI runs and developers. Reduces build times by 40-70%.
3. **Parallel execution** -- Turborepo and Nx run independent tasks in parallel by default.
4. **Docker layer caching** -- copy `package.json` and lockfile first, install deps, then copy source. This caches the dependency installation layer.
5. **Selective deployment** -- only deploy apps whose source or dependencies changed.

## Cross-Project Dependencies

- Internal packages use `workspace:*` -- resolved at install time, no publishing needed.
- Keep the dependency graph acyclic. If two packages need each other, extract the shared part into a third package.
- Use `tsconfig` project references for fast IDE feedback and incremental compilation.

## Common Pitfalls

- Circular dependencies between packages -- always check with `nx graph` or `madge`.
- Building packages that have not changed -- enable caching and verify `outputs` are configured.
- Inconsistent dependency versions across packages -- use pnpm catalogs or Nx's single-version policy.
- Oversized shared packages -- split `packages/utils` if it grows beyond 20 modules.
- Forgetting to add new packages to `pnpm-workspace.yaml` globs.
