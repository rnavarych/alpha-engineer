# Monorepo Patterns

## Turborepo

```json
// turbo.json — pipeline configuration
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": ["**/.env.*local"],
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],       // Build deps first (topological)
      "outputs": ["dist/**", ".next/**"],
      "cache": true
    },
    "test": {
      "dependsOn": ["build"],
      "cache": true
    },
    "lint": {
      "cache": true
    },
    "dev": {
      "cache": false,
      "persistent": true              // Long-running dev servers
    }
  }
}
```

```
# Workspace structure
monorepo/
  apps/
    web/              # Next.js frontend
      package.json    # name: "@acme/web"
    api/              # Node.js API
      package.json    # name: "@acme/api"
  packages/
    ui/               # Shared UI components
      package.json    # name: "@acme/ui"
    db/               # Shared database schema
      package.json    # name: "@acme/db"
    config-ts/        # Shared tsconfig
      package.json    # name: "@acme/config-ts"
    config-eslint/    # Shared ESLint config
      package.json    # name: "@acme/config-eslint"
  turbo.json
  package.json
  pnpm-workspace.yaml
```

```bash
# Run build for all packages (cached, parallel)
turbo build

# Run only for specific package and its deps
turbo build --filter=@acme/web...

# Run dev for apps only
turbo dev --filter=./apps/*
```

## pnpm Workspaces

```yaml
# pnpm-workspace.yaml
packages:
  - 'apps/*'
  - 'packages/*'
```

```json
// apps/web/package.json — reference internal packages
{
  "name": "@acme/web",
  "dependencies": {
    "@acme/ui": "workspace:*",      // Always latest local version
    "@acme/db": "workspace:*",
    "next": "^14.0.0"
  }
}
```

```bash
# Install dependencies for all workspaces
pnpm install

# Add dependency to specific workspace
pnpm --filter @acme/web add react-query

# Run script in specific workspace
pnpm --filter @acme/api test

# Run script across all workspaces
pnpm -r build
```

## Nx

```json
// nx.json — Nx configuration
{
  "targetDefaults": {
    "build": {
      "dependsOn": ["^build"],
      "inputs": ["production", "^production"],
      "cache": true
    },
    "test": {
      "inputs": ["default", "^production"],
      "cache": true
    }
  },
  "namedInputs": {
    "default": ["{projectRoot}/**/*"],
    "production": [
      "default",
      "!{projectRoot}/**/*.spec.ts",
      "!{projectRoot}/test/**/*"
    ]
  }
}
```

```bash
# Run affected (only changed packages)
nx affected -t build
nx affected -t test

# Visualize dependency graph
nx graph
```

## Shared TypeScript Config

```json
// packages/config-ts/base.json
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitReturns": true,
    "forceConsistentCasingInFileNames": true,
    "esModuleInterop": true,
    "isolatedModules": true,
    "skipLibCheck": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  }
}

// apps/web/tsconfig.json — extends shared config
{
  "extends": "@acme/config-ts/nextjs.json",
  "compilerOptions": {
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src", "next-env.d.ts"],
  "exclude": ["node_modules"]
}
```

## Build Caching

```bash
# Turborepo remote cache — share across CI and team
turbo login
turbo link

# Cache hit: build skipped, output restored from cache
# Cache miss: build runs, output stored in cache

# Environment variables affect cache key
# turbo.json: "globalEnv": ["NODE_ENV", "DATABASE_URL"]

# Verify cache status
turbo build --dry-run
```

## Anti-Patterns
- Circular dependencies between packages — causes build failures
- No shared config — each package has its own tsconfig/eslint (drift)
- Publishing to npm for internal packages — use `workspace:*` protocol
- Missing `"dependsOn": ["^build"]` — builds run before deps are ready
- Committing `.turbo/` cache — should be in `.gitignore`

## Quick Reference
```
Turborepo: turbo.json pipeline, ^build for topological deps, cache: true
pnpm workspaces: pnpm-workspace.yaml, workspace:* for local deps
Nx: nx.json targets, nx affected for changed-only builds
Shared config: @acme/config-ts, @acme/config-eslint — extend in apps
Build cache: local by default, remote with turbo link
Filter: turbo --filter=@acme/web..., pnpm --filter @acme/api
Dev: persistent: true for long-running dev servers
```
