---
name: react-expert
description: React expertise covering hooks, server components, React 19 actions and compiler, Next.js 15 App Router, Remix, TanStack Router and Query v5, Zustand, Jotai, shadcn/ui, Radix UI, Framer Motion, concurrent features, and React DevTools profiling.
allowed-tools: Read, Grep, Glob, Bash
---

# React Expert

## React 19 New Features

### Actions and useActionState
- **Actions**: Functions passed to form `action` props or transition APIs that can be async. React manages pending state, error handling, and optimistic updates automatically.
- **useActionState**: `const [state, dispatch, isPending] = useActionState(action, initialState)`. Replaces the `useFormState` pattern. Provides pending state and last action result without manual state management.
- **useFormStatus**: `const { pending, data, method, action } = useFormStatus()`. Reads the status of the parent `<form>` action. Use inside form child components (e.g., a Submit button) to disable during submission without prop drilling.
- **useOptimistic**: `const [optimisticValue, addOptimistic] = useOptimistic(state, reducer)`. Apply optimistic updates during a pending async transition. The UI shows the optimistic value; React rolls back automatically on error.

### use() Hook
- `use(promise)` reads a promise or context inside render. Unlike hooks, it can be called conditionally and inside loops.
- Suspense unwraps the promise: wrap the component in `<Suspense fallback={...}>` to show loading UI while the promise resolves.
- `use(Context)` reads context values; it is the only hook usable inside Server Components for context access.
- Use `use(fetch(...))` in Server Components to initiate data fetching inline without `async/await` at the top level.

### React Compiler (formerly React Forget)
- React Compiler automatically memoizes components and hooks. It inserts `useMemo`, `useCallback`, and `memo` at the compiler level — remove manual memoization in compiler-enabled codebases.
- Enable with `babel-plugin-react-compiler` or the Vite/Next.js plugin equivalents.
- The compiler requires adherence to the Rules of Hooks. Run `react-compiler-healthcheck` to assess codebase compatibility before enabling.
- After enabling, remove manual `useMemo`/`useCallback`/`memo` calls. Profile with React DevTools to verify the compiler is memoizing effectively.

### Activity (Offscreen)
- `<Activity mode="hidden">` keeps a component tree mounted and its state preserved while removing it from the visible DOM. Use for pre-rendered routes, background tabs, and cached panels.
- Replaces the unmount/remount pattern for toggled UI. The hidden subtree does not paint but its state is preserved.
- Use `mode="visible"` | `"hidden"` to toggle. React defers work in hidden trees to prioritize visible content.

## Hooks Patterns

### Core Hooks Usage
- **useState**: Use for local UI state. Prefer functional updates (`setState(prev => prev + 1)`) when the new value depends on the previous one. Avoid storing derived state; compute it during render instead.
- **useEffect**: Treat as a synchronization mechanism, not a lifecycle method. Always specify the dependency array. Clean up subscriptions, timers, and event listeners in the return function. Avoid setting state inside useEffect when the value can be derived.
- **useCallback**: Wrap callbacks passed to memoized children or used in dependency arrays of other hooks. Do not wrap every function; only those where referential stability matters.
- **useMemo**: Use for expensive computations (filtering large lists, complex transformations). Profile before optimizing. Never use for simple object/array literals unless they are dependency array entries.
- **useRef**: Use for DOM references, storing mutable values that should not trigger re-renders (previous values, interval IDs), and for imperative handle forwarding with `forwardRef`.
- **useTransition**: Mark non-urgent state updates so React can interrupt them to handle higher-priority work. Use for filtering, sorting, tab switching. `startTransition` wraps the state update; `isPending` indicates when it is in progress.
- **useDeferredValue**: Defer rendering of an expensive child tree while showing stale content. The parent re-renders immediately with the urgent value; the deferred child catches up when the browser is idle.
- **useId**: Generate stable, unique IDs for accessibility (linking labels to inputs). IDs are consistent between server and client renders, preventing hydration mismatches.

### Custom Hooks
- Extract reusable logic into custom hooks prefixed with `use`. Each custom hook should encapsulate a single concern.
- Return tuples `[value, setter]` for simple state hooks. Return objects `{ data, error, loading }` for complex hooks.
- Compose custom hooks from other hooks. Avoid deeply nested hook chains.
- Example patterns: `useDebounce`, `useMediaQuery`, `useLocalStorage`, `useIntersectionObserver`, `usePrevious`, `useAbortController`, `useEventListener`, `useIsomorphicLayoutEffect`.

## Component Composition

