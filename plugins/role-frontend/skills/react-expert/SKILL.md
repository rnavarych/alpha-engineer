---
name: react-expert
description: |
  React expertise including hooks patterns, component composition, server components,
  Suspense boundaries, data fetching with React Query/SWR/TanStack, Next.js patterns
  (App Router, Server Actions), and React-specific performance optimization.
allowed-tools: Read, Grep, Glob, Bash
---

# React Expert

## Hooks Patterns

### Core Hooks Usage
- **useState**: Use for local UI state. Prefer functional updates (`setState(prev => prev + 1)`) when the new value depends on the previous one. Avoid storing derived state; compute it during render instead.
- **useEffect**: Treat as a synchronization mechanism, not a lifecycle method. Always specify the dependency array. Clean up subscriptions, timers, and event listeners in the return function. Avoid setting state inside useEffect when the value can be derived.
- **useCallback**: Wrap callbacks passed to memoized children or used in dependency arrays of other hooks. Do not wrap every function; only those where referential stability matters.
- **useMemo**: Use for expensive computations (filtering large lists, complex transformations). Profile before optimizing. Never use for simple object/array literals unless they are dependency array entries.
- **useRef**: Use for DOM references, storing mutable values that should not trigger re-renders (previous values, interval IDs), and for imperative handle forwarding with `forwardRef`.

### Custom Hooks
- Extract reusable logic into custom hooks prefixed with `use`. Each custom hook should encapsulate a single concern.
- Return tuples `[value, setter]` for simple state hooks. Return objects `{ data, error, loading }` for complex hooks.
- Compose custom hooks from other hooks. Avoid deeply nested hook chains.
- Example patterns: `useDebounce`, `useMediaQuery`, `useLocalStorage`, `useIntersectionObserver`, `usePrevious`.

## Component Composition

- Favor composition with `children` and render props over deep component hierarchies.
- Use compound components (like `<Tabs>`, `<Tabs.Panel>`) for related UI groups sharing implicit state.
- Separate data-fetching containers from presentational components. Containers handle state and side effects; presentational components receive props and render UI.
- Use `React.lazy` with `Suspense` for code-split component loading.

## Server Components (React 19+ / Next.js App Router)

- Default to Server Components. They run on the server, produce zero client-side JavaScript, and can directly access databases and file systems.
- Add `"use client"` only when the component needs interactivity (event handlers, hooks, browser APIs).
- Pass serializable props from Server Components to Client Components. Functions and classes cannot cross the server-client boundary.
- Use Server Actions (`"use server"`) for form submissions and mutations. They replace API routes for simple data writes.
- Streaming with Suspense: Wrap slow data fetches in `<Suspense fallback={<Skeleton />}>` to stream HTML progressively.

## Data Fetching

- **React Query / TanStack Query**: Use for server state. Configure `staleTime` and `gcTime` per query. Use `queryKey` arrays for cache granularity. Implement optimistic updates with `onMutate` and rollback with `onError`.
- **SWR**: Lightweight alternative. Use `useSWR` with a global fetcher. Leverage `mutate` for local cache updates and revalidation.
- Deduplicate requests. Both React Query and SWR deduplicate concurrent requests with the same key.
- Prefetch data on hover or route transition for instant navigation.

## Next.js Patterns

- **App Router**: Use the `app/` directory with layout nesting. Shared layouts persist state across route changes. Use `loading.tsx` for route-level Suspense and `error.tsx` for error boundaries.
- **Server Actions**: Define with `"use server"` directive. Use for form mutations, database writes, and revalidation. Call `revalidatePath` or `revalidateTag` after writes.
- **Metadata API**: Export `metadata` or `generateMetadata` from page/layout files for SEO.
- **Image optimization**: Use `next/image` with `sizes` and `priority` props. Configure `remotePatterns` in `next.config.js`.
- **Route handlers**: Use `app/api/` route handlers for webhook endpoints or third-party integrations that require a traditional API endpoint.

## Performance Optimization

- Use `React.memo` on components that receive stable props but re-render due to parent updates. Always profile first with React DevTools.
- Virtualize long lists with `@tanstack/react-virtual` or `react-window`. Never render 1000+ DOM nodes at once.
- Avoid creating new objects/arrays in JSX props. Lift constants outside the component or use `useMemo`.
- Use `useTransition` for non-urgent state updates (search filtering, tab switching) to keep the UI responsive.
- Use `useDeferredValue` to defer rendering of expensive child trees while showing stale content.
- Split context providers. A single large context that changes frequently causes all consumers to re-render. Separate read-heavy from write-heavy contexts.
