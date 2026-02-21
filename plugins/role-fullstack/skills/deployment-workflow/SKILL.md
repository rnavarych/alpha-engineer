---
name: deployment-workflow
description: |
  Set up deployment workflows: Vercel auto-deploy and preview environments,
  Netlify, Railway, Render, Docker deployments, database migrations in CI,
  environment variable management, health checks, and rollback procedures.
allowed-tools: Read, Grep, Glob, Bash
---

# Deployment Workflow

## When to Use

Activate when configuring deployment pipelines, setting up preview environments, managing environment variables across stages, or establishing rollback and health-check procedures.

## Platform Selection

| Platform  | Best For                     | Preview Envs | DB Hosting | Docker Support |
|-----------|------------------------------|-------------|------------|----------------|
| Vercel    | Next.js, edge-first          | Auto per PR | No (use external) | Limited |
| Netlify   | Static/Jamstack, serverless  | Auto per PR | No         | No             |
| Railway   | Fullstack, databases included| Yes         | Yes        | Yes            |
| Render    | Docker, background workers   | Yes         | Yes        | Yes            |
| Fly.io    | Edge deployment, global      | Manual      | Yes (Postgres) | Yes        |

## Vercel Deployment

1. Connect the GitHub repo in the Vercel dashboard.
2. Configure build settings: framework preset, root directory (for monorepos), environment variables.
3. Each PR gets an automatic preview deployment with a unique URL.
4. Production deploys on merge to `main`. Use the Vercel CLI (`vercel --prod`) for manual deploys.
5. Set up deployment protection for preview environments (password or Vercel Authentication).

## Docker Deployment

```dockerfile
# Multi-stage Dockerfile for Node.js apps
FROM node:20-alpine AS base
RUN corepack enable && corepack prepare pnpm@latest --activate

FROM base AS deps
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --prod

FROM base AS build
WORKDIR /app
COPY . .
RUN pnpm install --frozen-lockfile
RUN pnpm build

FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/package.json ./
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/api/health || exit 1
CMD ["node", "dist/server.js"]
```

## Preview Environments per PR

- **Vercel/Netlify** -- automatic, zero configuration.
- **Docker-based** -- use GitHub Actions to build and deploy a container per PR. Use the PR number in the subdomain (`pr-42.staging.example.com`).
- **Database** -- either use a shared staging database (with schema migrations applied) or spin up ephemeral databases per preview (Neon branching, PlanetScale branching).
- Add the preview URL as a comment on the PR using a GitHub Action.

## Database Migrations in CI

1. Run migrations as a separate CI step before the deploy step.
2. Use `prisma migrate deploy` (not `dev`) in CI -- it applies pending migrations without generating new ones.
3. For zero-downtime migrations, follow the expand-contract pattern:
   - Deploy 1: add the new column (nullable), backfill data.
   - Deploy 2: update application code to use the new column.
   - Deploy 3: remove the old column.
4. Always test migrations against a copy of production data before applying to production.

## Environment Variables Management

- Use `.env.example` as documentation -- list every required variable with a description.
- Validate all env vars at startup with `zod` or `@t3-oss/env-nextjs`.
- Never commit secrets. Use platform-specific env var management (Vercel, Railway dashboards) or a secrets manager (AWS SSM, Doppler, Infisical).
- Separate env vars by stage: `development`, `staging`, `production`.

## Health Checks

```typescript
// /api/health endpoint
export async function GET() {
  const checks = {
    database: await checkDatabase(),
    cache: await checkRedis(),
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  };
  const healthy = Object.values(checks).every((v) => v !== false);
  return Response.json(checks, { status: healthy ? 200 : 503 });
}
```

## Rollback Procedures

- **Vercel/Netlify** -- instant rollback to any previous deployment from the dashboard.
- **Docker** -- tag images with git SHA. Rollback by redeploying the previous image tag.
- **Database** -- rollback migrations are risky. Prefer forward-only migrations with the expand-contract pattern.
- Document the rollback procedure in a runbook. Practice it before you need it.

## Common Pitfalls

- Running `prisma migrate dev` in production -- always use `prisma migrate deploy`.
- Deploying without a health-check endpoint -- load balancers need it to route traffic correctly.
- Hardcoding environment-specific values (URLs, keys) instead of using env vars.
- Not testing the Docker image locally before pushing to CI.
