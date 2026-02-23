# Component Composition, Server Components, and Concurrent Features

## When to load
Load when designing component hierarchies, implementing error boundaries, working with React Server Components and Server Actions, or using Suspense streaming and the Transition API.

## Component Composition

- Favor composition with `children` and render props over deep component hierarchies.
- Use compound components (like `<Tabs>`, `<Tabs.Panel>`) for related UI groups sharing implicit state.
- Separate data-fetching containers from presentational components — containers handle state and side effects.
- Use `React.lazy` with `Suspense` for code-split component loading.
- Use `forwardRef` + `useImperativeHandle` to expose imperative APIs (e.g., `focus()`, `reset()`, `scrollIntoView()`).

### Error Boundaries
- Class-based error boundaries catch render errors in their subtree. Use `react-error-boundary` library for function-component-friendly patterns.
- `<ErrorBoundary FallbackComponent={ErrorFallback} onReset={...}>` wraps sections that may fail.
- `useErrorBoundary()` lets you imperatively trigger error boundaries from event handlers or async code.
- Combine with Suspense: `<ErrorBoundary><Suspense fallback={<Skeleton/>}><AsyncComponent/></Suspense></ErrorBoundary>`.
- Reset after user action: pass `resetKeys` or call `resetErrorBoundary()` from the fallback.

## Server Components (React 19+ / Next.js App Router)

- Default to Server Components. Zero client-side JavaScript, direct database and filesystem access.
- Add `"use client"` only when the component needs interactivity (event handlers, hooks, browser APIs).
- Pass serializable props from Server to Client Components. Functions and classes cannot cross the boundary.
- Use Server Actions (`"use server"`) for form submissions and mutations — they replace API routes for simple writes.
- Streaming with Suspense: Wrap slow data fetches in `<Suspense fallback={<Skeleton />}>` to stream HTML progressively.
- Use the `server-only` package to hard-fail if server-only modules are accidentally imported client-side.
- A Server Component can render a Client Component as a child. A Client Component cannot render a Server Component directly — but can accept Server Components as `children` props.

## Concurrent Features

### Suspense Patterns
- **Data Suspense**: Wrap data-fetching components in `<Suspense>`. Works with React Query, SWR, Relay, and `use(promise)`.
- **Code Splitting**: `React.lazy(() => import('./HeavyComponent'))` + `<Suspense fallback={<Spinner/>}>`.
- **Nested Suspense**: Nest boundaries for granular loading UI. Outer boundaries show page shells; inner show component-level skeletons.
- **SuspenseList**: `<SuspenseList revealOrder="forwards" tail="collapsed">` coordinates multiple Suspense children to reveal in order.
- **Streaming SSR**: Next.js App Router streams HTML through Suspense boundaries. Above-the-fold content renders immediately.

### Transition API
- Wrap expensive state updates in `startTransition` to mark them as interruptible. React yields to more urgent updates mid-render.
- Use `useTransition` in components that initiate the transition to track `isPending`.
- Use `useDeferredValue` in components that receive frequently-changing props to throttle their re-renders.
- Next.js 15 and React Router 7 use `startTransition` internally for page navigation — navigation does not block user interaction.
