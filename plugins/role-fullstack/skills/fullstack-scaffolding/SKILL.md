---
name: fullstack-scaffolding
description: |
  Scaffold production-ready fullstack projects with Next.js (App Router), Remix,
  Nuxt 3, or SvelteKit. Sets up API routes, database (Prisma/Drizzle), auth
  (NextAuth/Lucia), styling (Tailwind CSS), deployment config, and strict TypeScript.
allowed-tools: Read, Grep, Glob, Bash
---

# Fullstack Scaffolding

## When to Use

Activate when the user requests a new project, starter template, or needs to bootstrap an application from scratch with a fullstack framework.

## Framework Selection Guide

| Framework   | Best For                              | SSR/SSG    | API Layer         |
|-------------|---------------------------------------|------------|--------------------|
| Next.js 14+ | React ecosystem, Vercel deployment    | Both       | Route Handlers, Server Actions |
| Remix       | Progressive enhancement, nested routes| SSR        | Loaders / Actions  |
| Nuxt 3      | Vue ecosystem, auto-imports           | Both       | server/api/        |
| SvelteKit   | Minimal JS, fast hydration            | Both       | +server.ts          |

## Scaffolding Checklist

1. **Initialize project** with the framework CLI (`create-next-app`, `create-remix`, `nuxi init`, `create svelte`).
2. **TypeScript strict mode** -- set `strict: true` in `tsconfig.json`. Add path aliases (`@/` for `src/`).
3. **Database setup** -- install Prisma or Drizzle. Create initial schema with User model. Generate client. Add seed script.
4. **Auth integration** -- configure NextAuth.js (App Router), Lucia, or Auth.js. Set up credentials + at least one OAuth provider. Add session middleware.
5. **Styling** -- install Tailwind CSS with PostCSS. Configure `tailwind.config.ts`. Add base styles and a design-token layer (CSS variables).
6. **Linting and formatting** -- ESLint (framework-specific config), Prettier, `lint-staged` + `husky` for pre-commit hooks.
7. **Environment variables** -- create `.env.example` with all required keys documented. Use `zod` to validate `process.env` at startup.
8. **Deployment config** -- add `Dockerfile` (multi-stage) or `vercel.json` / `netlify.toml`. Include health-check endpoint (`/api/health`).
9. **CI/CD stub** -- GitHub Actions workflow for lint, type-check, test, build.

## Project Structure (Next.js App Router Example)

```
├── apps/web/
│   ├── app/
│   │   ├── (auth)/login/page.tsx
│   │   ├── (dashboard)/page.tsx
│   │   ├── api/health/route.ts
│   │   └── layout.tsx
│   ├── prisma/
│   │   ├── schema.prisma
│   │   └── seed.ts
│   ├── tailwind.config.ts
│   ├── tsconfig.json
│   └── .env.example
├── packages/
│   ├── ui/          # shared components
│   ├── types/       # shared TypeScript types
│   └── config/      # shared ESLint, Tailwind, TS configs
├── turbo.json
└── package.json
```

## Key Principles

- **Convention over configuration.** Leverage framework defaults before overriding.
- **Validate early.** Use `zod` schemas for env vars, API inputs, and form data from day one.
- **No dead code.** Remove unused boilerplate from CLI-generated projects immediately.
- **Document decisions.** Add a brief `docs/decisions.md` noting framework choice rationale.

## Common Pitfalls

- Forgetting to add `.env` to `.gitignore` while keeping `.env.example` tracked.
- Using `any` types in API route handlers -- always type request/response bodies.
- Skipping database migration setup -- always use `prisma migrate dev` or Drizzle Kit from the start.
- Hardcoding secrets instead of using environment variables with validation.
