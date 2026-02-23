# Monorepo Strategies

## When to load
Load when setting up monorepo tooling, managing workspace packages, or optimizing CI for monorepos.

## Tool Comparison

| Tool | Language | Build Cache | Remote Cache | Task Orchestration |
|------|----------|-------------|--------------|-------------------|
| Turborepo | JS/TS | Yes | Yes (Vercel) | Parallel tasks |
| Nx | JS/TS (+ others) | Yes | Yes (Nx Cloud) | Task graph + affected |
| pnpm workspaces | JS/TS | No | No | Package manager only |
| Lerna | JS/TS | Via Nx | Via Nx | Versioning + publish |
| Bazel | Multi-language | Yes | Yes | Hermetic builds |

## Turborepo Setup

```json
// turbo.json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", ".next/**"]
    },
    "test": {
      "dependsOn": ["^build"],
      "outputs": []
    },
    "lint": {
      "outputs": []
    },
    "dev": {
      "cache": false,
      "persistent": true
    }
  }
}
```

```
// Directory structure
my-monorepo/
├── turbo.json
├── package.json (root)
├── apps/
│   ├── web/          # Next.js frontend
│   │   └── package.json
│   ├── api/          # Express API
│   │   └── package.json
│   └── mobile/       # React Native
│       └── package.json
├── packages/
│   ├── ui/           # Shared components
│   │   └── package.json
│   ├── config/       # Shared configs (ESLint, TS)
│   │   └── package.json
│   └── database/     # Prisma schema + client
│       └── package.json
└── pnpm-workspace.yaml
```

```yaml
# pnpm-workspace.yaml
packages:
  - "apps/*"
  - "packages/*"
```

```bash
# Run tasks
turbo build              # build all packages (cached)
turbo test --filter=web  # test only web app
turbo lint --affected     # lint only changed packages
turbo build --dry-run    # show task graph without executing
```

## Nx Setup

```json
// nx.json
{
  "targetDefaults": {
    "build": {
      "dependsOn": ["^build"],
      "cache": true
    },
    "test": {
      "cache": true
    },
    "lint": {
      "cache": true
    }
  },
  "affected": {
    "defaultBase": "main"
  }
}
```

```bash
# Run affected tasks only (based on git diff)
nx affected -t test       # test only affected by changes
nx affected -t build      # build only affected
nx affected -t lint       # lint only affected

# Dependency graph
nx graph                  # visual dependency graph in browser

# Run specific project
nx build api
nx test web
```

## Package Dependencies

```json
// apps/web/package.json
{
  "name": "web",
  "dependencies": {
    "@repo/ui": "workspace:*",
    "@repo/database": "workspace:*",
    "next": "^14.0.0"
  }
}

// packages/ui/package.json
{
  "name": "@repo/ui",
  "main": "./src/index.ts",
  "types": "./src/index.ts",
  "dependencies": {
    "react": "^18.0.0"
  }
}
```

```typescript
// apps/web/src/page.tsx — import from shared package
import { Button, Card } from '@repo/ui';
import { prisma } from '@repo/database';
```

## CI Optimization for Monorepos

```yaml
# GitHub Actions with Turborepo
name: CI
on:
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # needed for affected detection

      - uses: pnpm/action-setup@v3
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: pnpm

      - run: pnpm install --frozen-lockfile

      # Turborepo remote cache
      - run: pnpm turbo build test lint --cache-dir=.turbo
        env:
          TURBO_TOKEN: ${{ secrets.TURBO_TOKEN }}
          TURBO_TEAM: ${{ vars.TURBO_TEAM }}
```

## Versioning Strategy

```
Independent versioning (recommended):
  @repo/ui@1.2.0
  @repo/database@2.0.1
  web@1.5.0
  → Each package versioned independently
  → Use changesets for version management

Fixed versioning:
  All packages share same version (1.2.0)
  → Simpler, but version bumps even unchanged packages
```

```bash
# Changesets workflow
pnpm changeset          # describe your change
pnpm changeset version  # bump versions + update changelogs
pnpm changeset publish  # publish to npm
```

## Anti-patterns
- No build caching → slow CI, defeats monorepo purpose
- Circular dependencies between packages → build fails
- Running all tests on every PR → waste, use affected detection
- Shared package without clear API → tight coupling
- No workspace protocol (workspace:*) → installs from npm instead of local

## Quick reference
```
Turborepo: simplest setup, great caching, Vercel remote cache
Nx: most powerful, affected detection, visual graph
pnpm workspaces: package manager layer, combine with Turbo/Nx
Structure: apps/ (deployable) + packages/ (shared libraries)
Caching: local by default, remote for CI (Vercel/Nx Cloud)
Affected: only build/test packages changed since main branch
Versioning: changesets for independent, semantic-release for fixed
CI: fetch-depth=0, cache node_modules, use remote cache
```
