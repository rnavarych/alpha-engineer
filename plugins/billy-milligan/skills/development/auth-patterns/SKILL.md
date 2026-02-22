---
name: auth-patterns
description: |
  Authentication patterns: JWT implementation with timing attack prevention, RBAC middleware,
  NextAuth.js/Auth.js OAuth setup, user enumeration prevention, session management,
  MFA patterns, OAuth 2.0 PKCE flow. Use when implementing auth, reviewing auth code,
  choosing auth strategy.
allowed-tools: Read, Grep, Glob
---

# Authentication Patterns

## When to Use This Skill
- Implementing JWT authentication from scratch
- Setting up OAuth with NextAuth.js/Auth.js
- Implementing Role-Based Access Control (RBAC)
- Preventing user enumeration and timing attacks
- Designing multi-factor authentication

## Core Principles

1. **Prevent user enumeration** — login errors must be identical for "user not found" and "wrong password"
2. **Constant-time comparison** — always use `crypto.timingSafeEqual` for token comparison
3. **Short-lived access tokens** — 15 minutes max; refresh tokens rotate on use
4. **RBAC at middleware level** — authorization check before business logic, not inside it
5. **Never trust the client** — re-verify permissions on every request, not just at login

---

## Patterns ✅

### JWT Authentication (Timing Attack Safe)

```typescript
import * as jwt from 'jsonwebtoken';
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';

const ACCESS_TOKEN_TTL = '15m';
const REFRESH_TOKEN_TTL = '7d';
const BCRYPT_ROUNDS = 12;  // ~300ms — slow enough to deter brute force

export async function login(email: string, password: string) {
  // Always fetch user first — prevents timing difference revealing user existence
  const user = await db.users.findUnique({ where: { email: email.toLowerCase() } });

  // CRITICAL: Always run bcrypt even if user not found
  // This prevents timing attacks that reveal valid email addresses
  const hashToCompare = user?.passwordHash ?? '$2b$12$invalidhashfortimingequalityXXXX';
  const passwordValid = await bcrypt.compare(password, hashToCompare);

  if (!user || !passwordValid) {
    // Same error message regardless of which check failed — prevents enumeration
    throw new UnauthorizedError('Invalid email or password');
  }

  if (user.lockedAt) {
    throw new ForbiddenError('Account is locked. Contact support.');
  }

  return issueTokens(user.id, user.role);
}

function issueTokens(userId: string, role: string) {
  const accessToken = jwt.sign(
    { sub: userId, role, type: 'access' },
    process.env.JWT_ACCESS_SECRET!,
    { expiresIn: ACCESS_TOKEN_TTL, algorithm: 'HS256' }
  );

  const refreshToken = crypto.randomBytes(32).toString('hex');

  return { accessToken, refreshToken };
}

export function verifyAccessToken(token: string): { sub: string; role: string } {
  try {
    const payload = jwt.verify(token, process.env.JWT_ACCESS_SECRET!) as any;
    if (payload.type !== 'access') throw new Error('Wrong token type');
    return { sub: payload.sub, role: payload.role };
  } catch {
    throw new UnauthorizedError('Invalid or expired token');
  }
}
```

### Express Auth Middleware

```typescript
// Authentication middleware — sets req.user
export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Authentication required' } });
  }

  const token = authHeader.substring(7);
  try {
    req.user = verifyAccessToken(token);
    next();
  } catch {
    res.status(401).json({ error: { code: 'UNAUTHORIZED', message: 'Invalid token' } });
  }
}

// RBAC middleware — checks role or permission
export function requireRole(...roles: string[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({ error: { code: 'UNAUTHORIZED' } });
    }
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        error: { code: 'FORBIDDEN', message: `Required role: ${roles.join(' or ')}` },
      });
    }
    next();
  };
}

// Usage
app.get('/admin/users', requireAuth, requireRole('admin'), listUsersHandler);
app.post('/orders', requireAuth, requireRole('admin', 'staff', 'customer'), createOrderHandler);
app.delete('/orders/:id', requireAuth, requireRole('admin'), deleteOrderHandler);
```

### Permission-Based RBAC

```typescript
// More granular than role-based: permissions per action
const PERMISSIONS = {
  'orders:read': ['customer', 'staff', 'admin'],
  'orders:write': ['staff', 'admin'],
  'orders:delete': ['admin'],
  'users:read': ['admin'],
  'users:write': ['admin'],
} as const;

type Permission = keyof typeof PERMISSIONS;

export function requirePermission(permission: Permission) {
  return (req: Request, res: Response, next: NextFunction) => {
    const userRole = req.user?.role;
    const allowedRoles = PERMISSIONS[permission] as readonly string[];

    if (!userRole || !allowedRoles.includes(userRole)) {
      return res.status(403).json({
        error: { code: 'FORBIDDEN', message: `Missing permission: ${permission}` },
      });
    }
    next();
  };
}

// Usage
app.get('/orders', requireAuth, requirePermission('orders:read'), listOrdersHandler);
```

