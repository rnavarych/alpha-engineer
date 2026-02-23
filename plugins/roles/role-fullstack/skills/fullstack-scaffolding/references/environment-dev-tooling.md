# Environment Setup and Dev Tooling

## When to load
Load when configuring environment variables, Docker Compose for local services, or dev server tooling (Turbopack, Vite, HMR).

## .env Management

Use `.env.example` as the source of truth. Every developer copies it to `.env` and fills in values.

```bash
# .env.example — commit this file
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

## Docker Compose for Local Development

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

## Turbopack (Next.js dev server)

Turbopack is the Rust-based bundler that ships with Next.js 15. Enable with:
```bash
next dev --turbopack
```
Cold start 10x faster than webpack. Incremental compilation — only rebuilds changed modules. Production build still uses webpack (Turbopack production is in progress as of 2025).

## Vite Dev Server

SvelteKit, Nuxt 3, Astro, Remix (Vite template), and standalone Vite projects use Vite for development.

Key Vite patterns:
- `vite.config.ts` for plugins, aliases, proxy rules.
- `import.meta.env.VITE_*` for client-safe env vars.
- Plugin ecosystem: `@vitejs/plugin-react`, `unplugin-icons`, `vite-plugin-pwa`.
- `vite preview` to test production builds locally before deploying.

## Hot Module Replacement (HMR)

All modern fullstack frameworks ship HMR out of the box. Key considerations:
- React Fast Refresh: preserves component state on edit. Requires function components.
- Svelte HMR: preserves Svelte store state.
- Vue HMR: preserves component state for `<script setup>` components.
- Full page reload triggers: env file changes, middleware changes, server-side route files.
- WebSocket connection used by all HMR implementations — ensure dev proxy passes WebSocket traffic.
