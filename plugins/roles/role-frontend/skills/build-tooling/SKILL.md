---
name: build-tooling
description: |
  Build tooling expertise including Vite, webpack 5, esbuild, SWC, Turbopack,
  module federation, monorepo tooling (Nx, Turborepo), ESLint/Prettier
  configuration, and TypeScript configuration.
allowed-tools: Read, Grep, Glob, Bash
---

# Build Tooling

## When to use
- Setting up a new frontend project and choosing a build tool
- Configuring dev server, HMR, proxy, or library mode in Vite
- Replacing Babel with SWC or esbuild for faster transpilation
- Building micro-frontend architectures with Module Federation
- Setting up a monorepo with Turborepo or Nx
- Configuring ESLint flat config, Biome, Prettier, or pre-commit hooks
- Optimizing bundle size or establishing size budgets

## Core principles
1. **Vite first** for new projects — native ESM dev server, Rollup production builds, massive plugin ecosystem
2. **SWC over Babel** for transpilation — 20-70x faster, drop-in replacement
3. **pnpm for monorepos** — prevents phantom dependencies, hard links save disk
4. **Bundle budgets in CI** — `size-limit` blocks bloat before it ships
5. **Biome or separate tools** — never run Prettier as an ESLint plugin

## Reference Files

- `references/vite-esbuild-swc.md` — Vite config patterns, plugins, HMR, env vars, library mode, SSR mode; esbuild build API; SWC .swcrc and jest integration
- `references/webpack-turbopack-module-federation.md` — webpack 5 persistent cache, code splitting, bundle analysis; Turbopack vs Vite comparison; Module Federation remote/host setup
- `references/linting-formatting-typescript.md` — Biome config, ESLint 9+ flat config with TypeScript/React/a11y rules, Prettier config, pre-commit hooks, TypeScript strict tsconfig and project references
- `references/monorepo-modules-packages.md` — Turborepo and Nx task pipelines, pnpm workspaces, package manager comparison, dual ESM/CJS exports, bundle analysis tools, anti-patterns
