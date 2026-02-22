---
name: api-frontend-integration
description: |
  Integrate APIs with frontend applications using type-safe patterns: tRPC for
  end-to-end type safety, REST client generation (openapi-typescript, orval),
  TanStack Query / SWR for data fetching, optimistic updates, and error handling.
allowed-tools: Read, Grep, Glob, Bash
---

# API-Frontend Integration

## When to Use

Activate when connecting a backend API to a frontend application, setting up data-fetching patterns, implementing optimistic updates, or establishing type-safe API contracts.

## Integration Strategy Selection

| Approach              | Type Safety | Setup Cost | Best For                         |
|-----------------------|-------------|------------|----------------------------------|
| tRPC                  | Full E2E    | Low        | Monorepos, same-team ownership   |
| OpenAPI codegen       | Generated   | Medium     | REST APIs, multi-team            |
| GraphQL + codegen     | Generated   | Medium     | Complex relational data queries  |
| Manual fetch + Zod    | Runtime     | Low        | Simple APIs, third-party services|

## tRPC Integration (Recommended for Monorepos)

1. Define routers in `packages/api/src/routers/` with input validation via Zod.
2. Export the `AppRouter` type -- never the runtime object -- to the frontend.
3. Create a tRPC client with `httpBatchLink` or `httpSubscriptionLink`.
4. Wrap the app with `trpc.Provider` and `QueryClientProvider`.
5. Use `trpc.useQuery()` and `trpc.useMutation()` -- types flow automatically.

## REST Client Generation

- **openapi-typescript** -- generates TypeScript types from OpenAPI 3.x specs. Pair with `openapi-fetch` for typed fetch calls.
- **orval** -- generates React Query hooks, Zod schemas, and mock service workers from OpenAPI specs. Preferred for complex REST APIs.
- Automate generation in CI: `"codegen": "orval --config orval.config.ts"`.

## Data Fetching Patterns (TanStack Query / SWR)

```typescript
// Query with proper typing, stale time, and error handling
const { data, isLoading, error } = useQuery({
  queryKey: ['users', filters],
  queryFn: () => api.users.list(filters),
  staleTime: 5 * 60 * 1000,
  retry: 3,
  retryDelay: (attempt) => Math.min(1000 * 2 ** attempt, 10000),
});
```

## Optimistic Updates

1. Use `onMutate` to snapshot previous data and apply the optimistic change.
2. Use `onError` to rollback to the snapshot on failure.
3. Use `onSettled` to invalidate queries and refetch the authoritative state.
4. Show a subtle indicator (toast, inline badge) so the user knows the change is pending.

## Error Handling Strategy

- **API errors** -- define a shared error shape (`{ code, message, details? }`). Parse with Zod on the client.
- **Network errors** -- distinguish between offline, timeout, and server errors. Show different UI for each.
- **Error boundaries** -- wrap route segments with React Error Boundaries. Provide a "Retry" action.
- **Form validation** -- validate on the client first (Zod + react-hook-form), then re-validate on the server. Surface server-side errors next to the relevant field.

## Loading and Empty States

- Use skeleton loaders (not spinners) for content areas to reduce perceived latency.
- Always handle the empty state: "No results found" with a clear call-to-action.
- Show stale data with a background refresh indicator rather than a full loading state on refetch.

## Common Pitfalls

- Fetching inside `useEffect` without cancellation -- always use TanStack Query or SWR.
- Forgetting to invalidate related queries after a mutation.
- Not deduplicating concurrent identical requests (TanStack Query handles this automatically).
- Ignoring error responses and only checking `data` -- always handle the error path.