- Favor composition with `children` and render props over deep component hierarchies.
- Use compound components (like `<Tabs>`, `<Tabs.Panel>`) for related UI groups sharing implicit state.
- Separate data-fetching containers from presentational components. Containers handle state and side effects; presentational components receive props and render UI.
- Use `React.lazy` with `Suspense` for code-split component loading.
- Use `forwardRef` + `useImperativeHandle` to expose imperative APIs from components (e.g., focus(), reset(), scrollIntoView()).

### Error Boundaries
- Class-based error boundaries catch render errors in their subtree. Use `react-error-boundary` library for function-component-friendly patterns.
- `<ErrorBoundary FallbackComponent={ErrorFallback} onReset={...}>` wraps sections that may fail.
- `useErrorBoundary()` lets you imperatively trigger error boundaries from event handlers or async code.
- Combine Error Boundaries with Suspense: Suspense handles loading states, Error Boundaries handle failure states. Nest them: `<ErrorBoundary><Suspense fallback={<Skeleton/>}><AsyncComponent/></Suspense></ErrorBoundary>`.
- Reset error boundaries after user action: pass `resetKeys` or call `resetErrorBoundary()` from the fallback.

## Server Components (React 19+ / Next.js App Router)

- Default to Server Components. They run on the server, produce zero client-side JavaScript, and can directly access databases and file systems.
- Add `"use client"` only when the component needs interactivity (event handlers, hooks, browser APIs).
- Pass serializable props from Server Components to Client Components. Functions and classes cannot cross the server-client boundary.
- Use Server Actions (`"use server"`) for form submissions and mutations. They replace API routes for simple data writes.
- Streaming with Suspense: Wrap slow data fetches in `<Suspense fallback={<Skeleton />}>` to stream HTML progressively.
- Server Components can import server-only modules (database clients, secret keys). Use the `server-only` package to hard-fail if they are accidentally imported client-side.
- Compose Server and Client Components: a Server Component can render a Client Component as a child. A Client Component cannot render a Server Component directly — but can accept Server Components as `children` props.

## Concurrent Features

### Suspense Patterns
- **Data Suspense**: Wrap data-fetching components in `<Suspense>`. Works with React Query, SWR, Relay, and `use(promise)`.
- **Code Splitting**: `React.lazy(() => import('./HeavyComponent'))` + `<Suspense fallback={<Spinner/>}>`.
- **Nested Suspense**: Nest boundaries for granular loading UI. Outer boundaries show page shells; inner boundaries show component-level skeletons.
- **SuspenseList**: `<SuspenseList revealOrder="forwards" tail="collapsed">` coordinates multiple Suspense children to reveal in order instead of popping in randomly.
- **Streaming SSR**: Next.js App Router streams HTML from Server Components through Suspense boundaries. Users see above-the-fold content immediately while below-the-fold data resolves.

### Transition API
- Wrap expensive state updates in `startTransition` to mark them as interruptible. React can yield to more urgent updates (user typing, mouse events) mid-render.
- Use `useTransition` in components that initiate the transition to track `isPending`.
- Use `useDeferredValue` in components that receive frequently-changing props to throttle their re-renders.
- The router-level transitions in Next.js 15 and React Router 7 use `startTransition` internally. Page navigation does not block user interaction.

## Data Fetching

### TanStack Query v5
- **Breaking changes**: `cacheTime` renamed to `gcTime`. `useQuery` options object is the only call signature (no positional args). `status: 'loading'` renamed to `status: 'pending'`.
- Configure `QueryClient` with `defaultOptions`: set `staleTime: 60_000` globally and override per-query.
- Use `queryKey` arrays as the cache key. Structure as `['entity', { filters }]` for granular invalidation with `invalidateQueries({ queryKey: ['entity'] })`.
- `useSuspenseQuery` and `useSuspenseInfiniteQuery` integrate with React Suspense — no manual `isLoading` checks needed.
- Prefetch on hover: `queryClient.prefetchQuery(options)` in `onMouseEnter` handlers for instant navigation.
- Infinite queries: `useInfiniteQuery` with `getNextPageParam`. Pair with TanStack Virtual for virtualized infinite lists.
- Optimistic mutations: use `onMutate` to snapshot and update the cache, `onError` to restore, `onSettled` to sync.
- `useQueries` for parallel queries with dynamic count. `useSuspenseQueries` for parallel suspended queries.

### SWR
- Lightweight alternative. Use `useSWR` with a global fetcher. Leverage `mutate` for local cache updates and revalidation.
- Use `useSWRInfinite` for pagination and infinite scroll.
- `useSWRImmutable` for data that never changes (static reference data).
- `SWRConfig` provides global configuration: `{ fetcher, revalidateOnFocus, dedupingInterval }`.

## Next.js 15 Patterns

