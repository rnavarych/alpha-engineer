---
name: react-nextjs
description: |
  React and Next.js App Router patterns: Server Components async data fetching, parallel
  fetching with Promise.all, URL state vs useState, Server Actions, Suspense streaming,
  route handlers, middleware, Image/Font optimization, Core Web Vitals.
  Use when building Next.js applications, optimizing rendering, managing server/client state.
allowed-tools: Read, Grep, Glob
---

# React & Next.js Patterns

## When to Use This Skill
- Building Next.js 13+ App Router applications
- Choosing between Server Components and Client Components
- Optimizing performance and Core Web Vitals
- Managing forms with Server Actions
- Parallel data fetching strategies

## Core Principles

1. **Server Components by default** — only opt into Client Components when you need browser APIs or interactivity
2. **Fetch in parallel** — sequential awaits in Server Components multiply latency
3. **URL state over useState** for shareable filters/search/pagination
4. **Server Actions for mutations** — no need for API routes for form submissions
5. **Suspense boundaries** — stream UI as data becomes ready; never block the whole page

---

## Patterns ✅

### Server Component Data Fetching

```tsx
// app/orders/page.tsx — Server Component (default in App Router)
// No 'use client' directive = Server Component

interface Props {
  searchParams: { page?: string; status?: string };
}

export default async function OrdersPage({ searchParams }: Props) {
  const page = Number(searchParams.page) || 1;
  const status = searchParams.status;

  // Fetch directly in component — no useEffect, no API route needed
  const orders = await getOrders({ page, status });

  return (
    <div>
      <OrderFilters />  {/* Client Component for interactivity */}
      <Suspense fallback={<OrdersSkeleton />}>
        <OrderList orders={orders} />
      </Suspense>
    </div>
  );
}

// Data fetching function with caching
async function getOrders({ page, status }: { page: number; status?: string }) {
  // next.revalidate: cache for 60 seconds, then revalidate
  const response = await fetch(`${process.env.API_URL}/orders?page=${page}&status=${status}`, {
    next: { revalidate: 60, tags: ['orders'] },  // tag for on-demand revalidation
  });
  if (!response.ok) throw new Error('Failed to fetch orders');
  return response.json();
}
```

### Parallel Data Fetching (Not Sequential)

```tsx
// Wrong — sequential: userTime + statsTime + recentTime = total wait
export default async function DashboardPage() {
  const user = await getUser();          // 200ms
  const stats = await getStats();        // 300ms
  const recent = await getRecentItems(); // 150ms
  // Total: 650ms
}

// Correct — parallel: max(200, 300, 150) = 300ms
export default async function DashboardPage() {
  const [user, stats, recent] = await Promise.all([
    getUser(),
    getStats(),
    getRecentItems(),
  ]);
  // Total: 300ms (57% faster)
}

// Even better — unblock rendering with Suspense
export default function DashboardPage() {
  return (
    <div>
      <Suspense fallback={<UserSkeleton />}>
        <UserSection />          {/* Streams when user data ready */}
      </Suspense>
      <Suspense fallback={<StatsSkeleton />}>
        <StatsSection />         {/* Streams when stats ready */}
      </Suspense>
    </div>
  );
}

// Each section fetches its own data — no prop drilling
async function UserSection() {
  const user = await getUser();  // 200ms
  return <UserCard user={user} />;
}
```

### URL State for Filters (Not useState)

```tsx
// Wrong: useState doesn't persist on reload, not shareable
'use client';
const [status, setStatus] = useState('');
const [page, setPage] = useState(1);
// Problem: user refreshes → state lost. User copies URL → state not included.

// Correct: URL search params — persistent, shareable, bookmarkable
'use client';
import { useRouter, useSearchParams, usePathname } from 'next/navigation';

export function OrderFilters() {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  function updateFilter(key: string, value: string) {
    const params = new URLSearchParams(searchParams.toString());
    if (value) {
      params.set(key, value);
    } else {
      params.delete(key);
    }
    params.set('page', '1');  // Reset pagination on filter change
    router.push(`${pathname}?${params.toString()}`);
  }

  return (
    <select
      value={searchParams.get('status') || ''}
      onChange={(e) => updateFilter('status', e.target.value)}
    >
      <option value="">All statuses</option>
      <option value="pending">Pending</option>
      <option value="completed">Completed</option>
    </select>
  );
}
```

