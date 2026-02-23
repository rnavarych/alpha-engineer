---
name: state-management
description: |
  State management expertise including local vs global state decisions, Redux Toolkit,
  Zustand, Jotai, MobX, Context API patterns, server state (React Query, SWR) vs
  client state, optimistic updates, and state machines with XState.
allowed-tools: Read, Grep, Glob, Bash
---

# State Management

## When to use
- Deciding where state lives — local, global, server cache, URL, or form
- Setting up Zustand, Jotai, or Redux Toolkit stores
- Replacing axios+useState patterns with TanStack Query
- Implementing optimistic updates for mutations
- Building complex UI flows with XState state machines
- Migrating from Redux to Zustand, or Context to a proper store
- Diagnosing unnecessary re-renders from over-broad state subscriptions

## Core principles
1. **Server state belongs in TanStack Query or SWR** — never duplicate API data in a client store
2. **URL is state too** — pagination, filters, search: use `nuqs` or router search params
3. **Keep it local as long as possible** — global state is a last resort, not a default
4. **Selectors prevent re-renders** — subscribe to slices, not the whole store
5. **XState for impossible states** — if "loading" and "error" can't coexist, the machine enforces it

## Reference Files

- `references/react-state-primitives.md` — state category decision table, useState/useReducer patterns, useContext (when/when not), useSyncExternalStore, React 19 use(), stale closure prevention
- `references/server-state-tanstack-query.md` — TanStack Query v5 queries, optimistic mutations with onMutate/onError/onSettled, infinite queries, prefetch on hover, SWR alternative
- `references/global-state-zustand-jotai-redux.md` — Zustand with immer/persist/devtools middleware, granular selectors, Jotai atom composition, RTK createSlice/createEntityAdapter, URL state with nuqs, React Hook Form + Zod, XState machines, Preact signals, anti-patterns
