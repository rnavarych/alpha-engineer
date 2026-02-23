---
name: backend-nodejs
description: Node.js backend patterns — Fastify/Express, database access, async patterns, security hardening
allowed-tools: Read, Grep, Glob, Bash
---

# Backend Node.js Skill

## Core Principles
- **Create connections once**: DB/Redis pools are singletons — never instantiate per request.
- **Validate at boundaries**: All external input validated with Zod/TypeBox before business logic.
- **Catch async errors**: Unhandled promise rejections crash Node.js — always handle.
- **Fail fast on bad config**: Validate all env vars at startup with Zod — exit(1) if invalid.
- **Graceful shutdown**: SIGTERM handler closes connections, drains in-flight requests.

## References
- `references/express-fastify.md` — Fastify with TypeBox, Express with Zod, middleware, error handling
- `references/database-access.md` — Drizzle, Prisma, Knex, connection pooling, transactions
- `references/async-patterns.md` — Promise.all, BullMQ queues, worker threads, streams, backpressure
- `references/security.md` — Input validation, rate limiting, CORS, helmet, dependency audit

## Scripts
- `scripts/detect-node-stack.sh` — Reads package.json to identify framework, ORM, test runner

## Assets
- `assets/tsconfig-recommended.json` — Strict TypeScript configuration for Node.js
