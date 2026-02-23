# Data Fetching and Next.js 15 Patterns

## When to load
Load when configuring TanStack Query v5 or SWR, implementing Next.js App Router features (PPR, Server Actions, Turbopack, metadata), or routing with Remix v2 / React Router 7 or TanStack Router.

## TanStack Query v5

- **Breaking changes from v4**: `cacheTime` renamed to `gcTime`. `useQuery` options object only (no positional args). `status: 'loading'` renamed to `status: 'pending'`.
- Configure `QueryClient` with `defaultOptions`: set `staleTime: 60_000` globally and override per-query.
- Structure `queryKey` as `['entity', { filters }]` for granular invalidation with `invalidateQueries({ queryKey: ['entity'] })`.
- `useSuspenseQuery` and `useSuspenseInfiniteQuery` integrate with React Suspense — no manual `isLoading` checks.
- Prefetch on hover: `queryClient.prefetchQuery(options)` in `onMouseEnter` for instant navigation.
- Infinite queries: `useInfiniteQuery` with `getNextPageParam`. Pair with TanStack Virtual for virtualized lists.
- Optimistic mutations: use `onMutate` to snapshot and update cache, `onError` to restore, `onSettled` to sync.
- `useQueries` for parallel queries with dynamic count. `useSuspenseQueries` for parallel suspended queries.

## SWR

- Lightweight alternative. `useSWR` with a global fetcher. `mutate` for local cache updates and revalidation.
- `useSWRInfinite` for pagination and infinite scroll.
- `useSWRImmutable` for data that never changes (static reference data).
- `SWRConfig` provides global configuration: `{ fetcher, revalidateOnFocus, dedupingInterval }`.

## Next.js 15 App Router

- Use the `app/` directory with layout nesting. Shared layouts persist state across route changes.
- Use `loading.tsx` for route-level Suspense and `error.tsx` for error boundaries per route segment.
- **Partial Prerendering (PPR)**: Opt in with `export const experimental_ppr = true`. Static shell prerendered at build time; dynamic content streams in via Suspense.
- **`after()`**: Run code after the response has streamed to the client. Use for logging, analytics, and background tasks.
- Route groups `(group)/` organize routes without affecting URL structure.
- Parallel routes `@slot/` render multiple pages simultaneously in one layout.
- Intercepting routes `(.)folder` show a route in a modal while preserving the underlying page.

### Server Actions
- Define with `"use server"` directive. Use for form mutations, database writes, and revalidation.
- Call `revalidatePath` or `revalidateTag` after writes.
- Invoke in `<form action={serverAction}>` or imperatively with `serverAction(formData)`.
- Combine with `useActionState` and `useFormStatus` for full pending/error UI.
- Validate input server-side with Zod before processing. Never trust client-provided data.

### Turbopack
- Enable with `next dev --turbo`. Incrementally compiles only changed modules.
- Persistent cache across restarts in `.next/cache/turbopack` reduces cold start time.
- Production build still uses webpack in Next.js 15; Turbopack production is in active development.

### Metadata and SEO
- Export `metadata` or `generateMetadata` from page/layout files. `generateMetadata` can fetch data server-side.
- Use `metadataBase` in the root layout for resolving absolute Open Graph image URLs.
- Dynamic OG images: `app/opengraph-image.tsx` with the `ImageResponse` API from `next/og`.

## Routing Alternatives

### Remix v2 / React Router 7
- Use loaders/actions co-located with routes for data loading and mutations.
- `loader` functions run on the server before rendering. `action` functions handle form submissions.
- `useFetcher` for non-navigation data mutations. Progressive enhancement: forms work without JavaScript.
- `defer()` in loaders enables streaming: critical data awaited, non-critical deferred through Suspense.
- Route file convention: `app/routes/products.$id.tsx` creates `/products/:id`. Index routes: `_index.tsx`.

### TanStack Router
- Type-safe client-side router with full TypeScript inference for route params, search params, and loader data.
- Define routes with `createRootRoute()`, `createRoute()`, `createRouter()`. File-based routing via `@tanstack/router-plugin`.
- Search params as first-class state: `route.useSearch()` returns typed, validated params. Use Zod for schemas.
- `route.useParams()` and `route.useLoaderData()` are fully typed without casting.
- Integrate with TanStack Query: use `queryClient` in route loaders for cache-aware data fetching.
