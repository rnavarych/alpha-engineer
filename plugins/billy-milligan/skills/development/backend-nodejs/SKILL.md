---
name: backend-nodejs
description: |
  Node.js backend patterns: Fastify with TypeBox validation, Express error handling,
  Zod validation middleware, global connection pool (create once), graceful shutdown,
  async error propagation, structured logging, environment configuration.
  Use when building Node.js APIs, reviewing backend code, setting up new services.
allowed-tools: Read, Grep, Glob
---

# Node.js Backend Patterns

## When to Use This Skill
- Building RESTful or GraphQL APIs in Node.js
- Setting up Fastify or Express with production configuration
- Implementing input validation with Zod or TypeBox
- Configuring database connection pools
- Error handling and graceful shutdown

## Core Principles

1. **Create connections once** — never create DB/Redis connections per request
2. **Validate at boundaries** — all external input validated with Zod/TypeBox before reaching business logic
3. **Catch async errors** — unhandled promise rejections crash Node.js
4. **Environment variables** — all configuration from `process.env`, validated at startup
5. **Graceful shutdown** — SIGTERM handler closes connections before exit

---

## Patterns ✅

### Fastify with TypeBox Validation

```typescript
import Fastify from 'fastify';
import { Type, Static } from '@sinclair/typebox';
import { TypeBoxTypeProvider } from '@fastify/type-provider-typebox';

const fastify = Fastify({
  logger: {
    level: process.env.LOG_LEVEL || 'info',
    serializers: {
      req(request) {
        return { method: request.method, url: request.url, requestId: request.id };
      },
    },
  },
}).withTypeProvider<TypeBoxTypeProvider>();

// Schema defined once, used for validation AND TypeScript types
const CreateOrderBody = Type.Object({
  customerId: Type.String({ format: 'uuid' }),
  items: Type.Array(Type.Object({
    productId: Type.String({ format: 'uuid' }),
    quantity: Type.Integer({ minimum: 1, maximum: 100 }),
  }), { minItems: 1 }),
  notes: Type.Optional(Type.String({ maxLength: 500 })),
});

const OrderResponse = Type.Object({
  id: Type.String(),
  status: Type.String(),
  total: Type.Number(),
  createdAt: Type.String({ format: 'date-time' }),
});

fastify.post('/orders', {
  schema: {
    body: CreateOrderBody,
    response: { 200: OrderResponse },
  },
  handler: async (request, reply) => {
    const order = await orderService.create(request.body);  // Fully typed
    return reply.code(201).send(order);
  },
});
```

### Express with Async Error Handling

```typescript
import express from 'express';
import 'express-async-errors';  // Patches express to handle async errors

const app = express();
app.use(express.json({ limit: '10mb' }));

// Validation middleware with Zod
import { z, ZodSchema } from 'zod';

function validate<T>(schema: ZodSchema<T>) {
  return (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      return res.status(400).json({
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Request validation failed',
          details: result.error.flatten().fieldErrors,
        },
      });
    }
    req.body = result.data;  // Replace with parsed/coerced data
    next();
  };
}

const createOrderSchema = z.object({
  customerId: z.string().uuid(),
  items: z.array(z.object({
    productId: z.string().uuid(),
    quantity: z.number().int().min(1).max(100),
  })).min(1),
});

app.post('/orders', validate(createOrderSchema), async (req, res) => {
  // req.body is now fully typed and validated
  const order = await orderService.create(req.body);
  res.status(201).json(order);
  // Throws? express-async-errors catches it and passes to error handler
});

// Global error handler (MUST be last middleware with 4 params)
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  const requestId = req.headers['x-request-id'] as string;

  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      error: { code: err.code, message: err.message, requestId },
    });
  }

  req.log?.error({ err, requestId }, 'Unhandled error');
  res.status(500).json({
    error: { code: 'INTERNAL_ERROR', message: 'An unexpected error occurred', requestId },
  });
});
```

### Database Connection Pool (Create Once)

