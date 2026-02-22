---
name: security-architecture
description: |
  Security architecture: JWT with 15min access + refresh rotation, bcrypt rounds=12 (~300ms),
  secrets management (never in code), RLS for multi-tenancy, security headers (helmet.js),
  SQL injection prevention, IDOR prevention, input validation. OWASP Top 10 coverage.
  Use when designing auth flows, reviewing security posture, implementing multi-tenancy.
allowed-tools: Read, Grep, Glob
---

# Security Architecture

## When to Use This Skill
- Designing authentication and authorization flows
- Reviewing code for OWASP Top 10 vulnerabilities
- Implementing multi-tenant data isolation
- Setting security headers for web applications
- Secrets management strategy

## Core Principles

1. **Never store secrets in code** — environment variables, not hardcoded strings
2. **bcrypt with 12 rounds** — ~300ms hashing time, good balance vs brute force
3. **JWT access tokens: 15 minutes** — short-lived; refresh tokens: 7–30 days, rotated
4. **Row-Level Security for multi-tenant isolation** — DB enforces isolation, not just application
5. **Validate at boundaries** — trust nothing from outside your process

---

## Patterns ✅

### JWT Authentication with Refresh Token Rotation

```typescript
// Access token: 15 minutes (short — limits breach window)
// Refresh token: 7 days (stored in DB, rotated on use)

const ACCESS_TOKEN_TTL = '15m';
const REFRESH_TOKEN_TTL = '7d';

async function login(email: string, password: string) {
  const user = await db.users.findUnique({ where: { email } });
  if (!user) {
    // Constant-time comparison to prevent user enumeration via timing
    await bcrypt.compare(password, '$2b$12$invalidhashforconstanttimeXXXXXXXXXXXXXXXXXXX');
    throw new UnauthorizedError('Invalid credentials');
  }

  const valid = await bcrypt.compare(password, user.passwordHash);
  if (!valid) throw new UnauthorizedError('Invalid credentials');

  const accessToken = jwt.sign(
    { sub: user.id, role: user.role, type: 'access' },
    process.env.JWT_ACCESS_SECRET!,
    { expiresIn: ACCESS_TOKEN_TTL, algorithm: 'HS256' }
  );

  const refreshToken = crypto.randomBytes(32).toString('hex');
  const refreshTokenHash = crypto.createHash('sha256').update(refreshToken).digest('hex');

  await db.refreshTokens.create({
    data: {
      tokenHash: refreshTokenHash,
      userId: user.id,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    },
  });

  return { accessToken, refreshToken };
}

async function refreshAccessToken(refreshToken: string) {
  const tokenHash = crypto.createHash('sha256').update(refreshToken).digest('hex');

  const stored = await db.refreshTokens.findUnique({
    where: { tokenHash },
    include: { user: true },
  });

  if (!stored || stored.expiresAt < new Date() || stored.revokedAt) {
    // Detect refresh token reuse — potential compromise
    if (stored?.revokedAt) {
      await db.refreshTokens.updateMany({
        where: { userId: stored.userId },
        data: { revokedAt: new Date() },  // Revoke all user's tokens
      });
      throw new SecurityError('Refresh token reuse detected — all tokens revoked');
    }
    throw new UnauthorizedError('Invalid refresh token');
  }

  // Rotate: revoke old token, issue new one
  await db.refreshTokens.update({
    where: { id: stored.id },
    data: { revokedAt: new Date() },
  });

  const newRefreshToken = crypto.randomBytes(32).toString('hex');
  const newHash = crypto.createHash('sha256').update(newRefreshToken).digest('hex');
  await db.refreshTokens.create({
    data: { tokenHash: newHash, userId: stored.userId, expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) }
  });

  const accessToken = jwt.sign(
    { sub: stored.user.id, role: stored.user.role, type: 'access' },
    process.env.JWT_ACCESS_SECRET!,
    { expiresIn: ACCESS_TOKEN_TTL }
  );

  return { accessToken, refreshToken: newRefreshToken };
}
```

### Password Hashing

```typescript
// bcrypt with 12 rounds = ~300ms
// Why 300ms? Too fast (8 rounds, 10ms) → GPU brute force viable
//            Too slow (14 rounds, 1200ms) → login endpoint bottleneck

const BCRYPT_ROUNDS = 12;

async function hashPassword(plaintext: string): Promise<string> {
  return bcrypt.hash(plaintext, BCRYPT_ROUNDS);
}

async function verifyPassword(plaintext: string, hash: string): Promise<boolean> {
  return bcrypt.compare(plaintext, hash);
}

// Never store plaintext. Never use MD5/SHA1/SHA256 for passwords.
// Never use fast hashing algorithms for passwords — their speed is the vulnerability.
```

### Row-Level Security (Multi-Tenant Isolation)

