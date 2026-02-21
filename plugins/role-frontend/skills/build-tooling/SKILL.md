---
name: build-tooling
description: |
  Build tooling expertise including Vite, webpack 5, esbuild, SWC, Turbopack,
  module federation, monorepo tooling (Nx, Turborepo), ESLint/Prettier
  configuration, and TypeScript configuration.
allowed-tools: Read, Grep, Glob, Bash
---

# Build Tooling

## Vite

- Use Vite as the default build tool for new frontend projects. It provides instant dev server startup with native ES modules and fast HMR.
- Configure `vite.config.ts` with framework plugins: `@vitejs/plugin-react` (React), `@vitejs/plugin-vue` (Vue), `@analogjs/vite-plugin-angular` (Angular).
- Use Vite's built-in code splitting. Dynamic `import()` calls automatically create separate chunks.
- Configure `build.rollupOptions.output.manualChunks` for fine-grained vendor splitting (separate React, lodash, or chart libraries).
- Use environment variables with `import.meta.env`. Prefix client-exposed variables with `VITE_`.
- Enable `build.sourcemap` for production debugging. Use `'hidden'` to generate source maps without exposing them in the browser.
- Use `vite preview` to test production builds locally before deployment.

## Webpack 5

- Use webpack 5 for projects that require Module Federation, advanced loader configurations, or legacy plugin support.
- Enable persistent caching with `cache: { type: 'filesystem' }` to speed up rebuilds.
- Use `splitChunks` optimization to extract common vendor code and shared modules into separate chunks.
- Configure `resolve.alias` for path shortcuts. Mirror aliases in `tsconfig.json` paths for TypeScript compatibility.
- Use `webpack-bundle-analyzer` in CI to visualize and track bundle composition over time.
- Minimize loader chains. Each loader adds build time. Use SWC-loader or esbuild-loader instead of babel-loader for faster transpilation.

## esbuild

- Use esbuild for ultra-fast TypeScript/JavaScript transpilation and bundling. It is 10-100x faster than webpack for raw bundling.
- esbuild is used internally by Vite for dev-mode transpilation. Use it directly for building libraries, CLI tools, and server-side code.
- Configure with `esbuild.build()` API or the CLI. Set `target` to your minimum browser support level.
- Limitations: no HMR, limited plugin ecosystem, no CSS Modules out of the box. Use Vite or webpack for full application builds that need these features.
- Use esbuild for TypeScript type-stripping in CI scripts and serverless functions where build speed matters most.

## SWC

- Use SWC as a drop-in replacement for Babel. It is written in Rust and is 20-70x faster for transpilation.
- Next.js uses SWC by default. Configure with `.swcrc` for standalone use or `jsc` options in the framework config.
- SWC supports JSX transform, TypeScript stripping, decorator syntax, and module transformations.
- Use `@swc/jest` as a Jest transformer for significantly faster test execution compared to `ts-jest` or `babel-jest`.
- Use `swc-loader` in webpack as a faster alternative to `babel-loader`.

## Turbopack

- Turbopack is the webpack successor by Vercel, built in Rust. Use it with Next.js (`next dev --turbo`) for faster development builds.
- Turbopack provides incremental computation: only recompiles the modules that changed and their dependents.
- Currently optimized for development mode with Next.js. Production builds still use webpack in Next.js.
- Supports React Server Components, CSS Modules, PostCSS, and TypeScript out of the box with zero configuration.
- Monitor Turbopack stability. As of 2025, it is production-ready for dev mode but still maturing for general-purpose use.

## Module Federation

- Use Module Federation (webpack 5) for micro-frontend architectures. Multiple independently deployed applications share components and libraries at runtime.
- Define `exposes` in the remote application for shared components. Define `remotes` in the host application to consume them.
- Share common dependencies (React, React DOM, design system) with `shared` configuration to avoid loading duplicates. Set `singleton: true` for libraries that must have a single instance.
- Use `@module-federation/enhanced` for Vite and Rspack support beyond webpack.
- Handle versioning carefully. Mismatched shared dependency versions cause runtime errors. Pin shared library versions or use version ranges.
- Implement a fallback strategy for when a remote module is unavailable (network errors, deployment issues).

## Monorepo Tooling

### Nx
- Use Nx for large monorepos with multiple applications and shared libraries. Nx provides task orchestration, caching, and affected-project detection.
- Define project boundaries with `@nx/enforce-module-boundaries` lint rule to prevent unwanted cross-project imports.
- Use Nx generators to scaffold consistent project structures: `nx generate @nx/react:component`, `nx generate @nx/angular:library`.
- Enable distributed caching with Nx Cloud for sharing build caches across CI and developer machines.

### Turborepo
- Use Turborepo for simpler monorepos that need task pipelining and caching without a full framework.
- Define `turbo.json` with task pipelines. Tasks declare their dependencies and outputs for caching.
- Use workspace-level `package.json` scripts. Turborepo parallelizes independent tasks across packages.
- Enable remote caching with Vercel for shared build artifacts.

## ESLint and Prettier Configuration

- Use ESLint for code quality and Prettier for formatting. Do not use ESLint for formatting rules; they conflict with Prettier.
- Use `eslint-config-prettier` to disable ESLint rules that conflict with Prettier. Run Prettier as a separate step, not as an ESLint plugin.
- Framework-specific configs: `eslint-plugin-react-hooks` (React), `eslint-plugin-vue` (Vue), `@angular-eslint/schematics` (Angular).
- Enable `eslint-plugin-jsx-a11y` for accessibility linting in JSX. Enable `eslint-plugin-import` for import order and unused import detection.
- Configure Prettier with minimal options: `{ "singleQuote": true, "trailingComma": "all", "printWidth": 100 }`. Consistency matters more than specific choices.
- Use flat config (`eslint.config.js`) for ESLint 9+. Migrate from `.eslintrc` files to the flat config format.
- Run both ESLint and Prettier in CI as a pre-merge check. Use `lint-staged` with `husky` for pre-commit hooks.

## TypeScript Configuration

- Enable strict mode: `"strict": true` in `tsconfig.json`. This enables `strictNullChecks`, `noImplicitAny`, `strictFunctionTypes`, and other safety checks.
- Use project references for monorepos: each package has its own `tsconfig.json` that extends a root config. Use `"composite": true` and `"references"`.
- Set `"moduleResolution": "bundler"` for Vite/webpack projects. Use `"moduleResolution": "node16"` for Node.js libraries.
- Configure path aliases: `"paths": { "@/*": ["./src/*"] }` in `tsconfig.json` and mirror in the bundler config.
- Use `"isolatedModules": true` for compatibility with esbuild and SWC, which transpile files independently.
- Use `"skipLibCheck": true` to speed up type checking by skipping `.d.ts` files from `node_modules`. Enable full checking periodically.
- Set `"target"` and `"lib"` based on your browser support matrix. Use `"target": "ES2022"` for modern browsers.
