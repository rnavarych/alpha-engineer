---
name: fullstack-scaffolding
description: |
  Scaffold production-ready fullstack projects with Next.js (App Router), Remix,
  Nuxt 3, SvelteKit, Astro, or alternative stacks (T3, Blitz, RedwoodJS, Wasp).
  Sets up API routes, database (Prisma/Drizzle), auth (NextAuth/Lucia/Clerk),
  styling (Tailwind CSS), deployment config, strict TypeScript, monorepo layout,
  CMS backends (Payload, Directus, Strapi, Keystone), and dev toolchain.
allowed-tools: Read, Grep, Glob, Bash
---

# Fullstack Scaffolding

## When to Use

Activate when the user requests a new project, starter template, or needs to bootstrap an application from scratch with a fullstack framework.

## Framework CLI Starters

### TypeScript / JavaScript Ecosystem

**create-t3-app** (Next.js + tRPC + Prisma + NextAuth + Tailwind):
```bash
pnpm create t3-app@latest my-app
# Select: TypeScript, tRPC, NextAuth, Prisma, Tailwind CSS
```
Best for: SaaS, dashboards, apps where end-to-end type safety is paramount.

**create-next-app** (Next.js standalone):
```bash
pnpm create next-app@latest my-app --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"
```
Best for: React ecosystem, Vercel deployment, SSR/SSG hybrid.

**create-remix** (Remix):
```bash
pnpm create remix@latest my-app
# Template options: remix-run/remix/templates/express, blues-stack, indie-stack, grunge-stack
```
Best for: progressive enhancement, form-heavy apps, nested routing.

**create-svelte** (SvelteKit):
```bash
pnpm create svelte@latest my-app
# Select: SvelteKit demo app or skeleton, TypeScript, ESLint, Prettier, Playwright
```
Best for: minimal JavaScript output, high performance, simple mental model.

**nuxi init** (Nuxt 3):
```bash
pnpm dlx nuxi@latest init my-app
```
Best for: Vue ecosystem, auto-imports, versatile SSR/SSG/ISR.

**create astro** (Astro):
```bash
pnpm create astro@latest my-app
# Template options: blog, portfolio, minimal, with-react, with-vue, with-tailwind
```
Best for: content sites, documentation, marketing pages, partial hydration.

**create-expo-app** (React Native + Expo):
```bash
pnpm create expo-app@latest my-app --template
# Select: blank (TypeScript), tabs (Expo Router), bare workflow
```
Best for: cross-platform mobile with code sharing from a web monorepo.

### Fullstack DSL Frameworks

**Blitz.js** (Next.js + Zero-API layer):
```bash
pnpm create blitz-app@latest my-app
```
The original "no API" fullstack React framework. Server queries/mutations callable directly from components without explicit fetch. Now built on Next.js App Router.

**RedwoodJS** (React + GraphQL + Prisma):
```bash
pnpm create redwood-app@latest my-app --ts
```
Opinionated fullstack framework with generators for pages, layouts, cells (data components), services, and GraphQL resolvers. Best for teams wanting strong conventions.

**Wasp** (Fullstack DSL → React + Node.js):
```bash
curl -sSL https://get.wasp-lang.dev/installer.sh | sh
wasp new my-app
```
Wasp is a configuration language that generates a React + Express + Prisma application. Declare entities, routes, queries, actions, and auth in `.wasp` file. The compiler generates all boilerplate. Best for rapid MVPs.

**Amplication** (Backend code generator):
```bash
# Web-based or CLI: amplication create
npm install -g @amplication/cli
amplication create
```
Generates a production-ready NestJS + Prisma backend with GraphQL + REST APIs, authentication, RBAC, and admin UI from a visual entity modeler. Best for REST/GraphQL APIs without hand-writing boilerplate.

## Headless CMS Options

### Payload CMS (Code-first, TypeScript-native)

```bash
pnpx create-payload-app@latest
# Select: blank, website, e-commerce template
```
Payload runs inside your Next.js application (App Router integration via `withPayload`). All configuration is TypeScript -- collections, globals, fields, hooks, access control are code. No GUI config export/import problems.

Key patterns:
- Collections define content types: `posts`, `users`, `media`.
- Global documents for singleton content: `site-settings`, `navigation`.
- Lexical rich text editor with custom blocks.
- Local API: `payload.find({ collection: 'posts', where: { status: { equals: 'published' } } })` for server-side queries with zero HTTP overhead.
- REST API and GraphQL auto-generated from collection config.
- `beforeOperation`, `afterOperation`, `beforeChange`, `afterChange` hooks for business logic.

### Directus (REST + GraphQL auto-API over any database)

