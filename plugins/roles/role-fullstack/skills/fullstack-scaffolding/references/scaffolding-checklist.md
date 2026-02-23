# Scaffolding Checklist

## When to load
Load when starting a project from scratch and need a step-by-step setup sequence, or when auditing an existing project for missing foundational pieces.

## Setup Sequence

1. **Initialize project** with the framework CLI (see `framework-cli-starters.md`).
2. **TypeScript strict mode** — set `strict: true` in `tsconfig.json`. Add path aliases (`@/` for `src/`).
3. **Database setup** — install Prisma or Drizzle. Create initial schema with User model. Generate client. Add seed script.
4. **Auth integration** — configure NextAuth.js (App Router), Lucia, or Clerk. Set up credentials + at least one OAuth provider. Add session middleware.
5. **Styling** — install Tailwind CSS with PostCSS. Configure `tailwind.config.ts`. Add base styles and a design-token layer (CSS variables).
6. **Linting and formatting** — ESLint (framework-specific config), Prettier, `lint-staged` + `husky` for pre-commit hooks.
7. **Environment variables** — create `.env.example` with all required keys documented. Use `zod` to validate `process.env` at startup (`@t3-oss/env-nextjs` for Next.js).
8. **Deployment config** — add `Dockerfile` (multi-stage) or `vercel.json` / `netlify.toml`. Include health-check endpoint (`/api/health`).
9. **CI/CD stub** — GitHub Actions workflow for lint, type-check, test, build.

## Key Principles

- **Convention over configuration.** Leverage framework defaults before overriding.
- **Validate early.** Use `zod` schemas for env vars, API inputs, and form data from day one.
- **No dead code.** Remove unused boilerplate from CLI-generated projects immediately.
- **Feature flags from day one.** Add a simple feature flag mechanism (env var or database-backed) before you need it.
- **Structured logging.** Configure Pino or Winston with JSON output from project start.

## Common Pitfalls

- Forgetting to add `.env` to `.gitignore` while keeping `.env.example` tracked.
- Using `any` types in API route handlers — always type request/response bodies.
- Skipping database migration setup — always use `prisma migrate dev` or Drizzle Kit from the start.
- Hardcoding secrets instead of using environment variables with validation.
- Copying the entire boilerplate including demo content — remove it before first commit.
- Not setting up Docker Compose for local services (DB, Redis) — developers on different OSes will have inconsistent environments.
- Missing `--frozen-lockfile` in CI install commands — always pin exact versions in CI.
