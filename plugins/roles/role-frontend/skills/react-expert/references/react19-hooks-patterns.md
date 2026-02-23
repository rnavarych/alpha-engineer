# React 19 Features and Hooks Patterns

## When to load
Load when working with React 19 actions, useActionState, useOptimistic, the use() hook, React Compiler, Activity component, or choosing and composing core hooks (useState, useEffect, useTransition, useDeferredValue, custom hooks).

## React 19 New Features

### Actions and Form State
- **Actions**: Async functions passed to form `action` props or transition APIs. React manages pending state, error handling, and optimistic updates automatically.
- **useActionState**: `const [state, dispatch, isPending] = useActionState(action, initialState)`. Replaces the `useFormState` pattern — provides pending state and last action result without manual state management.
- **useFormStatus**: `const { pending, data, method, action } = useFormStatus()`. Reads the status of the parent `<form>` action. Use inside form child components (e.g., a Submit button) to disable during submission without prop drilling.
- **useOptimistic**: `const [optimisticValue, addOptimistic] = useOptimistic(state, reducer)`. Apply optimistic updates during a pending async transition. React rolls back automatically on error.

### use() Hook
- `use(promise)` reads a promise or context inside render. Unlike hooks, it can be called conditionally and inside loops.
- Suspense unwraps the promise — wrap the component in `<Suspense fallback={...}>` to show loading UI.
- `use(Context)` reads context values; usable inside Server Components for context access.

### React Compiler (formerly React Forget)
- Automatically memoizes components and hooks — inserts `useMemo`, `useCallback`, `memo` at the compiler level.
- Enable with `babel-plugin-react-compiler` or Vite/Next.js plugin equivalents.
- Requires adherence to the Rules of Hooks. Run `react-compiler-healthcheck` before enabling.
- After enabling, remove manual `useMemo`/`useCallback`/`memo` calls. Profile with React DevTools to verify.

### Activity (Offscreen)
- `<Activity mode="hidden">` keeps a component tree mounted and state preserved while removing it from visible DOM.
- Use for pre-rendered routes, background tabs, and cached panels. Replaces the unmount/remount pattern.
- `mode="visible"` | `"hidden"` to toggle. React defers work in hidden trees to prioritize visible content.

## Core Hooks

- **useState**: Prefer functional updates (`setState(prev => prev + 1)`) when new value depends on previous. Avoid storing derived state — compute during render.
- **useEffect**: Treat as synchronization, not lifecycle. Always specify the dependency array. Clean up subscriptions, timers, and event listeners in the return function.
- **useCallback**: Wrap callbacks passed to memoized children or used in dependency arrays. Do not wrap every function — only where referential stability matters.
- **useMemo**: For expensive computations (filtering large lists, complex transformations). Profile before optimizing.
- **useRef**: DOM references, mutable values that should not trigger re-renders (previous values, interval IDs), and imperative handle forwarding with `forwardRef`.
- **useTransition**: Mark non-urgent state updates so React can interrupt them. Use for filtering, sorting, tab switching. `isPending` indicates progress.
- **useDeferredValue**: Defer rendering of an expensive child while showing stale content. Parent re-renders immediately; deferred child catches up when browser is idle.
- **useId**: Stable, unique IDs for accessibility (linking labels to inputs). Consistent between server and client renders.

## Custom Hooks

- Extract reusable logic into custom hooks prefixed with `use`. Each hook encapsulates a single concern.
- Return tuples `[value, setter]` for simple state hooks. Return objects `{ data, error, loading }` for complex hooks.
- Compose custom hooks from other hooks. Avoid deeply nested hook chains.
- Common patterns: `useDebounce`, `useMediaQuery`, `useLocalStorage`, `useIntersectionObserver`, `usePrevious`, `useAbortController`, `useEventListener`, `useIsomorphicLayoutEffect`.
