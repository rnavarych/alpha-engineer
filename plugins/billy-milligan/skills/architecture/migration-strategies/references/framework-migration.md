# Framework Migration Patterns

## When to load
Load when discussing CRA to Next.js migration, Express to Fastify, REST to GraphQL, or any incremental framework migration using the strangler fig pattern.

## Patterns

### CRA -> Next.js (page-by-page)
```
Strategy: strangler fig pattern for frontend
Run both CRA and Next.js simultaneously, migrate page by page

Phase 1: Setup Next.js alongside CRA
Phase 2: Migrate shared components (design system, utils)
Phase 3: Migrate pages one at a time (start with least complex)
Phase 4: Move routing to Next.js, proxy unmigrated pages to CRA
Phase 5: Remove CRA when all pages migrated
```

```typescript
// next.config.js: proxy unmigrated routes to CRA
/** @type {import('next').NextConfig} */
const nextConfig = {
  async rewrites() {
    return {
      fallback: [
        {
          // Any route not handled by Next.js -> proxy to CRA
          source: '/:path*',
          destination: 'http://localhost:3001/:path*', // CRA dev server
        },
      ],
    };
  },
};

// Migration order (least risk first):
// 1. Static pages (about, terms, FAQ) -> getStaticProps
// 2. List pages (products, blog) -> getServerSideProps or ISR
// 3. Detail pages (product/:id) -> dynamic routes
// 4. Interactive pages (dashboard, settings) -> client components
// 5. Auth pages (login, register) -> last, highest risk
```

```typescript
// Migrating a CRA component to Next.js
// CRA (client-only):
// useEffect(() => { fetch('/api/products').then(...) }, []);

// Next.js (server-side data fetching):
// app/products/page.tsx
export default async function ProductsPage() {
  const products = await fetch('https://api.example.com/products', {
    next: { revalidate: 60 },  // ISR: revalidate every 60s
  }).then(r => r.json());

  return <ProductList products={products} />;
}

// Client components stay similar (add 'use client' directive)
'use client';
export function AddToCartButton({ productId }: { productId: string }) {
  const [loading, setLoading] = useState(false);
  // ... same React logic as CRA
}
```

### Express -> Fastify (route-by-route)
```typescript
// Strategy: run Fastify and Express together, migrate routes incrementally

// Step 1: Create Fastify instance with Express compatibility
import Fastify from 'fastify';
import expressPlugin from '@fastify/express';

const fastify = Fastify({ logger: true });
await fastify.register(expressPlugin);

// Step 2: Mount existing Express app as fallback
import { expressApp } from './legacy-express-app';
fastify.use(expressApp);  // Express handles unmigrated routes

// Step 3: Add new routes in Fastify (takes priority over Express)
fastify.get('/api/v2/products', {
  schema: {
    querystring: {
      type: 'object',
      properties: {
        limit: { type: 'integer', default: 20, maximum: 100 },
        offset: { type: 'integer', default: 0 },
      },
    },
    response: {
      200: {
        type: 'object',
        properties: {
          data: { type: 'array' },
          total: { type: 'integer' },
        },
      },
    },
  },
  handler: async (request, reply) => {
    const { limit, offset } = request.query;
    const products = await productService.list({ limit, offset });
    return { data: products.items, total: products.total };
  },
});

// Migration checklist per route:
// 1. Add Fastify route with schema validation
// 2. Migrate middleware to Fastify hooks (onRequest, preHandler)
// 3. Update tests to call Fastify route
// 4. Remove Express route
// 5. Verify in staging
```

```typescript
// Middleware migration: Express -> Fastify
fastify.addHook('onRequest', async (request, reply) => {
  const token = request.headers.authorization?.replace('Bearer ', '');
  if (!token) {
    reply.code(401).send({ error: 'Unauthorized' });
    return;
  }
  request.user = await verifyToken(token);
});

// Benefits of migration:
// - 2-3x faster request handling (Fastify benchmarks)
// - Schema-based validation (auto-generated, fast)
// - Built-in TypeScript support
// - Better plugin system (encapsulation)
```

### REST -> GraphQL (BFF pattern, parallel operation)
```typescript
// Strategy: GraphQL as Backend-for-Frontend, REST stays for B2B/external

import { createYoga, createSchema } from 'graphql-yoga';

const schema = createSchema({
  typeDefs: `
    type Product {
      id: ID!
      name: String!
      price: Float!
      category: Category!
      reviews: [Review!]!
    }
    type Query {
      product(id: ID!): Product
      products(limit: Int = 20, offset: Int = 0): [Product!]!
    }
  `,
  resolvers: {
    Query: {
      product: async (_, { id }) => fetch(`${REST_API}/products/${id}`).then(r => r.json()),
      products: async (_, { limit, offset }) =>
        fetch(`${REST_API}/products?limit=${limit}&offset=${offset}`).then(r => r.json()),
    },
    Product: {
      // N+1 prevented by DataLoader
      category: async (product) => categoryLoader.load(product.categoryId),
      reviews: async (product) => reviewLoader.load(product.id),
    },
  },
});

// Step 2: Frontend migrates to GraphQL queries one page at a time
// Step 3: GraphQL resolvers call services directly (skip REST proxy)
// Step 4: REST API maintained only for external/B2B consumers
```

## Anti-patterns
- Big-bang rewrite -> 6+ months of work, no value until done, high failure rate
- Migrating framework AND adding features -> do one at a time
- No tests before migration -> no way to verify feature parity
- Keeping both systems running indefinitely -> double maintenance cost
- Migrating internal tooling first -> migrate user-facing, highest-value pages first

## Decision criteria
- **CRA -> Next.js**: need SSR/SSG, SEO, API routes, image optimization, incremental adoption
- **Express -> Fastify**: need better performance, schema validation, TypeScript-first
- **REST -> GraphQL**: frontend needs flexible queries, multiple data sources, overfetching problem
- **Any migration**: only if current framework has a concrete limitation you have hit

## Quick reference
```
Strangler fig: new wraps old, migrate route by route
CRA -> Next.js: proxy unmigrated routes, migrate static pages first
Express -> Fastify: @fastify/express plugin, migrate route by route
REST -> GraphQL: BFF pattern, keep REST for external consumers
Migration order: static -> list -> detail -> interactive -> auth
Test coverage first: ensure parity before and after migration
```
