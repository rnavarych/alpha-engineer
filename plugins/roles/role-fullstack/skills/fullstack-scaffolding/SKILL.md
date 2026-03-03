---
name: role-fullstack:fullstack-scaffolding
description: Scaffold production-ready fullstack projects with Next.js (App Router), Remix, Nuxt 3, SvelteKit, Astro, Blitz, RedwoodJS, or Wasp. Covers framework CLI starters, headless CMS options (Payload, Directus, Strapi, Keystone), feature/layer/domain project structures, Turborepo monorepo layout, env var validation, Docker Compose for local services, and dev tooling (Turbopack, Vite, HMR). Use when bootstrapping a new project or auditing an existing one for missing foundations.
allowed-tools: Read, Grep, Glob, Bash
---

# Fullstack Scaffolding

## When to use
- Starting a new project and need the correct framework CLI command
- Choosing between Next.js, Remix, SvelteKit, Nuxt, Astro, or a DSL framework
- Adding a headless CMS to an existing or new application
- Deciding on project folder structure (feature vs layer vs domain)
- Setting up Turborepo monorepo with shared packages
- Configuring env var validation, Docker Compose, or CI/CD stub from day one

## Core principles
1. **Convention over configuration** — exhaust framework defaults before reaching for custom solutions; every override is future maintenance
2. **Validate at startup** — env vars validated with zod at boot time; a missing secret should crash immediately with a clear message, not at 3 AM
3. **Feature-based structure by default** — co-locate components, hooks, types, and API calls per feature; switch to domain-based only when bounded contexts are clear
4. **Remove boilerplate on first commit** — delete all demo content from CLI-generated projects before the first real commit lands
5. **Feature flags from day one** — add a minimal flag mechanism before the first conditional shipping need; retrofitting is always messier

## Reference Files

- `references/framework-cli-starters.md` — CLI commands and rationale for T3, Next.js, Remix, SvelteKit, Nuxt, Astro, Expo, Blitz, RedwoodJS, Wasp, Amplication; boilerplate template comparison table
- `references/headless-cms-options.md` — Payload CMS (code-first, Next.js integrated), Directus (no-code admin, any SQL), Strapi v5 (Document Service API), KeystoneJS (GraphQL + editorial UI)
- `references/project-structure.md` — feature-based, layer-based, and domain-based structure examples with annotated directory trees; Turborepo monorepo layout
- `references/environment-dev-tooling.md` — .env.example template, @t3-oss/env-nextjs validation code, Docker Compose for Postgres/Redis/Meilisearch, Turbopack setup, Vite patterns, HMR caveats
- `references/scaffolding-checklist.md` — nine-step setup sequence from CLI init to CI/CD stub, key principles, and common pitfalls checklist
