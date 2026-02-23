# Framework CLI Starters

## When to load
Load when bootstrapping a new project and need the correct CLI command and rationale for each framework.

## TypeScript / JavaScript Ecosystem

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

## Fullstack DSL Frameworks

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
npm install -g @amplication/cli
amplication create
```
Generates a production-ready NestJS + Prisma backend with GraphQL + REST APIs, authentication, RBAC, and admin UI from a visual entity modeler. Best for REST/GraphQL APIs without hand-writing boilerplate.

## Boilerplate Templates

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
