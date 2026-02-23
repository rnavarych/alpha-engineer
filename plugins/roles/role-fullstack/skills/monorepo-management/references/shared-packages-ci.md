# Shared Packages and CI Optimization

## When to load
Load when creating shared packages, setting up cross-project dependencies, optimizing CI pipelines with caching, or using Nx-specific features.

## Shared Packages Best Practices

### packages/ui
- Export components with barrel files (`index.ts`).
- Include a `package.json` with `"main"` and `"types"` fields pointing to source (for internal consumption) or built output.
- Use `"exports"` field for subpath exports (`@repo/ui/button`).

### packages/types
- Define shared interfaces, enums, and type aliases.
- Never include runtime code — types-only package.
- Both frontend and backend import from here for contract consistency.

### packages/config
- Share ESLint configs (`@repo/eslint-config`), Tailwind presets, and `tsconfig` base files.
- Apps extend these: `"extends": "@repo/config/tsconfig.base.json"`.

## Nx-Specific Features

- **Generators** — scaffold new apps and libraries with consistent structure: `nx generate @nx/react:app admin`.
- **Affected** — only build/test/lint packages affected by the current changes: `nx affected --target=test`.
- **Module boundaries** — enforce dependency rules with `@nx/enforce-module-boundaries` ESLint rule.
- **Task graph** — visualize task dependencies with `nx graph`.

## CI Optimization

1. **Change detection** — only run tasks for affected packages. Turborepo: automatic with caching. Nx: `nx affected`.
2. **Remote caching** — share build caches across CI runs and developers. Reduces build times by 40-70%.
3. **Parallel execution** — Turborepo and Nx run independent tasks in parallel by default.
4. **Docker layer caching** — copy `package.json` and lockfile first, install deps, then copy source. This caches the dependency installation layer.
5. **Selective deployment** — only deploy apps whose source or dependencies changed.

## Cross-Project Dependencies

- Internal packages use `workspace:*` — resolved at install time, no publishing needed.
- Keep the dependency graph acyclic. If two packages need each other, extract the shared part into a third package.
- Use `tsconfig` project references for fast IDE feedback and incremental compilation.

## Common Pitfalls

- Circular dependencies between packages — always check with `nx graph` or `madge`.
- Building packages that have not changed — enable caching and verify `outputs` are configured.
- Inconsistent dependency versions across packages — use pnpm catalogs or Nx's single-version policy.
- Oversized shared packages — split `packages/utils` if it grows beyond 20 modules.
- Forgetting to add new packages to `pnpm-workspace.yaml` globs.
