# Node.js Security

## Input Validation with Zod

```typescript
import { z } from 'zod';

// Validate ALL external input — never trust req.body/params/query
const createUserSchema = z.object({
  email: z.string().email().max(255).transform((e) => e.toLowerCase()),
  name: z.string().min(1).max(100).trim(),
  role: z.enum(['user', 'editor']),  // Restrict to allowed values
  age: z.number().int().min(13).max(150).optional(),
});

// Sanitize HTML to prevent XSS
const commentSchema = z.object({
  content: z.string()
    .max(5000)
    .transform((s) => sanitizeHtml(s, { allowedTags: ['b', 'i', 'a'] })),
});

// Path parameters — always validate format
const idParamSchema = z.object({
  id: z.string().uuid(), // Prevents SQL injection via malformed IDs
});
```

## Rate Limiting

```typescript
import rateLimit from 'express-rate-limit';
import RedisStore from 'rate-limit-redis';

// Global rate limit
app.use(rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,                   // 100 requests per window per IP
  standardHeaders: true,
  legacyHeaders: false,
  store: new RedisStore({ sendCommand: (...args) => redis.call(...args) }),
}));

// Stricter limit for auth endpoints
app.use('/auth/login', rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,                     // 5 login attempts per 15 minutes
  message: { error: { code: 'RATE_LIMITED', message: 'Too many login attempts' } },
}));

// API key rate limiting — per key, not per IP
app.use('/api/v1', rateLimit({
  windowMs: 60 * 1000,
  max: 60,                    // 60 requests per minute per API key
  keyGenerator: (req) => req.headers['x-api-key'] as string || req.ip,
}));
```

## CORS Configuration

```typescript
import cors from 'cors';

// Production — explicit origins only
app.use(cors({
  origin: [
    'https://app.example.com',
    'https://admin.example.com',
  ],
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-ID'],
  credentials: true,          // Allow cookies
  maxAge: 86400,               // Cache preflight for 24h
}));

// NEVER in production:
// app.use(cors({ origin: '*' }));  // Allows any origin
// app.use(cors());                 // Same — allows everything
```

## Helmet Security Headers

```typescript
import helmet from 'helmet';

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],          // No inline scripts
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", 'https://cdn.example.com'],
      connectSrc: ["'self'", 'https://api.example.com'],
    },
  },
  hsts: {
    maxAge: 31536000,                // 1 year
    includeSubDomains: true,
    preload: true,
  },
}));
// Sets: X-Content-Type-Options, X-Frame-Options, X-XSS-Protection, CSP, HSTS
```

## Dependency Audit

```bash
# Check for known vulnerabilities
npm audit

# Auto-fix where possible
npm audit fix

# Check for outdated dependencies
npm outdated

# Use Socket.dev or Snyk for CI pipeline
npx socket-security audit
```

## Environment Variable Validation

```typescript
import { z } from 'zod';

const envSchema = z.object({
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  DATABASE_URL: z.string().url(),
  REDIS_URL: z.string().url(),
  JWT_SECRET: z.string().min(32, 'JWT secret must be at least 32 characters'),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  ALLOWED_ORIGINS: z.string().transform((s) => s.split(',')),
});

const result = envSchema.safeParse(process.env);
if (!result.success) {
  console.error('Invalid environment:', result.error.flatten().fieldErrors);
  process.exit(1);
}
export const config = result.data;
```

## Anti-Patterns
- `cors({ origin: '*' })` in production — allows any website to call your API
- No rate limiting on login — enables brute force attacks
- Trusting `req.body` without validation — injection, type confusion
- Secrets in code or git — use env vars, validate at startup

## Quick Reference
```
Validation: Zod on every route — safeParse for API, parse for internal
Rate limit: 100/15min global, 5/15min login, per-key for APIs
CORS: explicit origins array, credentials: true for cookies
Helmet: CSP, HSTS, X-Frame-Options — one middleware, all headers
Audit: npm audit in CI, fail build on critical vulnerabilities
Env vars: Zod schema at startup — exit(1) if missing
```
