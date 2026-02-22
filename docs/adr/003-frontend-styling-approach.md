# ADR-003: Frontend Styling Approach

## Status
ACCEPTED

## Date
2025-02-21

## Context
The project requires a consistent, maintainable styling approach for a B2B SaaS dashboard built with Next.js.
Key requirements:
- Design consistency across components
- Developer ergonomics for a small team
- Performance (minimal CSS bundle, no runtime style injection)
- Compatibility with Next.js App Router and server components

## Options Considered

### Option A: Tailwind CSS v4
- **Pros:** Utility-first approach enables rapid UI development, no runtime overhead, excellent Next.js integration, v4 introduces native CSS variables and improved performance, no context switching between files for co-located styles
- **Cons:** Long className strings reduce HTML readability, not a design system in itself (requires discipline to create consistent tokens), component abstraction needed to avoid duplication

### Option B: CSS-in-JS (styled-components, Emotion)
- **Pros:** Component-level encapsulation, dynamic styles based on props, familiar React patterns
- **Cons:** Runtime overhead, incompatible with React Server Components (requires client-side hydration), bundle size increase, not compatible with Next.js App Router streaming

### Option C: CSS Modules
- **Pros:** Zero runtime overhead, local scope by default, works with server components
- **Cons:** Context switching between .module.css files, verbose for simple utilities, no built-in design token system

### Option D: Vanilla Extract / Panda CSS
- **Pros:** Type-safe, zero runtime, works with server components
- **Cons:** Additional build tooling, smaller ecosystem, team unfamiliarity

## Decision
**Option A: Tailwind CSS v4 with custom design tokens.**

Custom tokens defined via CSS variables in `globals.css`. Shared UI components created for recurring patterns to avoid className duplication.

## Rationale
- CSS-in-JS is incompatible with Next.js App Router server components — eliminated immediately
- Tailwind v4's native CSS variable support enables a proper design token layer without additional tooling
- Utility-first approach matches the rapid iteration speed required for B2B SaaS development
- The team has existing Tailwind experience; no ramp-up time required
- Performance characteristics (static CSS at build time, no runtime injection) align with Vercel deployment model

## Consequences
- Component library of shared UI primitives required to avoid className sprawl in complex components
- Design tokens (colors, spacing, typography) must be defined explicitly in CSS variables, not scattered as arbitrary Tailwind values
- ESLint rule for `tailwind-merge` should be enforced to prevent conflicting utility classes
- Viktor's objection noted: "it's not a design system, it's inline styles with extra steps" — acknowledged; component abstraction layer partially addresses this

## Related
- Depends on: Next.js App Router (reason CSS-in-JS was eliminated)
- Informs: Future ADR on component library structure (shadcn/ui vs custom primitives)
