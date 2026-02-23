# OWASP Top 10 Reference

## When to load
Load when discussing web application security for A01–A05: broken access control, cryptographic failures, injection, insecure design, or security misconfiguration.

## Patterns

### A01: Broken Access Control
```typescript
// Prevention: enforce authorization on every request
// Never rely on client-side checks alone
async function getOrder(orderId: string, userId: string) {
  const order = await db.orders.findById(orderId);
  if (order.userId !== userId && !user.roles.includes('admin')) {
    throw new ForbiddenError('Not authorized to view this order');
  }
  return order;
}

// IDOR prevention: always check ownership
// Rate limiting on sensitive endpoints
// Disable directory listing: X-Content-Type-Options: nosniff
// CORS: restrictive allowOrigin, never wildcard with credentials
```

### A02: Cryptographic Failures
```typescript
// Prevention: encrypt PII at rest, enforce TLS in transit
// Use strong algorithms: AES-256-GCM, argon2id for passwords
// Never: MD5, SHA1 for passwords, custom crypto
// Always: HTTPS, HSTS header, secure cookie flag

const passwordHash = await argon2.hash(password, {
  type: argon2.argon2id,
  memoryCost: 65536,  // 64MB
  timeCost: 3,
  parallelism: 4,
});
```

### A03: Injection
```typescript
// SQL injection prevention: parameterized queries ALWAYS
// NEVER concatenate user input into queries
const user = await db.query(
  'SELECT * FROM users WHERE email = $1',  // parameterized
  [userInput.email]
);

// NoSQL injection prevention
const user = await db.users.findOne({
  email: { $eq: sanitizedEmail },  // explicit operator
});

// Command injection prevention
import { execFile } from 'child_process';  // execFile, not exec
execFile('convert', [inputFile, outputFile]);  // args as array
```

### A04: Insecure Design
```
Prevention:
- Threat modeling during design phase (STRIDE)
- Rate limiting on auth endpoints (5 attempts per 15 min)
- Business logic abuse: limit gift card redemptions per account
- Use security design patterns: input validation, output encoding
- Security requirements in user stories
```

### A05: Security Misconfiguration
```typescript
// Helmet.js for Express security headers
import helmet from 'helmet';
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],  // no 'unsafe-inline'
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", 'data:', 'https:'],
    }
  },
  hsts: { maxAge: 63072000, includeSubDomains: true, preload: true },
}));

// Disable stack traces in production
app.use((err, req, res, next) => {
  const status = err.status || 500;
  res.status(status).json({
    error: status === 500 ? 'Internal server error' : err.message,
    // NEVER: stack: err.stack (exposes internals)
  });
});
```

## Anti-patterns
- Security as afterthought -> build into design phase
- Relying on WAF alone -> defense in depth, application-level checks required
- Generic error messages hiding all detail -> log detail server-side, return safe message to client
- Disabling security headers for convenience -> use proper CSP instead of removing headers

## Quick reference
```
A01 Access Control: check ownership on every request, RBAC
A02 Crypto: AES-256-GCM, argon2id, TLS 1.2+, no MD5/SHA1
A03 Injection: parameterized queries, never string concat
A04 Design: threat model (STRIDE), rate limit auth
A05 Misconfig: helmet.js, no stack traces, CSP headers
```