```bash
npx create-directus-project@latest my-project
# Or Docker: docker run directus/directus
```
Directus wraps any SQL database with a REST and GraphQL API, plus a no-code admin UI. Best for teams where non-developers manage content schema. Use the JavaScript SDK or the generated client for typed queries.

### Strapi v5 (Node.js headless CMS)

```bash
pnpm create strapi@latest my-project
# Select: TypeScript, SQLite (dev) / PostgreSQL (prod), template
```
Strapi v5 introduced the Document Service API, replaced entity service. Content types defined via admin UI or code (JSON schema). Plugin system for extending core. REST and GraphQL APIs. Content Manager + Media Library included. Deploy on Strapi Cloud, Railway, or self-host with Docker.

### KeystoneJS (Next.js + Prisma-backed CMS)

```bash
pnpm create keystone-app@latest my-app
```
Keystone defines content schema in TypeScript, generates Prisma migrations, and provides a GraphQL API plus the Keystone Admin UI. Excellent choice when developers want full code control but still need an editorial interface.

## Scaffolding Checklist

1. **Initialize project** with the framework CLI (see above).
2. **TypeScript strict mode** -- set `strict: true` in `tsconfig.json`. Add path aliases (`@/` for `src/`).
3. **Database setup** -- install Prisma or Drizzle. Create initial schema with User model. Generate client. Add seed script.
4. **Auth integration** -- configure NextAuth.js (App Router), Lucia, or Clerk. Set up credentials + at least one OAuth provider. Add session middleware.
5. **Styling** -- install Tailwind CSS with PostCSS. Configure `tailwind.config.ts`. Add base styles and a design-token layer (CSS variables).
6. **Linting and formatting** -- ESLint (framework-specific config), Prettier, `lint-staged` + `husky` for pre-commit hooks.
7. **Environment variables** -- create `.env.example` with all required keys documented. Use `zod` to validate `process.env` at startup (`@t3-oss/env-nextjs` for Next.js).
8. **Deployment config** -- add `Dockerfile` (multi-stage) or `vercel.json` / `netlify.toml`. Include health-check endpoint (`/api/health`).
9. **CI/CD stub** -- GitHub Actions workflow for lint, type-check, test, build.

## Project Structure Conventions

### Feature-Based Structure (recommended for most apps)

Organize code by feature/domain. Each feature is self-contained with its own components, hooks, types, and API calls.

```
src/
├── features/
│   ├── auth/
│   │   ├── components/     # LoginForm, SignupForm, AuthGuard
│   │   ├── hooks/          # useSession, useSignIn
│   │   ├── api.ts          # Auth API calls / tRPC procedures
│   │   └── types.ts        # Auth-specific types
│   ├── users/
│   │   ├── components/     # UserCard, UserList, UserAvatar
│   │   ├── hooks/          # useUser, useUsers
│   │   └── api.ts
│   └── billing/
│       ├── components/     # PricingTable, BillingPortal
│       ├── hooks/          # useSubscription
│       └── api.ts
├── shared/
│   ├── components/         # Button, Input, Modal, Toast (atomic UI)
│   ├── hooks/              # useDebounce, useLocalStorage, useIntersection
│   ├── lib/                # Singleton clients (prisma, redis, stripe, email)
│   └── types/              # App-wide type utilities
└── app/                    # Next.js App Router pages and layouts
```

### Layer-Based Structure (traditional, suits large teams)

Separates code by architectural layer: UI, business logic, data access.

```
src/
├── app/                    # Route handlers and page components
├── components/             # All React components, organized by type
├── lib/                    # Business logic (services, use cases)
├── server/                 # Server-only code (db, auth, API handlers)
├── hooks/                  # Custom React hooks
└── types/                  # TypeScript type definitions
```

### Domain-Based Structure (DDD-inspired, suits complex domains)

Each domain module contains all layers within it: routes, services, repositories, entities.

```
src/
├── modules/
│   ├── orders/
│   │   ├── order.entity.ts
│   │   ├── order.service.ts
│   │   ├── order.repository.ts
│   │   ├── order.router.ts
│   │   └── order.schema.ts
│   └── inventory/
│       ├── ...
├── shared/
│   ├── database/
│   ├── errors/
│   └── middleware/
└── app.ts
```

## Monorepo Scaffolding (with Turborepo)

```
├── apps/
│   ├── web/              # Next.js frontend (create-next-app)
│   ├── api/              # Express/Fastify/Hono API (if separate)
│   ├── admin/            # Admin panel (can be another Next.js app)
│   └── mobile/           # Expo React Native app
├── packages/
│   ├── ui/               # Shared React component library
│   ├── types/            # Shared TypeScript types and interfaces
│   ├── utils/            # Shared utility functions (pure, isomorphic)
│   ├── config/           # ESLint, TypeScript, Tailwind shared configs
│   ├── database/         # Prisma schema, client export, migrations
│   └── validators/       # Shared Zod schemas (used client + server)
├── turbo.json
├── pnpm-workspace.yaml
├── package.json
└── tsconfig.base.json
```