```sql
-- PostgreSQL RLS: DB enforces tenant isolation, not just application code
-- Even if application bug allows wrong tenant_id in query, DB rejects it

-- Enable RLS on tenant-scoped table
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Policy: users can only see their own tenant's data
CREATE POLICY tenant_isolation ON orders
  USING (tenant_id = current_setting('app.current_tenant_id')::uuid);

-- Application sets tenant ID at connection/transaction level
-- (using SET LOCAL so it's transaction-scoped)
```

```typescript
// Set tenant context before any query in multi-tenant request
async function withTenantContext<T>(tenantId: string, fn: () => Promise<T>): Promise<T> {
  return db.transaction(async (tx) => {
    await tx.execute(sql`SET LOCAL app.current_tenant_id = ${tenantId}`);
    return fn();
  });
}

// Usage in request handler
app.use(async (req, res, next) => {
  const tenantId = req.user?.tenantId;
  if (!tenantId) return res.status(401).end();
  req.db = createTenantDb(tenantId);  // Db client with tenant context
  next();
});
```

### Security Headers (Helmet.js)

```typescript
import helmet from 'helmet';

app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'nonce-${nonce}'"],  // nonce per request
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", 'data:', 'https://cdn.example.com'],
      connectSrc: ["'self'", 'https://api.example.com'],
      frameSrc: ["'none'"],
      objectSrc: ["'none'"],
    },
  },
  hsts: {
    maxAge: 31536000,       // 1 year
    includeSubDomains: true,
    preload: true,
  },
  referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
  xContentTypeOptions: true,  // X-Content-Type-Options: nosniff
  xFrameOptions: { action: 'deny' },  // X-Frame-Options: DENY
}));
```

### SQL Injection Prevention

```typescript
// Always use parameterized queries — never string interpolation

// Wrong — injectable
const userId = req.params.id;
const result = await db.query(`SELECT * FROM users WHERE id = '${userId}'`);
// Payload: ' OR '1'='1  → returns all users

// Correct — parameterized (Drizzle, Prisma, pg, all do this)
const user = await db.select().from(users).where(eq(users.id, userId));

// If you must use raw SQL (rare)
const result = await db.execute(sql`SELECT * FROM users WHERE id = ${userId}`);
// The sql template tag auto-parameterizes — safe
```

### IDOR Prevention (Object-Level Authorization)

```typescript
// IDOR: Insecure Direct Object Reference
// Wrong: trust the ID in the request
app.get('/orders/:id', async (req, res) => {
  const order = await db.orders.findUnique({ where: { id: req.params.id } });
  res.json(order);  // Any user can see any order by guessing ID
});

// Correct: always scope queries to the authenticated user
app.get('/orders/:id', requireAuth, async (req, res) => {
  const order = await db.orders.findUnique({
    where: {
      id: req.params.id,
      userId: req.user.id,  // Must belong to current user
    },
  });
  if (!order) return res.status(404).json({ error: { code: 'NOT_FOUND' } });
  res.json(order);
});
```

---

## Anti-Patterns ❌

### Secrets in Code
**What breaks**: Secret committed to git → every git clone, every CI log, every GitHub fork has the secret. Even after deletion, git history preserves it.
**Detection**: `git log -p | grep -i "secret\|password\|key\|token"` — run before every PR merge.
**Fix**: Environment variables. In production: AWS Secrets Manager, GCP Secret Manager, HashiCorp Vault.

### Long-Lived Access Tokens
**What it is**: JWT with 24h or 30-day expiry.
**What breaks**: Token theft → attacker has 24h (or 30 days) of access. No way to revoke a valid JWT without a blocklist.
**Fix**: 15-minute access tokens + refresh rotation. Breach window limited to 15 minutes.

### MD5 or SHA for Passwords
**What breaks**: GPU can compute 10 billion MD5 hashes per second. A 1M-entry password database with MD5 hashes cracked in minutes with a dictionary attack.
**Fix**: bcrypt (12 rounds), Argon2id, or scrypt. These are intentionally slow.

### Trusting User-Supplied Tenant ID
**What it is**: Reading `tenantId` from request body or query param, using it to scope queries.
**What breaks**: Attacker sends any tenant ID → sees all data for that tenant.
**Fix**: Tenant ID comes from verified JWT claim or session, never from user input.

---

## Quick Reference

```
JWT access TTL: 15 minutes
JWT refresh TTL: 7 days, rotate on use, store hash not raw token
bcrypt rounds: 12 (~300ms) — 10 is too fast, 14 is too slow for APIs
RLS: SET LOCAL app.current_tenant_id per transaction
SQL injection: always parameterized queries — never string concatenation
IDOR: scope every query to authenticated user
Security headers: Content-Security-Policy, HSTS, X-Frame-Options, nosniff
Secrets: never in code — environment variables, then Vault/SSM/Secret Manager
```