```typescript
// db.ts — singleton, created once at startup
import { Pool } from 'pg';
import { drizzle } from 'drizzle-orm/node-postgres';

// Pool created ONCE — reused across all requests
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,                    // Max connections (tune: CPU cores × 2)
  min: 2,                     // Keep minimum alive
  idleTimeoutMillis: 30_000,  // Close idle connections after 30s
  connectionTimeoutMillis: 5_000,  // Fail fast if can't connect in 5s
  application_name: process.env.SERVICE_NAME,
});

export const db = drizzle(pool);

// Wrong: creating new pool per request
app.get('/users', async (req, res) => {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });  // Never do this
  // Each request creates a new pool, never cleaned up
  // Within minutes: too many connections error
});
```

### Environment Configuration (Validated at Startup)

```typescript
// config.ts — validate all env vars at startup, fail fast if missing
import { z } from 'zod';

const configSchema = z.object({
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  DATABASE_URL: z.string().url(),
  REDIS_URL: z.string().url(),
  JWT_ACCESS_SECRET: z.string().min(32, 'JWT secret must be at least 32 chars'),
  JWT_REFRESH_SECRET: z.string().min(32),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),
  STRIPE_SECRET_KEY: z.string().startsWith('sk_'),
});

const result = configSchema.safeParse(process.env);
if (!result.success) {
  console.error('Invalid environment configuration:');
  console.error(result.error.flatten().fieldErrors);
  process.exit(1);  // Fail fast — don't start with bad config
}

export const config = result.data;

// Usage everywhere — fully typed, validated
import { config } from './config';
const server = app.listen(config.PORT);
```

### Graceful Shutdown

```typescript
// server.ts
const server = app.listen(config.PORT, () => {
  logger.info({ port: config.PORT }, 'Server started');
});

let isShuttingDown = false;

async function shutdown(signal: string) {
  if (isShuttingDown) return;
  isShuttingDown = true;
  logger.info({ signal }, 'Shutdown initiated');

  // 1. Stop accepting new connections
  server.close(async () => {
    try {
      // 2. Close database pool
      await pool.end();
      logger.info('Database pool closed');

      // 3. Close Redis
      await redis.quit();
      logger.info('Redis connection closed');

      logger.info('Graceful shutdown complete');
      process.exit(0);
    } catch (err) {
      logger.error({ err }, 'Error during shutdown');
      process.exit(1);
    }
  });

  // Force exit if graceful shutdown takes too long
  setTimeout(() => {
    logger.error('Shutdown timeout — forcing exit');
    process.exit(1);
  }, 30_000);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

// Catch unhandled rejections (don't let them crash silently)
process.on('unhandledRejection', (reason, promise) => {
  logger.error({ reason, promise }, 'Unhandled promise rejection');
  // In production: consider shutdown(). At minimum: log and alert.
});
```

---

## Anti-Patterns ❌

### Creating DB Connections Per Request
**What it is**: `new Pool(...)` or `mongoose.connect(...)` inside a request handler.
**What breaks**: PostgreSQL has a hard limit of ~100 connections before memory issues. Each new Pool() creates its own connections. Under load: "too many connections" error. Database becomes unavailable.
**Fix**: Create pool once at startup. Import the pool singleton in handlers.

### Not Handling Async Errors in Express
**What it is**: `app.get('/thing', async (req, res) => { throw new Error() })`
**What breaks**: Express 4 does not catch async errors automatically. Unhandled rejection crashes the process or hangs the request forever.
**Fix**: `express-async-errors` package, or wrap every async handler with `asyncHandler(fn)`, or upgrade to Express 5.

### Missing Input Validation
**What it is**: Using `req.body.userId` directly without validation.
**What breaks**: SQL injection, type coercion bugs, crashes from unexpected types. `req.body` is completely untyped in Express.
**Fix**: Zod schema + validation middleware before every route that accepts input.

### No Environment Variable Validation
**What it is**: Accessing `process.env.DATABASE_URL` without checking it exists.
**What breaks**: Service starts with `undefined` database URL. First database operation fails. Often discovered in production, not locally.
**Fix**: Zod schema validation at startup. Exit if required vars are missing.

---

## Quick Reference

```
Pool max connections: CPU cores × 2 (or 20 as safe default)
Pool connection timeout: 5000ms — fail fast
Pool idle timeout: 30000ms — release unused connections
Express async errors: use express-async-errors package
Validation: Zod at route level, validated before business logic
Config validation: Zod schema on process.env at startup — exit(1) if invalid
Graceful shutdown timeout: 30s force exit after SIGTERM
Health check: verify pool connectivity, not just process alive
```