## Environment Setup

### .env Management

Use `.env.example` as the source of truth. Every developer copies it to `.env` and fills in values.

```bash
# .env.example -- commit this file
DATABASE_URL=postgresql://user:password@localhost:5432/myapp
NEXTAUTH_SECRET=           # Generate: openssl rand -base64 32
NEXTAUTH_URL=http://localhost:3000
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
RESEND_API_KEY=
REDIS_URL=redis://localhost:6379
```

Validate at startup with `@t3-oss/env-nextjs`:
```typescript
// src/env.ts
import { createEnv } from '@t3-oss/env-nextjs';
import { z } from 'zod';

export const env = createEnv({
  server: {
    DATABASE_URL: z.string().url(),
    NEXTAUTH_SECRET: z.string().min(32),
    STRIPE_SECRET_KEY: z.string().startsWith('sk_'),
  },
  client: {
    NEXT_PUBLIC_APP_URL: z.string().url(),
  },
  runtimeEnv: process.env,
});
```

### Docker Compose for Local Development

```yaml
# docker-compose.yml
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  meilisearch:
    image: getmeili/meilisearch:v1.9
    ports:
      - "7700:7700"
    environment:
      MEILI_MASTER_KEY: development-master-key

volumes:
  postgres_data:
```

## Development Tools

### Turbopack (Next.js dev server)

Turbopack is the Rust-based bundler that ships with Next.js 15. Enable with:
```bash
next dev --turbopack
```
Cold start 10x faster than webpack. Incremental compilation -- only rebuilds changed modules. Production build still uses webpack (Turbopack production is in progress as of 2025).

### Vite Dev Server

SvelteKit, Nuxt 3, Astro, Remix (Vite template), and standalone Vite projects use Vite for development.

Key Vite patterns:
- `vite.config.ts` for plugins, aliases, proxy rules.
- `import.meta.env.VITE_*` for client-safe env vars.
- Plugin ecosystem: `@vitejs/plugin-react`, `unplugin-icons`, `vite-plugin-pwa`.
- `vite preview` to test production builds locally before deploying.

### Hot Module Replacement (HMR)

All modern fullstack frameworks ship HMR out of the box. Key considerations:
- React Fast Refresh: preserves component state on edit. Requires function components.
- Svelte HMR: preserves Svelte store state.
- Vue HMR: preserves component state for `<script setup>` components.
- Full page reload triggers: env file changes, middleware changes, server-side route files.
- WebSocket connection used by all HMR implementations -- ensure dev proxy passes WebSocket traffic.

## Boilerplates and Templates

| Template | Stack | Use Case |
|----------|-------|----------|
| create-t3-app | Next.js + tRPC + Prisma + NextAuth + Tailwind | TypeScript SaaS |
| Taxonomy (shadcn) | Next.js + MDX + Contentlayer + Stripe | Content + billing |
| Precedent | Next.js + Prisma + NextAuth + Radix + Tailwind | Clean starter |
| Vercel Commerce | Next.js + Shopify/BigCommerce | E-commerce |
| Medusa.js starter | Medusa (Node) + Next.js storefront | Headless commerce |
| Supabase starter | Next.js + Supabase + Tailwind | Auth + database |
| Payload website template | Next.js + Payload CMS | Marketing + CMS |
| Epic Stack (Kent C. Dodds) | Remix + SQLite + Fly.io | Full-featured Remix |
| T3 Turbo | Turborepo + Next.js + Expo + tRPC | Web + mobile |

## Key Principles

- **Convention over configuration.** Leverage framework defaults before overriding.
- **Validate early.** Use `zod` schemas for env vars, API inputs, and form data from day one.
- **No dead code.** Remove unused boilerplate from CLI-generated projects immediately.
- **Feature flags from day one.** Add a simple feature flag mechanism (env var or database-backed) before you need it.
- **Structured logging.** Configure Pino or Winston with JSON output from project start.

## Common Pitfalls

- Forgetting to add `.env` to `.gitignore` while keeping `.env.example` tracked.
- Using `any` types in API route handlers -- always type request/response bodies.
- Skipping database migration setup -- always use `prisma migrate dev` or Drizzle Kit from the start.
- Hardcoding secrets instead of using environment variables with validation.
- Copying the entire boilerplate including demo content -- remove it before first commit.
- Not setting up Docker Compose for local services (DB, Redis) -- developers on different OSes will have inconsistent environments.
- Missing `--frozen-lockfile` in CI install commands -- always pin exact versions in CI.
