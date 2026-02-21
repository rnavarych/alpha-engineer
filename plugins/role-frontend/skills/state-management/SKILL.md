---
name: state-management
description: |
  State management expertise including local vs global state decisions, Redux Toolkit,
  Zustand, Jotai, MobX, Context API patterns, server state (React Query, SWR) vs
  client state, optimistic updates, and state machines with XState.
allowed-tools: Read, Grep, Glob, Bash
---

# State Management

## Local vs Global State

- **Local state**: State that only one component or a small subtree needs. Use `useState`, `useReducer` (React), `ref`/`reactive` (Vue), or signals (Angular). Keep state as close to where it is used as possible.
- **Global state**: State shared across distant parts of the component tree (auth user, theme, feature flags, shopping cart). Use a dedicated state management library.
- **Decision criteria**: If lifting state up requires passing props through more than two intermediate components, consider global state. If the state resets when the component unmounts and that is correct behavior, keep it local.
- **URL state**: Pagination, filters, search queries, and selected tabs should live in the URL (query params or path segments). The URL is the source of truth; components read from it.
- **Form state**: Keep form state local with a form library (React Hook Form, Formik, VeeValidate). Do not store transient input values in global state.

## Redux Toolkit

- Use Redux Toolkit (RTK) as the standard way to write Redux. Never write Redux without RTK.
- Define slices with `createSlice`. Each slice owns a domain: `userSlice`, `cartSlice`, `notificationsSlice`. Colocate actions, reducers, and selectors.
- Use `createAsyncThunk` for API calls. Handle `pending`, `fulfilled`, and `rejected` states in `extraReducers`.
- Use RTK Query for data fetching. Define API slices with `createApi` and `fetchBaseQuery`. RTK Query handles caching, deduplication, polling, and optimistic updates.
- Use `createSelector` from Reselect (included in RTK) for memoized derived state. Compose selectors for complex derivations.
- Use `createEntityAdapter` for normalized collections (lists of items with IDs).
- Keep the store shape flat and normalized. Avoid deeply nested state.

## Zustand

- Use Zustand for lightweight global state without boilerplate. Define stores as hooks: `const useStore = create((set) => ({ ... }))`.
- Access only the state slices a component needs using selectors: `const count = useStore(state => state.count)`. This prevents unnecessary re-renders.
- Use middleware: `persist` for localStorage, `devtools` for Redux DevTools integration, `immer` for mutable-style updates.
- Zustand stores work outside React components. Use `useStore.getState()` and `useStore.setState()` in plain functions, event handlers, or server-side code.
- Split large stores into multiple smaller stores by domain rather than creating one monolithic store.

## Jotai

- Use Jotai for atomic state management. Define atoms with `atom()` and read/write them in components with `useAtom()`.
- Atoms are bottom-up: start with primitive atoms and compose them into derived atoms with `atom(get => get(baseAtom) * 2)`.
- Use `atomWithStorage` for persistent state, `atomWithQuery` for server data, and `focusAtom` for lens-based substate access.
- Jotai eliminates the need for React Context for most global state use cases. Each atom is an independent unit of state.
- Use `Provider` only when you need state isolation (e.g., in tests or embedded widgets).

## MobX

- Use MobX for reactive state with automatic dependency tracking. Define observable classes with `makeAutoObservable` in the constructor.
- Use `observer()` HOC (from `mobx-react-lite`) to make components reactive to observable changes.
- Keep side effects in `reaction()` or `autorun()`. Use `reaction` when you need to react to specific observable values; use `autorun` when you want to track all accessed observables.
- Structure stores as plain classes. Inject them via React Context or a simple dependency injection pattern.
- MobX uses mutable state with proxies. This is a different mental model from Redux. Choose MobX when the team is comfortable with mutable patterns.

## Context API

- Use React Context for low-frequency global state: theme, locale, auth status, feature flags.
- Do not use Context for high-frequency updates (form inputs, animation state, search results). Every context change re-renders all consumers.
- Split contexts by concern: `ThemeContext`, `AuthContext`, `LocaleContext`. Avoid a single "AppContext" that combines unrelated state.
- Wrap context values in `useMemo` to prevent unnecessary re-renders: `const value = useMemo(() => ({ user, logout }), [user])`.
- Combine Context with `useReducer` for dispatch-based state management that does not require an external library.

## Server State vs Client State

- **Server state**: Data that originates from the server (user profiles, product lists, order history). It is async, cacheable, shared, and can become stale. Use React Query, SWR, RTK Query, or Apollo Client.
- **Client state**: Data that exists only in the browser (UI toggles, form drafts, selected tabs, modal open/close). It is synchronous, local, and ephemeral. Use local state or a lightweight store.
- Never duplicate server data into client state stores. Let the data fetching library own the cache. Components read from the cache, not from Redux.
- Synchronize server and client state at the boundary: after a mutation succeeds, invalidate or update the server state cache. Do not manually sync two sources of truth.

## Optimistic Updates

- Apply the update to the UI immediately before the server confirms it. Roll back if the server request fails.
- With React Query: use `onMutate` to snapshot the previous state, update the cache, and return the snapshot. Use `onError` to restore the snapshot. Use `onSettled` to refetch for consistency.
- With Redux/Zustand: dispatch an optimistic action that updates the store, then dispatch a confirm or rollback action based on the API response.
- Show subtle indicators (saving spinner, "Saving..." text) during the optimistic window so users know the action is in progress.
- Use optimistic updates for low-risk actions (toggling a like, reordering a list). Avoid optimistic updates for high-risk actions (payments, deletions) where a failure has significant consequences.

## State Machines (XState)

- Use XState for complex UI state that has well-defined states and transitions: multi-step forms, media players, connection status, drag-and-drop workflows.
- Define machines with `createMachine`. States are explicit nodes (idle, loading, success, error). Transitions are triggered by events. Guards control conditional transitions.
- Use `invoke` for async operations (API calls, timers). The machine handles pending, resolved, and rejected states declaratively.
- Use `@xstate/react` with `useMachine` or `useActor` hooks. The machine drives the UI; the component renders based on the current state.
- State machines make impossible states impossible. If "loading" and "error" cannot coexist, the machine enforces that constraint by design.
- Use the XState visualizer (stately.ai/viz) to diagram and validate state machines before implementation.
