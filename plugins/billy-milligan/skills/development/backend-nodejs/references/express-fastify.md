# Express & Fastify Patterns

## Fastify with TypeBox

```typescript
import Fastify from 'fastify';
import { Type, Static } from '@sinclair/typebox';
import { TypeBoxTypeProvider } from '@fastify/type-provider-typebox';

const app = Fastify({
  logger: {
    level: process.env.LOG_LEVEL || 'info',
    transport: process.env.NODE_ENV === 'development'
      ? { target: 'pino-pretty' }
      : undefined,
  },
}).withTypeProvider<TypeBoxTypeProvider>();

// Schema = validation + TypeScript type in one declaration
const CreateOrderBody = Type.Object({
  customerId: Type.String({ format: 'uuid' }),
  items: Type.Array(
    Type.Object({
      productId: Type.String({ format: 'uuid' }),
      quantity: Type.Integer({ minimum: 1, maximum: 100 }),
    }),
    { minItems: 1 }
  ),
});

const OrderResponse = Type.Object({
  id: Type.String(),
  status: Type.String(),
  total: Type.Number(),
  createdAt: Type.String({ format: 'date-time' }),
});

app.post('/orders', {
  schema: {
    body: CreateOrderBody,
    response: { 201: OrderResponse },
  },
  handler: async (request, reply) => {
    // request.body is fully typed from TypeBox schema
    const order = await orderService.create(request.body);
    return reply.code(201).send(order);
  },
});
```

## Express with Zod Middleware

```typescript
import express from 'express';
import 'express-async-errors';
import { z, ZodSchema } from 'zod';

const app = express();
app.use(express.json({ limit: '10mb' }));

// Validation middleware — reusable across routes
function validate<T>(schema: ZodSchema<T>) {
  return (req: express.Request, res: express.Response, next: express.NextFunction) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      return res.status(400).json({
        error: {
          code: 'VALIDATION_ERROR',
          details: result.error.flatten().fieldErrors,
        },
      });
    }
    req.body = result.data;
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
  const order = await orderService.create(req.body);
  res.status(201).json(order);
});
```

## Global Error Handler

```typescript
// Must be last middleware — 4 parameters required
app.use((err: Error, req: express.Request, res: express.Response, _next: express.NextFunction) => {
  const requestId = req.headers['x-request-id'] as string;

  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      error: { code: err.code, message: err.message, requestId },
    });
  }

  logger.error({ err, requestId }, 'Unhandled error');
  res.status(500).json({
    error: { code: 'INTERNAL_ERROR', message: 'An unexpected error occurred', requestId },
  });
});
```

## Graceful Shutdown

```typescript
const server = app.listen(config.PORT, () => {
  logger.info({ port: config.PORT }, 'Server started');
});

let isShuttingDown = false;

async function shutdown(signal: string) {
  if (isShuttingDown) return;
  isShuttingDown = true;
  logger.info({ signal }, 'Shutdown initiated');

  server.close(async () => {
    await pool.end();
    await redis.quit();
    logger.info('Graceful shutdown complete');
    process.exit(0);
  });

  setTimeout(() => {
    logger.error('Shutdown timeout — forcing exit');
    process.exit(1);
  }, 30_000);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
```

## Anti-Patterns
- Express without `express-async-errors` — async throws crash the process
- Missing global error handler — unhandled errors return raw stack traces
- No request ID propagation — impossible to trace requests through logs
- JSON body limit not set — enables DoS via large payloads
