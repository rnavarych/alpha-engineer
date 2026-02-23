# Platform Selection

## When to load
Load when choosing a deployment platform, comparing hosting options, or evaluating Docker-based vs managed deployment.

## Platform Comparison

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

- **Vercel/Netlify** — automatic, zero configuration.
- **Docker-based** — use GitHub Actions to build and deploy a container per PR. Use the PR number in the subdomain (`pr-42.staging.example.com`).
- **Database** — either use a shared staging database (with schema migrations applied) or spin up ephemeral databases per preview (Neon branching, PlanetScale branching).
- Add the preview URL as a comment on the PR using a GitHub Action.
