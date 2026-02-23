# Project Structure Conventions

## When to load
Load when organizing a new or existing project, choosing between feature-based, layer-based, or domain-based structure, or setting up a Turborepo monorepo layout.

## Feature-Based Structure (recommended for most apps)

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

## Layer-Based Structure (traditional, suits large teams)

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

## Domain-Based Structure (DDD-inspired, suits complex domains)

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

## Monorepo Layout (Turborepo)

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
