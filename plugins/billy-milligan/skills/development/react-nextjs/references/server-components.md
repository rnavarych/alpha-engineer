# Server Components

## When Server vs Client

```
Server Component (default — no directive):
  - Data fetching (async/await directly in component)
  - Database or filesystem access
  - Rendering markdown, syntax highlighting
  - SEO-critical content

Client Component ("use client"):
  - useState, useEffect, useRef, useContext
  - Event handlers (onClick, onChange, onSubmit)
  - Browser APIs (localStorage, navigator, window)
  - Third-party libs that use hooks or DOM
```

## RSC Async Data Fetching

```tsx
// app/orders/page.tsx — Server Component (no "use client")
export default async function OrdersPage({
  searchParams,
}: {
  searchParams: Promise<{ page?: string; status?: string }>;
}) {
  const { page = '1', status } = await searchParams;

  // Fetch directly in component — no useEffect, no API route
  const orders = await getOrders({
    page: Number(page),
    status,
  });

  return (
    <section>
      <OrderFilters />
      <OrderList orders={orders} />
    </section>
  );
}

async function getOrders(params: { page: number; status?: string }) {
  const res = await fetch(`${process.env.API_URL}/orders?${new URLSearchParams({
    page: String(params.page),
    ...(params.status && { status: params.status }),
  })}`, {
    next: { revalidate: 60, tags: ['orders'] },
  });
  if (!res.ok) throw new Error('Failed to fetch orders');
  return res.json();
}
```

## Suspense Streaming

```tsx
// Stream independent sections — each renders as soon as its data resolves
export default function DashboardPage() {
  return (
    <div className="grid grid-cols-2 gap-4">
      <Suspense fallback={<StatsSkeleton />}>
        <StatsSection />          {/* Streams at ~100ms */}
      </Suspense>
      <Suspense fallback={<ChartSkeleton />}>
        <RevenueChart />          {/* Streams at ~300ms */}
      </Suspense>
      <Suspense fallback={<TableSkeleton />}>
        <RecentOrders />          {/* Streams at ~200ms */}
      </Suspense>
    </div>
  );
}

// Each section fetches its own data — no prop drilling, no waterfall
async function StatsSection() {
  const stats = await getStats(); // 100ms
  return <StatsCards stats={stats} />;
}

async function RevenueChart() {
  const data = await getRevenueData(); // 300ms
  return <Chart data={data} />;
}
```

## Parallel vs Sequential Fetching

```tsx
// BAD — sequential: 200ms + 300ms + 150ms = 650ms
export default async function Page() {
  const user = await getUser();
  const stats = await getStats();
  const recent = await getRecent();
}

// GOOD — parallel: max(200, 300, 150) = 300ms
export default async function Page() {
  const [user, stats, recent] = await Promise.all([
    getUser(),
    getStats(),
    getRecent(),
  ]);
}
```

## Anti-Patterns
- Adding `"use client"` to every file — increases bundle, removes RSC benefits
- Sequential `await` for independent data — use `Promise.all`
- Fetching in layout then passing as props — fetch where data is needed
- Using `useEffect` for data that can be fetched on server
