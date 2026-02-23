# Authentication & Authorization Patterns

## When to load
Load when discussing JWT, sessions, OAuth2/OIDC, API key auth, mTLS, or building authentication/authorization systems.

## Patterns

### JWT (stateless, API-first)
```typescript
// Access token: 15min, contains claims
// Refresh token: 7 days, rotate on use, stored in DB
interface JWTPayload {
  sub: string;        // user ID
  email: string;
  roles: string[];
  iat: number;
  exp: number;        // 15 minutes from iat
}

// Token generation
function generateTokens(user: User) {
  const accessToken = jwt.sign(
    { sub: user.id, email: user.email, roles: user.roles },
    process.env.JWT_SECRET,
    { expiresIn: '15m', algorithm: 'RS256' }  // RS256 for asymmetric
  );
  const refreshToken = crypto.randomBytes(64).toString('hex');
  // Store refresh token hash in DB with userId, expiresAt, family
  return { accessToken, refreshToken };
}

// Refresh token rotation (detect reuse = compromise)
async function rotateRefreshToken(oldToken: string) {
  const stored = await db.refreshTokens.findByHash(hashToken(oldToken));
  if (!stored || stored.usedAt) {
    // Token reuse detected - revoke entire family
    await db.refreshTokens.revokeFamily(stored.familyId);
    throw new AuthError('TOKEN_REUSE_DETECTED');
  }
  await db.refreshTokens.markUsed(stored.id);
  return generateTokens(stored.user);
}
```

### Session-based (server-side, traditional web)
```typescript
// Redis session store
import session from 'express-session';
import RedisStore from 'connect-redis';

app.use(session({
  store: new RedisStore({ client: redis, prefix: 'sess:' }),
  secret: process.env.SESSION_SECRET,
  name: '__session',
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: true,          // HTTPS only
    httpOnly: true,         // no JS access
    sameSite: 'lax',        // CSRF protection
    maxAge: 24 * 60 * 60 * 1000,  // 24 hours
    domain: '.example.com', // shared across subdomains
  },
}));
```
Use sessions when: server-rendered apps, need instant revocation, simpler mental model.

### OAuth2/OIDC (Authorization Code + PKCE)
```typescript
// PKCE flow for SPAs and mobile (no client secret needed)
// 1. Generate code_verifier and code_challenge
const codeVerifier = crypto.randomBytes(32).toString('base64url');
const codeChallenge = crypto
  .createHash('sha256')
  .update(codeVerifier)
  .digest('base64url');

// 2. Redirect to authorization server
const authUrl = new URL('https://auth.example.com/authorize');
authUrl.searchParams.set('response_type', 'code');
authUrl.searchParams.set('client_id', CLIENT_ID);
authUrl.searchParams.set('redirect_uri', REDIRECT_URI);
authUrl.searchParams.set('scope', 'openid profile email');
authUrl.searchParams.set('code_challenge', codeChallenge);
authUrl.searchParams.set('code_challenge_method', 'S256');
authUrl.searchParams.set('state', csrfToken);

// 3. Exchange code for tokens (server-side)
const tokenResponse = await fetch('https://auth.example.com/token', {
  method: 'POST',
  body: new URLSearchParams({
    grant_type: 'authorization_code',
    code: authorizationCode,
    redirect_uri: REDIRECT_URI,
    client_id: CLIENT_ID,
    code_verifier: codeVerifier,
  }),
});
```

### API keys (service-to-service, developer APIs)
```typescript
// API key: hash before storing, prefix for identification
function generateApiKey(): { key: string; hash: string } {
  const prefix = 'sk_live_';  // sk_test_ for sandbox
  const secret = crypto.randomBytes(32).toString('hex');
  const key = `${prefix}${secret}`;
  const hash = crypto.createHash('sha256').update(key).digest('hex');
  return { key, hash };  // show key once, store hash
}

// Middleware: validate API key
async function apiKeyAuth(req: Request, res: Response, next: NextFunction) {
  const key = req.headers['x-api-key'] || req.headers.authorization?.replace('Bearer ', '');
  if (!key) return res.status(401).json({ error: 'API key required' });

  const hash = crypto.createHash('sha256').update(key).digest('hex');
  const apiKey = await db.apiKeys.findByHash(hash);
  if (!apiKey || apiKey.revokedAt) return res.status(401).json({ error: 'Invalid API key' });

  req.apiKey = apiKey;  // attach scopes, rate limits
  next();
}
```

### Decision tree
```
Is it user-facing?
  Yes -> Is it a SPA/mobile app?
    Yes -> OAuth2 + PKCE (or JWT with refresh rotation)
    No  -> Session-based (server-rendered)
  No  -> Is it service-to-service?
    Yes -> Is it internal (same network)?
      Yes -> mTLS (mutual TLS with certificates)
      No  -> API keys with scoped permissions
```

## Anti-patterns
- JWT in localStorage -> XSS can steal tokens; use httpOnly cookies
- Long-lived JWT (>1hr) without refresh rotation -> stolen token is valid too long
- Refresh tokens without rotation -> no way to detect compromise
- API keys in query parameters -> logged in server access logs, browser history
- Session secret as static string -> use crypto.randomBytes(64) minimum

## Decision criteria
- **JWT**: stateless APIs, microservices, mobile apps, need horizontal scaling without shared state
- **Sessions**: server-rendered apps, need instant revocation, simpler auth model
- **OAuth2/OIDC**: third-party login (Google, GitHub), delegated authorization
- **API keys**: developer APIs, service-to-service, webhook verification
- **mTLS**: zero-trust service mesh, internal service-to-service

## Quick reference
```
JWT access token: 15 min, RS256, in httpOnly cookie
JWT refresh token: 7 days, rotate on use, detect reuse
Session: Redis store, 24hr, secure + httpOnly + sameSite
OAuth2: always use PKCE, even for confidential clients
API keys: prefix (sk_live_), hash before storing, show once
mTLS: for internal services, SPIFFE/SPIRE for identity
Password hashing: argon2id (preferred) or bcrypt (rounds=12)
```
