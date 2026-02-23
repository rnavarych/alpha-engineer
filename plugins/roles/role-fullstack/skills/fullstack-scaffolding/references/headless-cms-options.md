# Headless CMS Options

## When to load
Load when a project requires content management, an editorial interface, or a CMS-backed backend alongside the frontend framework.

## Payload CMS (Code-first, TypeScript-native)

```bash
pnpx create-payload-app@latest
# Select: blank, website, e-commerce template
```

Payload runs inside your Next.js application (App Router integration via `withPayload`). All configuration is TypeScript — collections, globals, fields, hooks, access control are code. No GUI config export/import problems.

Key patterns:
- Collections define content types: `posts`, `users`, `media`.
- Global documents for singleton content: `site-settings`, `navigation`.
- Lexical rich text editor with custom blocks.
- Local API: `payload.find({ collection: 'posts', where: { status: { equals: 'published' } } })` for server-side queries with zero HTTP overhead.
- REST API and GraphQL auto-generated from collection config.
- `beforeOperation`, `afterOperation`, `beforeChange`, `afterChange` hooks for business logic.

## Directus (REST + GraphQL auto-API over any database)

```bash
npx create-directus-project@latest my-project
# Or Docker: docker run directus/directus
```

Directus wraps any SQL database with a REST and GraphQL API, plus a no-code admin UI. Best for teams where non-developers manage content schema. Use the JavaScript SDK or the generated client for typed queries.

## Strapi v5 (Node.js headless CMS)

```bash
pnpm create strapi@latest my-project
# Select: TypeScript, SQLite (dev) / PostgreSQL (prod), template
```

Strapi v5 introduced the Document Service API, replaced entity service. Content types defined via admin UI or code (JSON schema). Plugin system for extending core. REST and GraphQL APIs. Content Manager + Media Library included. Deploy on Strapi Cloud, Railway, or self-host with Docker.

## KeystoneJS (Next.js + Prisma-backed CMS)

```bash
pnpm create keystone-app@latest my-app
```

Keystone defines content schema in TypeScript, generates Prisma migrations, and provides a GraphQL API plus the Keystone Admin UI. Excellent choice when developers want full code control but still need an editorial interface.
