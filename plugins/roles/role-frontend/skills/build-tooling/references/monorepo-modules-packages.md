# Monorepo Tooling, Module Systems, and Package Managers

## When to load
Load when setting up Turborepo/Nx monorepos, configuring pnpm workspaces, implementing dual ESM/CJS exports, or managing bundle size analysis.

## Turborepo

```json
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": ["**/.env.*local"],
  "tasks": {
    "build": { "dependsOn": ["^build"], "outputs": ["dist/**", ".next/**"], "env": ["NODE_ENV"] },
    "lint": { "dependsOn": ["^build"] },
    "test": { "dependsOn": ["build"], "inputs": ["src/**/*.tsx", "src/**/*.ts", "test/**/*.ts"] },
    "dev": { "cache": false, "persistent": true }
  }
}
```

- Use for simpler monorepos that need task pipelining and caching. Enable remote caching with Vercel.

## Nx

```json
{
  "targetDefaults": {
    "build": { "dependsOn": ["^build"], "cache": true },
    "test": { "cache": true, "inputs": ["default", "^default"] }
  },
  "namedInputs": {
    "default": ["{projectRoot}/**/*"],
    "production": ["default", "!{projectRoot}/**/*.spec.ts"]
  }
}
```

- Use for large monorepos with multiple applications and shared libraries.
- Define project boundaries with `@nx/enforce-module-boundaries` lint rule. Enable Nx Cloud for distributed caching.

## pnpm Workspaces

```yaml
# pnpm-workspace.yaml
packages:
  - 'apps/*'
  - 'packages/*'
```

```bash
pnpm install --frozen-lockfile           # CI
pnpm add react --filter @myorg/web-app  # add to specific workspace
pnpm -r run build                        # run across all packages
```

- **pnpm is preferred**: prevents phantom dependencies, uses less disk via hard links, handles workspaces natively.

## Package Managers Comparison

| Manager | Key Feature | Best For |
|---|---|---|
| npm | Built into Node.js | Simple projects, CI environments |
| pnpm | Content-addressable store | Monorepos, disk-efficient |
| Yarn Berry (v4) | Plug'n'Play, zero-installs | Deterministic installs |
| Bun | Runtime + package manager, fast | Speed-focused projects |

## ESM vs CJS

| Feature | ESM | CJS |
|---|---|---|
| Syntax | `import`/`export` | `require()`/`module.exports` |
| Loading | Static, async | Dynamic, sync |
| Tree shaking | Yes | No |
| Top-level await | Yes | No |
| Browser support | Yes (native) | No (requires bundler) |

### Dual Package Exports

```json
{
  "type": "module",
  "exports": {
    ".": {
      "import": "./dist/index.mjs",
      "require": "./dist/index.cjs",
      "types": "./dist/index.d.ts"
    }
  },
  "main": "./dist/index.cjs",
  "module": "./dist/index.mjs",
  "types": "./dist/index.d.ts"
}
```

## Bundle Analysis

```bash
npx source-map-explorer dist/main.js  # precise per-file size attribution
npx size-limit                         # budget enforcement in CI
```

```json
{
  "size-limit": [
    { "path": "dist/index.js", "limit": "50 KB" },
    { "path": "dist/vendor.js", "limit": "150 KB" }
  ]
}
```

- Track bundle size over time. Use `size-limit` or `bundlesize` in CI to compare against the baseline.
- Identify duplicate dependencies with `npm ls <package>` or bundler deduplication plugins.

## Anti-Patterns

| Anti-Pattern | Problem | Solution |
|---|---|---|
| No `.browserslistrc` | Shipping unnecessary polyfills | Define target browsers explicitly |
| Babel + TypeScript both transpiling | Double processing, slow builds | Use SWC or esbuild for transpilation |
| No bundle size budget | Silent bloat | `size-limit` or `bundlesize` in CI |
| Single chunk output | Entire app loaded upfront | Route-based code splitting |
| Running Prettier via ESLint | Slow, conflicting rules | Run separately, use `eslint-config-prettier` |
| Lerna for task running | Deprecated, no caching | Use Turborepo or Nx |