### NextAuth.js / Auth.js Setup

```typescript
// app/api/auth/[...nextauth]/route.ts
import NextAuth from 'next-auth';
import Google from 'next-auth/providers/google';
import GitHub from 'next-auth/providers/github';
import Credentials from 'next-auth/providers/credentials';
import { DrizzleAdapter } from '@auth/drizzle-adapter';
import { db } from '@/db';

const { handlers, auth, signIn, signOut } = NextAuth({
  adapter: DrizzleAdapter(db),
  providers: [
    Google({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),
    GitHub({
      clientId: process.env.GITHUB_CLIENT_ID!,
      clientSecret: process.env.GITHUB_CLIENT_SECRET!,
    }),
    Credentials({
      credentials: {
        email: { type: 'email' },
        password: { type: 'password' },
      },
      authorize: async (credentials) => {
        if (!credentials?.email || !credentials?.password) return null;
        return login(credentials.email as string, credentials.password as string)
          .catch(() => null);  // Return null for invalid credentials (no throw)
      },
    }),
  ],
  callbacks: {
    jwt({ token, user }) {
      if (user) {
        token.role = (user as any).role;  // Persist role in JWT
      }
      return token;
    },
    session({ session, token }) {
      session.user.role = token.role as string;
      return session;
    },
  },
  pages: {
    signIn: '/auth/login',
    error: '/auth/error',
  },
});

export { handlers as GET, handlers as POST };
```

```typescript
// Protect routes with middleware
// middleware.ts
import { auth } from '@/auth';
import { NextResponse } from 'next/server';

export default auth((req) => {
  const isLoggedIn = !!req.auth;
  const isProtected = req.nextUrl.pathname.startsWith('/dashboard');

  if (isProtected && !isLoggedIn) {
    return NextResponse.redirect(new URL('/auth/login', req.nextUrl));
  }
});

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
```

### Password Reset (Token-Based)

```typescript
async function requestPasswordReset(email: string) {
  const user = await db.users.findUnique({ where: { email } });

  // Always return success — don't reveal if email exists
  if (!user) return;  // Silent return, same response to client

  const resetToken = crypto.randomBytes(32).toString('hex');
  const resetTokenHash = crypto.createHash('sha256').update(resetToken).digest('hex');

  await db.passwordResets.upsert({
    where: { userId: user.id },
    create: {
      userId: user.id,
      tokenHash: resetTokenHash,
      expiresAt: new Date(Date.now() + 3600_000),  // 1 hour
    },
    update: {
      tokenHash: resetTokenHash,
      expiresAt: new Date(Date.now() + 3600_000),
    },
  });

  await emailService.sendPasswordReset(user.email, resetToken);
}
```

---

## Anti-Patterns ❌

### User Enumeration via Different Error Messages
**What it is**: "User not found" vs "Incorrect password" — two different messages.
**What breaks**: Attacker knows which emails are registered. Can target those accounts specifically. Can sell valid email list.
**Fix**: Always "Invalid email or password" regardless of which check failed.

### Timing Attack on Token Comparison
**What it is**: `if (token === storedToken)` — JavaScript string comparison short-circuits.
**What breaks**: Attacker can measure microsecond differences to guess tokens one character at a time.
**Fix**: `crypto.timingSafeEqual(Buffer.from(token), Buffer.from(storedToken))` — always compares all bytes.

### Authorization Check Inside Business Logic
**What it is**: `if (user.role === 'admin') { /* admin action */ } else { /* or throw */ }` inside a service function.
**What breaks**: Authorization logic spread across codebase. Easy to forget in one place. Hard to audit.
**Fix**: Authorization middleware at route level. Service functions assume caller is authorized.

### Never-Expiring Access Tokens
**What it is**: `jwt.sign({...}, secret, { expiresIn: '30d' })`
**What breaks**: Token stolen → attacker has 30 days. No way to revoke JWT without blocklist. Breach window = token lifetime.
**Fix**: Access tokens 15 minutes. Refresh tokens for long sessions, rotate on use.

---

## Quick Reference

```
bcrypt rounds: 12 (~300ms) — not faster, not slower
Access token TTL: 15 minutes
Refresh token TTL: 7 days, rotated on every use
User enumeration: same error message for "not found" and "wrong password"
Timing attacks: always run bcrypt even when user not found
RBAC: middleware layer, not inside business logic
Password reset token: 32 random bytes, store SHA-256 hash, 1h expiry
```
