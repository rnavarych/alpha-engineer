---
name: role-frontend:react-expert
description: React expertise covering hooks, server components, React 19 actions and compiler, Next.js 15 App Router, Remix, TanStack Router and Query v5, Zustand, Jotai, shadcn/ui, Radix UI, Framer Motion, concurrent features, and React DevTools profiling.
allowed-tools: Read, Grep, Glob, Bash
---

# React Expert

## When to use
- Building React 19 features: actions, useActionState, useOptimistic, use() hook, Activity component
- Enabling React Compiler and removing manual memoization (useMemo/useCallback/memo)
- Choosing the right hook for state, effects, transitions, or deferred rendering
- Designing component hierarchies with error boundaries, compound components, or lazy loading
- Implementing React Server Components, Server Actions, and Suspense streaming
- Configuring TanStack Query v5, SWR, or data fetching with Next.js App Router patterns
- Routing with Next.js 15, Remix v2 / React Router 7, or TanStack Router
- Selecting and integrating UI libraries (shadcn/ui, Radix UI, Ark UI, React Aria)
- Profiling re-renders with React DevTools and optimizing with Million.js
- Building forms with React Hook Form and Zod

## Core principles
1. **Server Components by default** — add `"use client"` only when interactivity is genuinely required
2. **React Compiler kills manual memoization** — remove useMemo/useCallback/memo when the compiler is enabled
3. **Suspense is the loading primitive** — wrap async boundaries with Suspense, not conditional isLoading checks
4. **useActionState over custom form state** — React 19 manages pending, error, and result for you
5. **TanStack Query over manual fetch state** — staleTime, gcTime, and queryKey structure matter more than the fetcher

## Reference Files

- `references/react19-hooks-patterns.md` — useActionState/useFormStatus/useOptimistic, use() hook, React Compiler setup, Activity component, core hooks (useState through useId), custom hooks best practices and common patterns
- `references/components-server-concurrent.md` — component composition, compound components, forwardRef, error boundaries with react-error-boundary, Server Components rules, Server Actions, server-only package, Suspense patterns, SuspenseList, Streaming SSR, Transition API
- `references/data-fetching-nextjs15.md` — TanStack Query v5 breaking changes and patterns, SWR, Next.js 15 App Router (PPR, after(), route groups, parallel/intercepting routes), Server Actions with Zod validation, Turbopack, metadata/SEO, Remix v2/React Router 7, TanStack Router type-safe routing
- `references/ui-animation-advanced-forms.md` — shadcn/ui setup and customization, Radix UI primitives and asChild, Ark UI, React Aria, Framer Motion (AnimatePresence, layout animations, LazyMotion), React Three Fiber, React Email, Million.js block compiler, React DevTools Profiler, React Hook Form with Zod