### App Router
- Use the `app/` directory with layout nesting. Shared layouts persist state across route changes. Use `loading.tsx` for route-level Suspense and `error.tsx` for error boundaries.
- **Partial Prerendering (PPR)**: Opt in with `export const experimental_ppr = true`. Static shell is prerendered at build time; dynamic content streams in via Suspense. Combines SSG speed with SSR dynamism.
- **`after()`**: Run code after the response has streamed to the client. Use for logging, analytics, and background tasks that should not block the response.
- Route groups `(group)/` organize routes without affecting URL structure. Parallel routes `@slot/` render multiple pages simultaneously in one layout.
- Intercepting routes `(.)folder` show a route in a modal overlay while preserving the underlying page (e.g., photo lightboxes from feed).

### Server Actions
- Define with `"use server"` directive. Use for form mutations, database writes, and revalidation. Call `revalidatePath` or `revalidateTag` after writes.
- Invoke directly in `<form action={serverAction}>` or imperatively with `serverAction(formData)`.
- Combine with `useActionState` and `useFormStatus` for full pending/error UI without client state management.
- Validate input server-side with Zod before processing. Never trust client-provided data.

### Turbopack (Next.js)
- Enable with `next dev --turbo`. Incrementally compiles only changed modules and their dependents.
- Supports React Server Components, CSS Modules, PostCSS, TypeScript, and `@next/font` out of the box.
- Persistent cache across restarts reduces cold start time. Located in `.next/cache/turbopack`.
- Production build still uses webpack in Next.js 15; Turbopack production is in active development.

### Metadata and SEO
- Export `metadata` or `generateMetadata` from page/layout files. `generateMetadata` can fetch data server-side.
- Use `metadataBase` in the root layout for resolving absolute Open Graph image URLs.
- Dynamic OG images: `app/opengraph-image.tsx` with the ImageResponse API from `next/og`.

## Routing Alternatives

### Remix v2 / React Router 7
- Remix v2 merges with React Router 7. Use loaders/actions co-located with routes for data loading and mutations.
- `loader` functions run on the server before rendering. `action` functions handle form submissions. `useFetcher` for non-navigation data mutations.
- Progressive enhancement: forms work without JavaScript. Add client-side behavior incrementally.
- `defer()` in loaders enables streaming: critical data awaited, non-critical data deferred through Suspense.
- Nested routes share layouts. `<Outlet>` renders child routes. Error and pending states scoped per route segment.
- Route file convention: `app/routes/products.$id.tsx` creates `/products/:id`. Index routes: `_index.tsx`.

### TanStack Router
- Type-safe client-side router with full TypeScript inference for route params, search params, and loader data.
- Define routes with `createRootRoute()`, `createRoute()`, and `createRouter()`. File-based routing via `@tanstack/router-plugin`.
- Search params as first-class state: `route.useSearch()` returns typed, validated search params. Use `zod` for search param schemas.
- `route.useParams()` and `route.useLoaderData()` are fully typed without casting.
- Integrate with TanStack Query: use `queryClient` in route loaders for data fetching with cache.
- Supports code splitting per route, parallel data loading, and pending/error boundaries scoped to route segments.

## UI Libraries and Component Systems

### shadcn/ui
- Not a library — it is a collection of copy-paste components built on Radix UI primitives and Tailwind CSS.
- Add components via `npx shadcn-ui@latest add button`. Components are added to your `components/ui/` directory and are fully owned and customizable.
- Each component is a thin, styled wrapper around a Radix UI primitive. Customize the Tailwind classes directly.
- Use the CLI to add new components. Update strategy: re-run the CLI and merge changes manually.
- Configure via `components.json`: set the style (default/new-york), base color, CSS variables, and TypeScript preference.

### Radix UI Primitives
- Unstyled, accessible component primitives: `Dialog`, `DropdownMenu`, `Select`, `Popover`, `Tooltip`, `Accordion`, `Tabs`, `Toast`, etc.
- All primitives follow WAI-ARIA patterns. Focus management, keyboard navigation, and screen reader announcements are built in.
- Use `asChild` prop to delegate rendering to a custom element: `<Trigger asChild><button>Click</button></Trigger>`.
- Compose with any styling solution: Tailwind, CSS Modules, Vanilla Extract, Emotion.

### Ark UI
- Headless component library from Chakra UI team. Framework-agnostic: supports React, Vue, and Solid.
- Built on Zag.js state machines for reliable interactive behavior.
- Components: `DatePicker`, `ColorPicker`, `FileUpload`, `NumberInput`, `RangeSlider`, `TagsInput`, `TreeView`, etc.
- Use with Park UI for pre-styled variants, or style raw Ark UI components yourself.

