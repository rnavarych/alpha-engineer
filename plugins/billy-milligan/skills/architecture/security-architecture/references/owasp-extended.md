# OWASP Extended Reference (A06–A10)

## When to load
Load when discussing vulnerable components, authentication failures, software integrity, security logging, or SSRF prevention (OWASP A06–A10).

## Patterns

### A06: Vulnerable and Outdated Components
```bash
# Regular dependency audits
npm audit --production
npx better-npm-audit audit

# Pin major versions, allow patch updates
# package.json: "express": "~4.18.0" (patch only)

# Check for end-of-life runtimes
# Node.js LTS schedule: even-numbered releases
```

### A07: Identification and Authentication Failures
```typescript
// Prevention checklist:
// - Multi-factor authentication for sensitive operations
// - Password minimum: 12 chars, check against breach databases
// - Account lockout: 5 failed attempts -> 15min lockout
// - Session invalidation on password change/logout

import { hibpCheck } from 'hibp';
async function validatePassword(password: string) {
  if (password.length < 12) throw new Error('Minimum 12 characters');
  const breachCount = await hibpCheck(password);
  if (breachCount > 0) throw new Error('Password found in data breach');
}
```

```typescript
// Account lockout with Redis counter
async function trackFailedLogin(userId: string): Promise<void> {
  const key = `auth:failed:${userId}`;
  const attempts = await redis.incr(key);
  await redis.expire(key, 900); // 15 min window

  if (attempts >= 5) {
    await redis.set(`auth:locked:${userId}`, '1', 'EX', 900);
    logger.warn({ event: 'auth.locked', userId, attempts });
    throw new Error('Account temporarily locked');
  }
}

async function clearFailedLogins(userId: string): Promise<void> {
  await redis.del(`auth:failed:${userId}`);
}
```

### A08: Software and Data Integrity Failures
```typescript
// Verify package integrity with lock files
// npm ci (not npm install) in CI/CD
// Subresource integrity for CDN scripts:
// <script src="cdn.js" integrity="sha384-..." crossorigin="anonymous">

// Deserialization: validate before processing
import Ajv from 'ajv';
const ajv = new Ajv({ allErrors: true });
const validate = ajv.compile(schema);
if (!validate(data)) throw new ValidationError(validate.errors);
```

### A09: Security Logging and Monitoring Failures
```typescript
// Log security events with structured data
logger.warn({
  event: 'auth.failed',
  userId: attemptedUserId,
  ip: req.ip,
  userAgent: req.headers['user-agent'],
  reason: 'invalid_password',
  attemptCount: failedAttempts,
});

// Events that must always be logged:
// - Failed authentication attempts (with IP)
// - Privilege escalation (role change, admin access)
// - Bulk data exports (>100 records)
// - Access to admin endpoints from unknown IPs
// - Password reset requests

// Alert on: 5+ failed logins from same IP in 5 min,
// privilege escalation attempts, bulk data export
```

### A10: Server-Side Request Forgery (SSRF)
```typescript
// Prevention: validate and restrict outbound URLs
import { URL } from 'url';

function validateUrl(input: string): URL {
  const url = new URL(input);

  // Block internal/private IPs
  const blocked = ['127.0.0.1', 'localhost', '0.0.0.0', '169.254.169.254'];
  if (blocked.includes(url.hostname)) throw new Error('Blocked host');

  // Block private IP ranges (RFC 1918 + link-local)
  if (url.hostname.match(/^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)/)) {
    throw new Error('Private IP blocked');
  }

  // Allow only HTTPS
  if (url.protocol !== 'https:') throw new Error('HTTPS required');

  return url;
}

// Additional SSRF defenses:
// - Allowlist outbound domains where possible
// - Use a dedicated egress proxy with domain filtering
// - Block DNS rebinding: resolve hostname, check IP before request
```

## Anti-patterns
- Running `npm install` in CI -> lock file ignored, unpinned deps may change
- No lockout on auth endpoints -> brute force in minutes
- Logging PII in security events -> GDPR violation + exposes data in log systems
- Trusting user-supplied URLs for server-side fetches without validation -> SSRF
- Treating WAF as substitute for application-level SSRF checks -> bypassed easily

## Quick reference
```
A06 Components: npm audit, pin versions (~4.18.0), check EOL
A07 Auth: MFA, breach check (hibp), lockout after 5 attempts
A08 Integrity: npm ci, lock files, AJV schema validation
A09 Logging: structured security events, never log PII, alert on anomalies
A10 SSRF: validate URLs, block private IPs and localhost, HTTPS only
```
