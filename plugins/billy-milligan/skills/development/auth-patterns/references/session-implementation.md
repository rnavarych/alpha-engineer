# Session Implementation

## Redis Session Store

```typescript
import session from 'express-session';
import RedisStore from 'connect-redis';
import Redis from 'ioredis';

const redis = new Redis(process.env.REDIS_URL);

app.use(session({
  store: new RedisStore({
    client: redis,
    prefix: 'sess:',
    ttl: 86400,               // 24 hours
  }),
  name: 'sid',                 // Cookie name (not default 'connect.sid')
  secret: process.env.SESSION_SECRET!,
  resave: false,               // Don't save unchanged sessions
  saveUninitialized: false,    // Don't create empty sessions
  rolling: true,               // Reset TTL on each request
  cookie: {
    httpOnly: true,            // Not accessible via JS
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',           // CSRF protection
    maxAge: 24 * 60 * 60 * 1000,  // 24 hours
    domain: '.myapp.com',     // Shared across subdomains
  },
}));

// Session data — stored in Redis, only session ID in cookie
declare module 'express-session' {
  interface SessionData {
    userId: string;
    role: string;
    loginAt: number;
    lastActivity: number;
  }
}

// Login — create session
app.post('/auth/login', async (req, res) => {
  const user = await authenticateUser(req.body.email, req.body.password);

  // Regenerate session ID to prevent session fixation
  req.session.regenerate((err) => {
    if (err) throw err;
    req.session.userId = user.id;
    req.session.role = user.role;
    req.session.loginAt = Date.now();
    req.session.save((err) => {
      if (err) throw err;
      res.json({ success: true });
    });
  });
});

// Logout — destroy session
app.post('/auth/logout', (req, res) => {
  req.session.destroy((err) => {
    if (err) throw err;
    res.clearCookie('sid');
    res.json({ success: true });
  });
});
```

## Session Fixation Prevention

```typescript
// Session fixation: attacker sets a known session ID before user logs in
// After login, attacker uses the same session ID to hijack the session

// Prevention: ALWAYS regenerate session ID after authentication
app.post('/auth/login', async (req, res) => {
  const user = await authenticateUser(req.body);

  // regenerate() creates new session ID, copies data, destroys old
  req.session.regenerate((err) => {
    if (err) return next(err);

    req.session.userId = user.id;
    req.session.role = user.role;

    req.session.save((err) => {
      if (err) return next(err);
      res.json({ success: true });
    });
  });
});

// Also regenerate on privilege elevation
app.post('/auth/elevate', async (req, res) => {
  // User confirmed MFA or re-entered password
  req.session.regenerate((err) => {
    req.session.elevated = true;
    req.session.elevatedAt = Date.now();
    req.session.save(() => res.json({ elevated: true }));
  });
});
```

## CSRF Protection

```typescript
import csrf from 'csurf';

// Token-based CSRF protection for session-based auth
const csrfProtection = csrf({
  cookie: {
    httpOnly: true,
    sameSite: 'strict',
    secure: process.env.NODE_ENV === 'production',
  },
});

// Apply to state-changing routes
app.use('/api', csrfProtection);

// Provide token to client
app.get('/api/csrf-token', (req, res) => {
  res.json({ csrfToken: req.csrfToken() });
});

// Client includes token in headers
// fetch('/api/orders', {
//   method: 'POST',
//   headers: { 'CSRF-Token': csrfToken },
//   body: JSON.stringify(data),
// });

// Alternative: Double-submit cookie pattern
// 1. Server sets CSRF token in cookie (readable by JS)
// 2. Client reads cookie, sends token in header
// 3. Server verifies header matches cookie
// SameSite=Lax cookies provide significant CSRF protection by themselves
```

## Session Middleware

```typescript
// Authentication middleware
function requireSession(req: Request, res: Response, next: NextFunction) {
  if (!req.session?.userId) {
    return res.status(401).json({ error: { code: 'UNAUTHORIZED' } });
  }

  // Update last activity
  req.session.lastActivity = Date.now();
  next();
}

// Inactivity timeout — force re-login after 30 min idle
function checkInactivity(maxIdleMs: number = 30 * 60 * 1000) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (req.session?.lastActivity) {
      const idle = Date.now() - req.session.lastActivity;
      if (idle > maxIdleMs) {
        return req.session.destroy(() => {
          res.status(401).json({ error: { code: 'SESSION_EXPIRED' } });
        });
      }
    }
    next();
  };
}

// Absolute timeout — force re-login after 24h regardless
function checkAbsoluteTimeout(maxAgeMs: number = 24 * 60 * 60 * 1000) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (req.session?.loginAt) {
      const age = Date.now() - req.session.loginAt;
      if (age > maxAgeMs) {
        return req.session.destroy(() => {
          res.status(401).json({ error: { code: 'SESSION_EXPIRED' } });
        });
      }
    }
    next();
  };
}

app.use('/api', requireSession, checkInactivity(), checkAbsoluteTimeout());
```

## Anti-Patterns
- Not regenerating session ID after login — enables session fixation
- Storing sensitive data in cookie (not session store) — exposed to client
- Default cookie name `connect.sid` — fingerprints the framework
- Missing `sameSite` cookie attribute — vulnerable to CSRF
- No inactivity timeout — session valid forever if cookie not expired

## Quick Reference
```
Redis store: connect-redis, prefix: 'sess:', TTL matches cookie maxAge
Cookie: httpOnly, secure, sameSite: 'lax', custom name (not default)
Session fixation: req.session.regenerate() after every login
CSRF: sameSite cookies + CSRF token for extra protection
Inactivity timeout: 30 min idle -> force re-login
Absolute timeout: 24h max session age regardless of activity
Logout: req.session.destroy() + res.clearCookie()
Rolling: true — reset TTL on each request (active users stay logged in)
```
