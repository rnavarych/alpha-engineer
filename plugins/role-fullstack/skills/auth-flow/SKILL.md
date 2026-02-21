---
name: auth-flow
description: |
  Implement complete authentication flows: login, signup, forgot-password pages,
  JWT + refresh tokens, session-based auth, social login (Google, GitHub, Apple),
  MFA/2FA, protected routes via middleware, and role-based UI rendering.
allowed-tools: Read, Grep, Glob, Bash
---

# Auth Flow Implementation

## When to Use

Activate when adding authentication or authorization to a fullstack application -- login/signup pages, protected routes, social login, token management, or role-based access control.

## Auth Library Selection

| Library      | Framework     | Session Store   | OAuth Built-in | MFA Support |
|-------------|---------------|-----------------|----------------|-------------|
| NextAuth.js / Auth.js | Next.js, SvelteKit | DB / JWT | Yes | Via adapter |
| Lucia        | Any           | DB              | Manual         | Manual      |
| Clerk        | Any           | Managed         | Yes            | Yes         |
| Supabase Auth| Any           | Managed         | Yes            | Yes         |

## Login / Signup Flow

1. **Form UI** -- use `react-hook-form` + `zod` for validation. Fields: email, password, confirm password (signup).
2. **API endpoint** -- validate input with Zod, hash password with `bcrypt` (cost 12+) or `argon2`, store user in DB.
3. **Session creation** -- issue a session token (stored in `httpOnly`, `secure`, `sameSite=lax` cookie) or JWT pair.
4. **Redirect** -- on success redirect to the dashboard or the originally requested page (store `callbackUrl`).

## JWT + Refresh Token Strategy

- **Access token** -- short-lived (15 minutes), stored in memory (not localStorage). Contains user ID, role, permissions.
- **Refresh token** -- long-lived (7-30 days), stored in `httpOnly` cookie. Rotate on every use (one-time use tokens).
- **Silent refresh** -- use an interceptor (Axios/fetch wrapper) that catches 401, calls `/api/auth/refresh`, replays the original request.
- **Token revocation** -- maintain a deny-list in Redis for immediate logout, or use short-lived tokens and accept the window.

## Social Login (OAuth 2.0)

1. Configure OAuth apps in Google Cloud Console, GitHub Settings, Apple Developer.
2. Set redirect URIs to `{APP_URL}/api/auth/callback/{provider}`.
3. Use NextAuth.js providers or implement the OAuth flow manually (authorization code + PKCE).
4. On first social login, create a local user record. On subsequent logins, link to the existing account by email.
5. Handle edge case: user signs up with email/password, then tries social login with the same email -- prompt to link accounts.

## MFA / 2FA Implementation

- **TOTP** -- use `otpauth` or `speakeasy` library. Generate a secret, show QR code, verify 6-digit code.
- **Recovery codes** -- generate 10 single-use codes at MFA setup. Hash and store them. Show once, never again.
- **Flow** -- after password verification, redirect to MFA challenge page. Only issue session after MFA passes.

## Protected Routes (Middleware)

```typescript
// Next.js middleware.ts
export function middleware(request: NextRequest) {
  const token = request.cookies.get('session-token');
  if (!token && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
}
export const config = { matcher: ['/dashboard/:path*', '/api/protected/:path*'] };
```

## Role-Based UI Rendering

- Define roles in a shared enum: `admin`, `editor`, `viewer`.
- Server-side: check role in API handlers and middleware before returning data.
- Client-side: use a `<Can action="edit" resource="post">` component or `usePermissions()` hook to conditionally render UI elements.
- Never rely solely on client-side role checks -- always enforce on the server.

## Common Pitfalls

- Storing JWTs in localStorage (XSS vulnerable) -- use httpOnly cookies or in-memory storage.
- Not rate-limiting login endpoints -- add rate limiting (5 attempts per minute per IP).
- Returning different error messages for "user not found" vs "wrong password" -- always use a generic message.
- Forgetting to invalidate sessions on password change.
