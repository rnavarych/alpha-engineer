# Turborepo Setup

## When to load
Load when configuring Turborepo pipelines, enabling remote caching, or optimizing task orchestration in a monorepo.

## Tool Selection

| Tool      | Learning Curve | Caching       | Code Generation | Best For                     |
|-----------|---------------|---------------|-----------------|------------------------------|
| Turborepo | Low           | Local + Remote| No              | Simple monorepos, startups   |
| Nx        | Medium        | Local + Remote| Yes (generators)| Large monorepos, enterprise  |
| Lerna     | Low           | Via Nx        | No              | Publishing npm packages      |

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
- `outputs` defines what to cache — always include build artifacts.
- Enable remote caching with Vercel (`turbo login && turbo link`) or self-hosted (Ducktape, Turborepo Remote Cache).

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
