# OAuth 2.0 & OpenID Connect

## Authorization Code + PKCE Flow

```
PKCE (Proof Key for Code Exchange) — required for all public clients

1. Client generates code_verifier (random 43-128 chars)
2. Client computes code_challenge = SHA256(code_verifier), base64url-encoded
3. Client redirects user to authorization endpoint with code_challenge
4. User authenticates and authorizes
5. Provider redirects back with authorization code
6. Client exchanges code + code_verifier for tokens
7. Provider verifies SHA256(code_verifier) === stored code_challenge

Why PKCE: prevents authorization code interception attacks
Required by: all OAuth 2.1 clients (not just mobile/SPA)
```

```typescript
import crypto from 'crypto';

// Step 1-2: Generate PKCE pair
function generatePKCE(): { verifier: string; challenge: string } {
  const verifier = crypto.randomBytes(32).toString('base64url');
  const challenge = crypto.createHash('sha256')
    .update(verifier).digest('base64url');
  return { verifier, challenge };
}

// Step 3: Build authorization URL
function getAuthorizationUrl(provider: OAuthProvider): string {
  const { verifier, challenge } = generatePKCE();
  const state = crypto.randomBytes(16).toString('hex');

  // Store verifier + state in session (needed for step 6)
  session.set('oauth_verifier', verifier);
  session.set('oauth_state', state);

  const params = new URLSearchParams({
    client_id: provider.clientId,
    redirect_uri: provider.redirectUri,
    response_type: 'code',
    scope: 'openid email profile',
    state,
    code_challenge: challenge,
    code_challenge_method: 'S256',
  });

  return `${provider.authorizationEndpoint}?${params}`;
}

// Step 6: Exchange code for tokens
async function handleCallback(code: string, state: string): Promise<TokenResponse> {
  // Verify state matches
  if (state !== session.get('oauth_state')) {
    throw new Error('State mismatch — possible CSRF attack');
  }

  const verifier = session.get('oauth_verifier');
  session.delete('oauth_verifier');
  session.delete('oauth_state');

  const response = await fetch(provider.tokenEndpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'authorization_code',
      client_id: provider.clientId,
      client_secret: provider.clientSecret,
      code,
      redirect_uri: provider.redirectUri,
      code_verifier: verifier,
    }),
  });

  if (!response.ok) {
    throw new Error(`Token exchange failed: ${response.status}`);
  }

  return response.json();
}
```

## Token Exchange (Service-to-Service)

```typescript
// Exchange user token for service-specific token
async function exchangeToken(
  subjectToken: string,
  targetAudience: string,
): Promise<string> {
  const response = await fetch(provider.tokenEndpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:token-exchange',
      subject_token: subjectToken,
      subject_token_type: 'urn:ietf:params:oauth:token-type:access_token',
      audience: targetAudience,
      client_id: process.env.CLIENT_ID!,
      client_secret: process.env.CLIENT_SECRET!,
    }),
  });

  const data = await response.json();
  return data.access_token;
}
```

## Provider Integration (NextAuth.js)

```typescript
// app/api/auth/[...nextauth]/route.ts
import NextAuth from 'next-auth';
import Google from 'next-auth/providers/google';
import GitHub from 'next-auth/providers/github';
import { DrizzleAdapter } from '@auth/drizzle-adapter';

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
  ],
  callbacks: {
    jwt({ token, user, account }) {
      if (user) {
        token.role = user.role;
        token.provider = account?.provider;
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

## ID Token Validation

```typescript
// Verify OIDC ID token (JWT from provider)
import { createRemoteJWKSet, jwtVerify } from 'jose';

const JWKS = createRemoteJWKSet(
  new URL('https://accounts.google.com/.well-known/jwks.json')
);

async function verifyIdToken(idToken: string): Promise<UserInfo> {
  const { payload } = await jwtVerify(idToken, JWKS, {
    issuer: 'https://accounts.google.com',
    audience: process.env.GOOGLE_CLIENT_ID,
  });

  return {
    sub: payload.sub!,
    email: payload.email as string,
    name: payload.name as string,
    emailVerified: payload.email_verified as boolean,
  };
}
```

## Anti-Patterns
- OAuth without PKCE — authorization code can be intercepted
- Missing `state` parameter — enables CSRF attacks
- Storing tokens in URL fragment — visible in browser history and referrer
- Not validating `iss` and `aud` in ID token — accepts tokens from any provider
- Using implicit flow — deprecated, use authorization code + PKCE

## Quick Reference
```
PKCE: required for all clients (OAuth 2.1) — prevents code interception
State: random value, verify on callback — prevents CSRF
Authorization code flow: redirect -> code -> exchange -> tokens
ID token: JWT from provider, verify iss + aud + signature via JWKS
Token exchange: user token -> service-specific token (RFC 8693)
NextAuth.js: adapter + providers + callbacks
Scopes: openid (required for OIDC), email, profile
```
