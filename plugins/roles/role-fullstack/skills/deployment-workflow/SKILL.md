---
name: deployment-workflow
description: Set up deployment workflows for Vercel, Netlify, Railway, Render, and Docker. Covers preview environments per PR, database migrations in CI (expand-contract pattern), environment variable validation, health check endpoints, and rollback procedures. Use when configuring deployment pipelines, managing env vars across stages, or establishing rollback runbooks.
allowed-tools: Read, Grep, Glob, Bash
---

# Deployment Workflow

## When to use
- Configuring a deployment pipeline for a new project
- Setting up preview environments per pull request
- Managing environment variables across development, staging, and production
- Running database migrations safely in CI without downtime
- Adding health check endpoints for load balancer routing
- Establishing rollback procedures before the first production incident

## Core principles
1. **Platform matches project shape** — Vercel for edge-first Next.js, Railway/Render for fullstack with databases, Fly.io for global edge
2. **Migrations before deploy, never after** — run `prisma migrate deploy` as a CI step preceding the deploy step, never during
3. **Expand-contract for zero downtime** — add column → backfill → update code → drop old column across three separate deploys
4. **Validate env vars at startup** — use `@t3-oss/env-nextjs` or zod to crash fast with a clear message rather than fail silently at runtime
5. **Health check is not optional** — every deployed service needs `/api/health` returning 200/503; load balancers depend on it

## Reference Files

- `references/platform-selection.md` — comparison table for Vercel, Netlify, Railway, Render, Fly.io; Vercel setup steps; multi-stage Dockerfile for Node.js; Docker-based preview environments per PR
- `references/migrations-env-vars.md` — CI migration steps, expand-contract pattern walkthrough, env var management with secrets managers, common pitfalls
- `references/health-checks-rollback.md` — health check endpoint implementation, liveness vs readiness probes, rollback procedures for Vercel/Docker/database, incident runbook checklist