### React Aria (Adobe)
- Fully accessible, unstyled, and WAI-ARIA-compliant hooks and components from Adobe.
- `useButton`, `useTextField`, `useSelect`, `useDialog`, `useDatePicker`, `useCalendar` — all with ARIA patterns, keyboard support, and internationalization.
- React Aria Components (`react-aria-components`) provides pre-composed components using the hooks internally.
- Supports virtualized lists with `useVirtualizer`. Handles complex cases: RTL, high-contrast mode, mobile touch.

## Animation

### Framer Motion
- Use `motion.div` components for declarative animations. Define `initial`, `animate`, and `exit` states.
- `AnimatePresence` handles exit animations when components are removed from the tree. Required for mount/unmount transitions.
- Layout animations: `layout` prop animates between layout changes (resize, reorder) automatically.
- `useMotionValue` and `useTransform` for physics-based scroll animations and drag interactions.
- Variants system: define named animation states and orchestrate children animations with `staggerChildren` and `delayChildren`.
- Use `LazyMotion` with `domAnimation` feature pack to reduce bundle size from ~34KB to ~16KB gzipped.
- `useScroll` for scroll-driven animations: track scroll progress and transform to opacity, scale, or position.

## Advanced Patterns

### React Three Fiber
- Declarative Three.js in React. JSX describes the 3D scene graph: `<mesh>`, `<boxGeometry>`, `<meshStandardMaterial>`.
- `useFrame` hook runs a callback every animation frame. Use for animation loops without lifecycle boilerplate.
- `useThree` accesses the renderer, camera, and scene from any component in the canvas tree.
- Drei library provides pre-built abstractions: `<OrbitControls>`, `<Environment>`, `<Text>`, `<Html>` overlay.
- For performance: use `instancedMesh` for repeated geometries, `useMemo` for geometries and materials, and `Suspense` for async asset loading.

### React Email
- Build HTML emails with React components. `@react-email/components` provides email-safe primitives: `Button`, `Text`, `Section`, `Container`, `Img`, `Link`, `Hr`.
- Render to HTML string with `render(<MyEmail />)` from `@react-email/render`.
- Preview with `email dev` CLI server. Supports hot reload and cross-client preview.
- Send via Resend, SendGrid, Postmark, or Nodemailer. Pass the rendered HTML string to the sending API.
- Inline critical styles. Avoid CSS classes, flexbox, and grid — most email clients do not support them.

### Million.js
- Compiler that replaces React's virtual DOM reconciler with a block-based diffing algorithm for list-heavy UIs.
- Wrap components with `block()` HOC or use the `million/compiler` Vite/webpack plugin for automatic optimization.
- Best for static components rendering large arrays of data. Less effective for deeply nested dynamic trees.
- Benchmark before enabling: not all components benefit. Use the Million Lint tool to identify candidates.

### React Native for Web / Expo for Web
- `react-native-web` maps React Native components to DOM elements. Use for code sharing between web and native.
- Expo for Web (`expo start --web`) runs Expo apps in the browser using `react-native-web` and Metro bundler.
- Universal components: `View`, `Text`, `TextInput`, `ScrollView`, `Pressable` work on both platforms.
- Platform-specific code: use `.web.tsx` and `.native.tsx` file extensions for platform divergence.
- Limitations: not a replacement for semantic HTML. Use for cross-platform teams sharing logic, not for public web apps where SEO and accessibility matter.

## React DevTools Profiler

- Open Profiler tab in React DevTools. Record a render sequence. Inspect the flame graph for slow components.
- **Commit detail view**: Each commit shows which components re-rendered and why (props changed, hooks changed, parent re-rendered).
- **Ranked chart**: Lists all components by render duration in a single commit. Identify the most expensive renders.
- **Why did this render?**: Enable "Record why each component rendered" in settings to see the specific prop or state that triggered the re-render.
- Use `<Profiler id="..." onRender={callback}>` in production-safe profiling for specific subtrees. Log render duration to your monitoring service.
- Trace memory with the Chrome Memory panel alongside React DevTools to detect component-level memory leaks.

## Form Handling

### React Hook Form + Zod
- Use React Hook Form (RHF) for performant, uncontrolled form management. Minimal re-renders: only the changed field re-renders.
- `useForm<FormValues>({ resolver: zodResolver(schema) })` integrates Zod validation.
- `register` attaches fields to the form. `handleSubmit` validates and calls the submit handler. `formState.errors` provides typed field errors.
- `Controller` wraps controlled components (Radix, Material UI) that cannot use `register` directly.
- `useFieldArray` for dynamic field lists (line items, tags, addresses).
- Define the Zod schema as the source of truth. Derive `FormValues` with `z.infer<typeof schema>`.
- Use `mode: 'onBlur'` for validation-on-blur in long forms. Use `mode: 'onChange'` for real-time feedback in short forms.