### Server Actions for Forms

```tsx
// app/orders/new/page.tsx
import { redirect } from 'next/navigation';
import { revalidateTag } from 'next/cache';

// Server Action — runs on the server, no API route needed
async function createOrder(formData: FormData) {
  'use server';

  const validated = createOrderSchema.safeParse({
    customerId: formData.get('customerId'),
    items: JSON.parse(formData.get('items') as string),
  });

  if (!validated.success) {
    return { error: validated.error.flatten() };
  }

  const order = await db.orders.create({ data: validated.data });
  revalidateTag('orders');  // Invalidate cached order listings
  redirect(`/orders/${order.id}`);
}

export default function NewOrderPage() {
  return (
    <form action={createOrder}>
      <input name="customerId" required />
      <SubmitButton />  {/* Client Component for pending state */}
    </form>
  );
}
```

```tsx
// Client Component for form submission pending state
'use client';
import { useFormStatus } from 'react-dom';

export function SubmitButton() {
  const { pending } = useFormStatus();
  return (
    <button type="submit" disabled={pending}>
      {pending ? 'Creating...' : 'Create Order'}
    </button>
  );
}
```

### Client Components — When to Use

```tsx
// Use 'use client' ONLY when you need:
// 1. Browser APIs (window, localStorage, navigator)
// 2. Event handlers that need state (onClick, onChange)
// 3. Hooks (useState, useEffect, useRef)
// 4. Real-time updates (WebSocket, SSE)

'use client';
import { useState, useEffect } from 'react';

// Keep Client Components as leaf nodes — don't push 'use client' up the tree
export function InteractiveCounter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>Count: {count}</button>;
}

// Compose: Server Component wraps Client Component
// app/page.tsx (Server Component)
export default async function Page() {
  const data = await fetchHeavyData();  // Runs on server
  return (
    <div>
      <ServerRenderedData data={data} />
      <InteractiveCounter />  {/* Only the counter is client-side */}
    </div>
  );
}
```

---

## Anti-Patterns ❌

### Sequential Data Fetching in Server Components
**What it is**: Multiple `await fetch()` calls one after another.
**What breaks**: Latency multiplies. 4 sequential 100ms calls = 400ms. Parallel = 100ms.
**Fix**: `Promise.all([...])` for independent fetches.

### Everything as Client Component
**What it is**: Adding `'use client'` at the top of every file "to be safe."
**What breaks**: Server Components are faster (no JS bundle, no hydration). Adding `'use client'` unnecessarily increases bundle size, removes server-side rendering benefits.
**Fix**: Server Components by default. Client Components only for interactivity.

### Managing Filter State in useState
**What it is**: Filter, search, and pagination state in React state.
**What breaks**: State lost on page refresh. Cannot share URL with filters applied. Browser back button doesn't restore state.
**Fix**: URL search params. Server Components read `searchParams` directly.

### Waterfall Fetching in Nested Components
**What it is**: Parent fetches, then child fetches, then grandchild fetches — each waiting for parent to finish.
**What breaks**: Network waterfall. 100ms + 100ms + 100ms = 300ms minimum.
**Fix**: Fetch at the top level, pass data as props. Or hoist Suspense boundaries and fetch in parallel.

---

## Quick Reference

```
Server Component = default, no 'use client', server-side rendering
Client Component = 'use client', browser APIs, interactivity, hooks
Parallel fetch: Promise.all([...]) — not sequential await
URL state: useSearchParams + router.push for filters/pagination
Server Actions: 'use server' for form mutations, no API route needed
revalidateTag: invalidate cached data after mutation
Suspense: stream sections independently — faster perceived load
Core Web Vitals targets: LCP < 2.5s, CLS < 0.1, INP < 200ms
```
