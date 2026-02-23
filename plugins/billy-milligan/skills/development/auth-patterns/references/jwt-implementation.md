# JWT Implementation

## Token Pair: Access + Refresh

```typescript
import jwt from 'jsonwebtoken';
import crypto from 'crypto';

const ACCESS_TOKEN_TTL = '15m';   // Short-lived
const REFRESH_TOKEN_TTL = '7d';   // Longer, rotated on use
const BCRYPT_ROUNDS = 12;         // ~300ms — deters brute force

interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

function issueTokens(userId: string, role: string): TokenPair {
  const accessToken = jwt.sign(
    { sub: userId, role, type: 'access' },
    process.env.JWT_ACCESS_SECRET!,
    { expiresIn: ACCESS_TOKEN_TTL, algorithm: 'HS256' }
  );

  // Refresh token: opaque random string, stored in DB
  const refreshToken = crypto.randomBytes(32).toString('hex');

  return { accessToken, refreshToken };
}
```

## Login with Timing Attack Prevention

```typescript
import bcrypt from 'bcrypt';

async function login(email: string, password: string): Promise<TokenPair> {
  const user = await db.users.findUnique({
    where: { email: email.toLowerCase() },
  });

  // CRITICAL: Always run bcrypt even if user not found
  // Prevents timing attacks that reveal valid email addresses
  const hashToCompare = user?.passwordHash
    ?? '$2b$12$invalidhashfortimingequalitypadding';
  const passwordValid = await bcrypt.compare(password, hashToCompare);

  if (!user || !passwordValid) {
    // Same error regardless of which check failed — prevents enumeration
    throw new UnauthorizedError('Invalid email or password');
  }

  if (user.lockedAt) {
    throw new ForbiddenError('Account locked. Contact support.');
  }

  // Store refresh token hash in DB
  const tokens = issueTokens(user.id, user.role);
  const refreshHash = crypto.createHash('sha256')
    .update(tokens.refreshToken).digest('hex');

  await db.refreshTokens.create({
    data: {
      userId: user.id,
      tokenHash: refreshHash,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    },
  });

  return tokens;
}
```

## Token Rotation

```typescript
async function refreshAccessToken(refreshToken: string): Promise<TokenPair> {
  const tokenHash = crypto.createHash('sha256')
    .update(refreshToken).digest('hex');

  const stored = await db.refreshTokens.findUnique({
    where: { tokenHash },
    include: { user: true },
  });

  if (!stored || stored.expiresAt < new Date()) {
    // Token not found or expired — could be stolen token reuse
    if (stored) {
      // Invalidate ALL refresh tokens for this user (security measure)
      await db.refreshTokens.deleteMany({ where: { userId: stored.userId } });
      logger.warn({ userId: stored.userId }, 'Refresh token reuse detected');
    }
    throw new UnauthorizedError('Invalid refresh token');
  }

  // Delete used token (one-time use)
  await db.refreshTokens.delete({ where: { id: stored.id } });

  // Issue new pair
  const tokens = issueTokens(stored.user.id, stored.user.role);
  const newHash = crypto.createHash('sha256')
    .update(tokens.refreshToken).digest('hex');

  await db.refreshTokens.create({
    data: {
      userId: stored.user.id,
      tokenHash: newHash,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    },
  });

  return tokens;
}
```

## httpOnly Cookie Transport

```typescript
// Set tokens in httpOnly cookies — not accessible via JavaScript
function setAuthCookies(res: Response, tokens: TokenPair) {
  res.cookie('access_token', tokens.accessToken, {
    httpOnly: true,      // Not accessible via document.cookie
    secure: true,        // HTTPS only
    sameSite: 'lax',     // CSRF protection
    maxAge: 15 * 60 * 1000,  // 15 minutes
    path: '/',
  });

  res.cookie('refresh_token', tokens.refreshToken, {
    httpOnly: true,
    secure: true,
    sameSite: 'lax',
    maxAge: 7 * 24 * 60 * 60 * 1000,  // 7 days
    path: '/auth/refresh',  // Only sent to refresh endpoint
  });
}

// Read from cookie in middleware
function extractToken(req: Request): string | null {
  return req.cookies?.access_token
    ?? req.headers.authorization?.replace('Bearer ', '')
    ?? null;
}
```

## Token Revocation

```typescript
// Revoke all sessions for a user (password change, security incident)
async function revokeAllSessions(userId: string) {
  await db.refreshTokens.deleteMany({ where: { userId } });
  // Access tokens expire in 15 minutes — acceptable window
  // For immediate revocation: use a token blocklist in Redis
}

// Redis blocklist for immediate access token revocation
async function revokeAccessToken(token: string) {
  const decoded = jwt.decode(token) as { exp: number };
  const ttl = decoded.exp - Math.floor(Date.now() / 1000);
  if (ttl > 0) {
    await redis.setex(`blocklist:${token}`, ttl, '1');
  }
}

// Check blocklist in auth middleware
async function isTokenRevoked(token: string): Promise<boolean> {
  return (await redis.exists(`blocklist:${token}`)) === 1;
}
```

## Anti-Patterns
- Storing JWT in localStorage — accessible via XSS, use httpOnly cookies
- Never-expiring access tokens — 30-day JWT = 30-day breach window
- Same error message omission — "User not found" vs "Wrong password" leaks info
- `===` for token comparison — timing attack; use `crypto.timingSafeEqual`
- Refresh token without rotation — stolen token usable forever

## Quick Reference
```
Access token: 15 min TTL, JWT, carries user ID + role
Refresh token: 7 day TTL, opaque random, stored as SHA-256 hash in DB
Rotation: delete used refresh token, issue new pair
Transport: httpOnly + secure + sameSite cookies
Revocation: delete refresh tokens + optional Redis blocklist for access
Timing safety: always run bcrypt even when user not found
bcrypt rounds: 12 (~300ms per hash)
User enumeration: same error for "not found" and "wrong password"
```
