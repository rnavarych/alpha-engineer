---
name: typescript-patterns
description: Advanced TypeScript patterns — type design, runtime validation, error handling, monorepo configuration
allowed-tools: Read, Grep, Glob, Bash
---

# TypeScript Patterns Skill

## Core Principles
- **Strict mode always**: `strict: true` catches entire classes of bugs at compile time.
- **Discriminated unions over exceptions**: `Result<T, E>` is explicit; `throw` is invisible.
- **Branded types prevent mix-ups**: `UserId` and `OrderId` should not be interchangeable.
- **Zod is the bridge**: Runtime validation + TypeScript types from one source of truth.
- **`satisfies` over `as`**: `satisfies` validates without widening; `as` silences errors.

## References
- `references/type-patterns.md` — Discriminated unions, template literals, conditional/mapped types, infer
- `references/runtime-validation.md` — Zod, Valibot schema-first with type inference
- `references/error-handling.md` — Result type, typed errors, neverthrow
- `references/monorepo-patterns.md` — Turborepo, Nx, pnpm workspaces, build caching
