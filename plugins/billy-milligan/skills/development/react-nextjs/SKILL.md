---
name: react-nextjs
description: React and Next.js App Router patterns — Server Components, client state, performance, streaming
allowed-tools: Read, Grep, Glob, Bash
---

# React & Next.js Skill

## Core Principles
- **Server-first**: Default to Server Components; add `"use client"` only for interactivity, browser APIs, or hooks.
- **Streaming**: Use `<Suspense>` boundaries to stream UI progressively — never block on slow data.
- **Type safety**: Colocate Zod schemas with API routes; infer types from schemas, never duplicate.
- **Performance budgets**: LCP < 2.5s, CLS < 0.1, INP < 200ms — measure on every PR.

## References
- `references/server-components.md` — RSC data fetching, Suspense streaming, Server vs Client decision tree
- `references/client-patterns.md` — Zustand/Jotai state, react-hook-form, optimistic UI
- `references/performance.md` — Bundle analysis, code splitting, image optimization, Core Web Vitals
- `references/app-router-patterns.md` — Layouts, parallel routes, intercepting routes, middleware

## Assets
- `assets/nextjs-starter-checklist.md` — New project setup checklist
