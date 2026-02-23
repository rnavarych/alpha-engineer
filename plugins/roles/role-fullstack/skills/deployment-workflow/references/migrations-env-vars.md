# Migrations and Environment Variables

## When to load
Load when running database migrations in CI, managing environment variables across stages, or validating environment configuration at startup.

## Database Migrations in CI

1. Run migrations as a separate CI step before the deploy step.
2. Use `prisma migrate deploy` (not `dev`) in CI — it applies pending migrations without generating new ones.
3. For zero-downtime migrations, follow the expand-contract pattern:
   - Deploy 1: add the new column (nullable), backfill data.
   - Deploy 2: update application code to use the new column.
   - Deploy 3: remove the old column.
4. Always test migrations against a copy of production data before applying to production.

## Environment Variables Management

- Use `.env.example` as documentation — list every required variable with a description.
- Validate all env vars at startup with `zod` or `@t3-oss/env-nextjs`.
- Never commit secrets. Use platform-specific env var management (Vercel, Railway dashboards) or a secrets manager (AWS SSM, Doppler, Infisical).
- Separate env vars by stage: `development`, `staging`, `production`.

## Common Pitfalls

- Running `prisma migrate dev` in production — always use `prisma migrate deploy`.
- Deploying without a health-check endpoint — load balancers need it to route traffic correctly.
- Hardcoding environment-specific values (URLs, keys) instead of using env vars.
- Not testing the Docker image locally before pushing to CI.
