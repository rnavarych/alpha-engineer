# App Router Patterns

## Layouts

```tsx
// app/layout.tsx — root layout (required, wraps all pages)
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <Providers>      {/* Theme, auth, query client */}
          <Header />
          <main>{children}</main>
          <Footer />
        </Providers>
      </body>
    </html>
  );
}

// app/dashboard/layout.tsx — nested layout (persists across dashboard pages)
export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex">
      <Sidebar />          {/* Does NOT re-render on page navigation */}
      <div className="flex-1">{children}</div>
    </div>
  );
}
// Layouts persist state between navigations — sidebar scroll position preserved
```

## Parallel Routes

```
app/
  @analytics/page.tsx    — parallel slot
  @feed/page.tsx         — parallel slot
  layout.tsx             — renders both slots
  page.tsx               — main content
```

```tsx
// app/layout.tsx — receives parallel routes as props
export default function Layout({
  children,
  analytics,
  feed,
}: {
  children: React.ReactNode;
  analytics: React.ReactNode;
  feed: React.ReactNode;
}) {
  return (
    <div className="grid grid-cols-3">
      <div className="col-span-2">{children}</div>
      <aside>
        {analytics}
        {feed}
      </aside>
    </div>
  );
}
// Each slot loads independently — @analytics can stream before @feed
```

## Intercepting Routes

```
app/
  feed/
    page.tsx                   — feed page
  @modal/
    (.)feed/[id]/page.tsx      — intercepts /feed/[id] — shows as modal
  feed/[id]/page.tsx           — direct URL shows full page
```

```tsx
// app/@modal/(.)feed/[id]/page.tsx — modal interceptor
import { Modal } from '@/components/modal';

export default async function PhotoModal({ params }: { params: { id: string } }) {
  const photo = await getPhoto(params.id);
  return (
    <Modal>
      <PhotoDetail photo={photo} />
    </Modal>
  );
}
// Click from feed → shows modal overlay
// Direct URL /feed/123 → shows full page
// Instagram-style navigation pattern
```

## Middleware

```tsx
// middleware.ts — runs before every request
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Auth redirect
  const token = request.cookies.get('session')?.value;
  if (pathname.startsWith('/dashboard') && !token) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  // Geo-based redirect
  const country = request.geo?.country;
  if (pathname === '/' && country === 'DE') {
    return NextResponse.redirect(new URL('/de', request.url));
  }

  // Add request headers
  const headers = new Headers(request.headers);
  headers.set('x-request-id', crypto.randomUUID());
  return NextResponse.next({ request: { headers } });
}

export const config = {
  matcher: [
    // Skip static files and API routes
    '/((?!_next/static|_next/image|favicon.ico|api).*)',
  ],
};
```

## Route Groups

```
app/
  (marketing)/           — route group (no URL segment)
    layout.tsx           — marketing layout (no sidebar)
    page.tsx             — / (home)
    about/page.tsx       — /about
  (dashboard)/           — route group
    layout.tsx           — dashboard layout (with sidebar)
    settings/page.tsx    — /settings
    orders/page.tsx      — /orders
```

## Loading and Error States

```tsx
// app/orders/loading.tsx — automatic Suspense boundary
export default function Loading() {
  return <OrdersSkeleton />;
}

// app/orders/error.tsx — automatic error boundary
'use client';
export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div>
      <h2>Something went wrong</h2>
      <p>{error.message}</p>
      <button onClick={reset}>Try again</button>
    </div>
  );
}

// app/not-found.tsx — 404 page
export default function NotFound() {
  return <h1>Page not found</h1>;
}
```

## Quick Reference
```
Layouts: persist between navigations, don't re-render on page change
Parallel routes: @slot — independent loading, simultaneous rendering
Intercepting routes: (.) same level, (..) one up — modal pattern
Route groups: (name) — shared layout without URL segment
Middleware: runs at edge, auth redirects, geo, headers — no heavy logic
loading.tsx: automatic Suspense fallback for the route segment
error.tsx: automatic error boundary ("use client" required)
```
