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

### Configuration Patterns

```ts
// vite.config.ts
import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'
import { visualizer } from 'rollup-plugin-visualizer'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')

  return {
    plugins: [
      react(),
      mode === 'analyze' && visualizer({ open: true, gzipSize: true }),
    ],
    resolve: {
      alias: {
        '@': '/src',
        '@components': '/src/components',
        '@lib': '/src/lib',
      },
    },
    server: {
      port: 3000,
      proxy: {
        '/api': {
          target: env.API_URL || 'http://localhost:8080',
          changeOrigin: true,
          rewrite: (path) => path.replace(/^\/api/, ''),
        },
      },
    },
    build: {
      sourcemap: 'hidden',
      rollupOptions: {
        output: {
          manualChunks: {
            vendor: ['react', 'react-dom'],
            router: ['react-router-dom'],
            query: ['@tanstack/react-query'],
          },
        },
      },
    },
  }
})
```

### Vite Plugins

```ts
import AutoImport from 'unplugin-auto-import/vite'
import { VitePWA } from 'vite-plugin-pwa'
import tsconfigPaths from 'vite-tsconfig-paths'

plugins: [
  // Auto-import hooks and utilities without explicit imports
  AutoImport({
    imports: ['react', 'react-router-dom'],
    dts: 'src/auto-imports.d.ts',
  }),

  // PWA support
  VitePWA({
    registerType: 'autoUpdate',
    workbox: {
      globPatterns: ['**/*.{js,css,html,ico,png,svg}'],
    },
  }),

  // Resolve tsconfig paths
  tsconfigPaths(),
]
```

### HMR (Hot Module Replacement)

- Vite HMR works at the module level. Only the changed module and its immediate dependents are re-evaluated.
- Custom HMR handling for state preservation:

```ts
// Preserve state across HMR updates
if (import.meta.hot) {
  import.meta.hot.accept()
  import.meta.hot.dispose(() => {
    // cleanup resources
  })
}
```

### Environment Variables

```bash
# .env              - loaded in all cases
# .env.local        - loaded in all cases, ignored by git
# .env.development  - loaded in dev mode
# .env.production   - loaded in production mode

VITE_API_URL=https://api.example.com
VITE_APP_TITLE=My App
# Non-VITE_ prefixed vars are only available server-side
DATABASE_URL=postgres://...
```

```ts
// Access in code
const apiUrl = import.meta.env.VITE_API_URL
const isDev = import.meta.env.DEV
const isProd = import.meta.env.PROD
const mode = import.meta.env.MODE
```

### Library Mode

```ts
// vite.config.ts for building a library
export default defineConfig({
  build: {
    lib: {
      entry: 'src/index.ts',
      name: 'MyLib',
      formats: ['es', 'cjs'],
      fileName: (format) => `my-lib.${format}.js`,
    },
    rollupOptions: {
      external: ['react', 'react-dom'],
      output: {
        globals: { react: 'React', 'react-dom': 'ReactDOM' },
      },
    },
  },
})
```

### SSR Mode

- Vite supports SSR with `vite.ssrLoadModule()` for development and `vite build --ssr` for production builds.
- Frameworks like Nuxt 3, SvelteKit, and Astro use Vite's SSR mode internally.

## Turbopack

- Turbopack is the webpack successor by Vercel, built in Rust. Use it with Next.js (`next dev --turbo`) for faster development builds.
- Turbopack provides incremental computation: only recompiles the modules that changed and their dependents.
- Currently optimized for development mode with Next.js. Production builds still use webpack in Next.js.
- Supports React Server Components, CSS Modules, PostCSS, and TypeScript out of the box with zero configuration.
- Monitor Turbopack stability. As of 2025, it is production-ready for dev mode but still maturing for general-purpose use.

### Comparison with Vite

| Feature | Vite | Turbopack |
|---|---|---|
| Dev server | Native ESM, fast startup | Bundled, incremental compilation |
| Framework support | React, Vue, Svelte, Angular, Solid | Next.js (primary), others planned |
| Production build | Rollup-based | Webpack (in Next.js) |
| Plugin ecosystem | Rich (Rollup-compatible) | Limited (Next.js plugins) |
| Language | JavaScript/TypeScript | Rust |
| Use case | General frontend projects | Next.js projects |

## Webpack 5

- Use webpack 5 for projects that require Module Federation, advanced loader configurations, or legacy plugin support.

### Persistent Caching

```js
// webpack.config.js
module.exports = {
  cache: {
    type: 'filesystem',
    buildDependencies: {
      config: [__filename],
    },
    cacheDirectory: path.resolve(__dirname, '.webpack-cache'),
  },
}
```

### Code Splitting

```js
optimization: {
  splitChunks: {
    chunks: 'all',
    cacheGroups: {
      vendor: {
        test: /[\\/]node_modules[\\/]/,
        name: 'vendors',
        chunks: 'all',
        priority: 10,
      },
      common: {
        minChunks: 2,
        priority: 5,
        reuseExistingChunk: true,
      },
    },
  },
},
```

### Build Analysis

```bash
# Generate stats file and analyze
npx webpack --profile --json > stats.json
npx webpack-bundle-analyzer stats.json

# Or use the plugin
const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin
plugins: [new BundleAnalyzerPlugin({ analyzerMode: 'static' })]
```

- Configure `resolve.alias` for path shortcuts. Mirror aliases in `tsconfig.json` paths for TypeScript compatibility.
- Minimize loader chains. Each loader adds build time. Use SWC-loader or esbuild-loader instead of babel-loader for faster transpilation.

## esbuild

- Use esbuild for ultra-fast TypeScript/JavaScript transpilation and bundling. It is 10-100x faster than webpack for raw bundling.

```ts
// Build API
import * as esbuild from 'esbuild'

await esbuild.build({
  entryPoints: ['src/index.ts'],
  bundle: true,
  outfile: 'dist/index.js',
  platform: 'node',         // or 'browser'
  target: 'node18',         // or 'es2022'
  format: 'esm',            // or 'cjs'
  minify: true,
  sourcemap: true,
  external: ['express'],     // do not bundle these
  define: {
    'process.env.NODE_ENV': '"production"',
  },
})
```

```bash
# CLI usage
esbuild src/index.ts --bundle --outfile=dist/index.js --platform=node --format=esm --minify
```

- esbuild is used internally by Vite for dev-mode transpilation. Use it directly for building libraries, CLI tools, and server-side code.
- Limitations: no HMR, limited plugin ecosystem, no CSS Modules out of the box. Use Vite or webpack for full application builds that need these features.
- Use esbuild for TypeScript type-stripping in CI scripts and serverless functions where build speed matters most.

## SWC

- Use SWC as a drop-in replacement for Babel. It is written in Rust and is 20-70x faster for transpilation.

```json
// .swcrc
{
  "jsc": {
    "parser": {
      "syntax": "typescript",
      "tsx": true,
      "decorators": true
    },
    "transform": {
      "react": {
        "runtime": "automatic"
      }
    },
    "target": "es2022"
  },
  "module": {
    "type": "es6"
  }
}
```

- Next.js uses SWC by default. Configure with `.swcrc` for standalone use or `jsc` options in the framework config.
- SWC supports JSX transform, TypeScript stripping, decorator syntax, and module transformations.
- Use `@swc/jest` as a Jest transformer for significantly faster test execution.

```json
// jest.config.json
{
  "transform": {
    "^.+\\.(t|j)sx?$": ["@swc/jest", {
      "jsc": { "transform": { "react": { "runtime": "automatic" } } }
    }]
  }
}
```

- Use `swc-loader` in webpack as a faster alternative to `babel-loader`.

## Biome

- Biome is an all-in-one formatter and linter, written in Rust. It replaces both ESLint and Prettier with a single tool.

```json
// biome.json
{
  "$schema": "https://biomejs.dev/schemas/1.9.0/schema.json",
  "organizeImports": { "enabled": true },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true,
      "complexity": {
        "noForEach": "warn"
      },
      "suspicious": {
        "noExplicitAny": "error"
      }
    }
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100
  }
}
```

```bash
# Format and lint
biome check --write .

# CI check (no writes)
biome ci .
```

- Migration from ESLint/Prettier: run `biome migrate` to convert existing configs. Not all ESLint rules have Biome equivalents.
- Advantages: single tool, fast (Rust), consistent formatting + linting. Disadvantage: smaller plugin ecosystem than ESLint.

## ESLint

### Flat Config (ESLint 9+)

```js
// eslint.config.js
import js from '@eslint/js'
import tseslint from 'typescript-eslint'
import reactHooks from 'eslint-plugin-react-hooks'
import jsxA11y from 'eslint-plugin-jsx-a11y'
import importPlugin from 'eslint-plugin-import'

export default tseslint.config(
  js.configs.recommended,
  ...tseslint.configs.strictTypeChecked,
  {
    plugins: {
      'react-hooks': reactHooks,
      'jsx-a11y': jsxA11y,
      'import': importPlugin,
    },
    rules: {
      'react-hooks/rules-of-hooks': 'error',
      'react-hooks/exhaustive-deps': 'warn',
      'jsx-a11y/alt-text': 'error',
      'import/order': ['error', {
        groups: ['builtin', 'external', 'internal', 'parent', 'sibling'],
        'newlines-between': 'always',
        alphabetize: { order: 'asc' },
      }],
      '@typescript-eslint/no-unused-vars': ['error', {
        argsIgnorePattern: '^_',
        varsIgnorePattern: '^_',
      }],
    },
    languageOptions: {
      parserOptions: {
        project: './tsconfig.json',
      },
    },
  },
  {
    ignores: ['dist/', 'node_modules/', '*.config.js'],
  },
)
```

- Framework-specific configs: `eslint-plugin-react-hooks` (React), `eslint-plugin-vue` (Vue), `@angular-eslint/schematics` (Angular).
- Enable `eslint-plugin-jsx-a11y` for accessibility linting in JSX.
- Migrate from `.eslintrc` files to the flat config format for ESLint 9+.

## Prettier

```json
// .prettierrc
{
  "singleQuote": true,
  "trailingComma": "all",
  "printWidth": 100,
  "semi": false,
  "tabWidth": 2,
  "arrowParens": "always",
  "endOfLine": "lf"
}
```

- Use `eslint-config-prettier` to disable ESLint rules that conflict with Prettier. Run Prettier as a separate step, not as an ESLint plugin.
- Consistency matters more than specific choices. Pick defaults and stop debating.

### Pre-commit Hooks

```json
// package.json
{
  "lint-staged": {
    "*.{ts,tsx,js,jsx}": ["eslint --fix", "prettier --write"],
    "*.{css,scss,md,json}": ["prettier --write"]
  }
}
```

```bash
# Setup with husky
npx husky init
echo "npx lint-staged" > .husky/pre-commit
```

## TypeScript Configuration

### Strict Mode

```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,                    // enables all strict checks
    "noUncheckedIndexedAccess": true,  // array/object access returns T | undefined
    "exactOptionalPropertyTypes": true, // distinguish undefined from missing
    "forceConsistentCasingInFileNames": true,
    "isolatedModules": true,           // required for esbuild/SWC
    "moduleResolution": "bundler",     // for Vite/webpack projects
    "module": "ESNext",
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "jsx": "react-jsx",
    "skipLibCheck": true,
    "paths": {
      "@/*": ["./src/*"],
      "@components/*": ["./src/components/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### Project References (Monorepo)

```json
// tsconfig.json (root)
{
  "references": [
    { "path": "./packages/shared" },
    { "path": "./packages/ui" },
    { "path": "./apps/web" }
  ],
  "files": []
}

// packages/shared/tsconfig.json
{
  "compilerOptions": {
    "composite": true,
    "declaration": true,
    "declarationMap": true,
    "outDir": "./dist"
  },
  "include": ["src/**/*"]
}
```

- Set `"moduleResolution": "bundler"` for Vite/webpack projects. Use `"moduleResolution": "node16"` for Node.js libraries.
- Use `"isolatedModules": true` for compatibility with esbuild and SWC, which transpile files independently.
- Use `"skipLibCheck": true` to speed up type checking by skipping `.d.ts` files from `node_modules`.

## Module Federation

- Use Module Federation (webpack 5) for micro-frontend architectures. Multiple independently deployed applications share components and libraries at runtime.

```js
// Remote app webpack.config.js
const { ModuleFederationPlugin } = require('webpack').container

module.exports = {
  plugins: [
    new ModuleFederationPlugin({
      name: 'remote_app',
      filename: 'remoteEntry.js',
      exposes: {
        './Button': './src/components/Button',
        './Header': './src/components/Header',
      },
      shared: {
        react: { singleton: true, requiredVersion: '^18.0.0' },
        'react-dom': { singleton: true, requiredVersion: '^18.0.0' },
      },
    }),
  ],
}

// Host app webpack.config.js
module.exports = {
  plugins: [
    new ModuleFederationPlugin({
      name: 'host_app',
      remotes: {
        remote_app: 'remote_app@http://localhost:3001/remoteEntry.js',
      },
      shared: {
        react: { singleton: true },
        'react-dom': { singleton: true },
      },
    }),
  ],
}
```

- Use `@module-federation/enhanced` for Vite and Rspack support beyond webpack.
- Handle versioning carefully. Mismatched shared dependency versions cause runtime errors.
- Implement a fallback strategy for when a remote module is unavailable.

## Monorepo Tooling

### Turborepo

```json
// turbo.json
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": ["**/.env.*local"],
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", ".next/**"],
      "env": ["NODE_ENV"]
    },
    "lint": {
      "dependsOn": ["^build"]
    },
    "test": {
      "dependsOn": ["build"],
      "inputs": ["src/**/*.tsx", "src/**/*.ts", "test/**/*.ts"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    }
  }
}
```

- Use Turborepo for simpler monorepos that need task pipelining and caching without a full framework.
- Enable remote caching with Vercel for shared build artifacts.

### Nx

```json
// nx.json
{
  "targetDefaults": {
    "build": {
      "dependsOn": ["^build"],
      "cache": true
    },
    "test": {
      "cache": true,
      "inputs": ["default", "^default"]
    }
  },
  "namedInputs": {
    "default": ["{projectRoot}/**/*"],
    "production": ["default", "!{projectRoot}/**/*.spec.ts"]
  }
}
```

- Use Nx for large monorepos with multiple applications and shared libraries.
- Define project boundaries with `@nx/enforce-module-boundaries` lint rule.
- Use Nx generators to scaffold consistent project structures.
- Enable distributed caching with Nx Cloud.

### pnpm Workspaces

```yaml
# pnpm-workspace.yaml
packages:
  - 'apps/*'
  - 'packages/*'
```

```json
// package.json (workspace root)
{
  "scripts": {
    "build": "turbo run build",
    "dev": "turbo run dev",
    "lint": "turbo run lint",
    "test": "turbo run test"
  }
}
```

## Package Managers

| Manager | Key Feature | Best For |
|---|---|---|
| npm | Built into Node.js, ubiquitous | Simple projects, CI environments |
| pnpm | Content-addressable store, strict node_modules | Monorepos, disk-efficient, strict dependency resolution |
| Yarn Berry (v4) | Plug'n'Play, zero-installs | Projects that want deterministic installs without node_modules |
| Bun | Runtime + package manager, fast | Speed-focused projects, Bun runtime users |

- **pnpm is preferred** for most projects: it prevents phantom dependencies (accessing packages not in your `package.json`), uses less disk space via hard links, and handles workspaces natively.

```bash
# pnpm install with frozen lockfile (CI)
pnpm install --frozen-lockfile

# Add dependency to specific workspace package
pnpm add react --filter @myorg/web-app

# Run script across all workspace packages
pnpm -r run build
```

## Bundle Analysis

```bash
# source-map-explorer: precise per-file size attribution
npx source-map-explorer dist/main.js

# bundlephobia: check package size before installing
# https://bundlephobia.com/package/lodash

# import cost: VS Code extension showing inline import sizes

# size-limit: budget enforcement in CI
npx size-limit
```

```json
// package.json - size-limit config
{
  "size-limit": [
    { "path": "dist/index.js", "limit": "50 KB" },
    { "path": "dist/vendor.js", "limit": "150 KB" }
  ]
}
```

- Set performance budgets in the bundler config. Fail the build if total JS exceeds 200KB gzipped.
- Track bundle size over time. Use `size-limit` or `bundlesize` in CI to compare against the baseline.
- Identify and eliminate duplicate dependencies with `npm ls <package>` or bundler deduplication plugins.

## CSS Tooling

- **PostCSS**: Use as a CSS transformer pipeline. Common plugins: `autoprefixer`, `postcss-preset-env`, `cssnano`.

```js
// postcss.config.js
module.exports = {
  plugins: {
    'postcss-preset-env': { stage: 2, features: { 'nesting-rules': true } },
    autoprefixer: {},
    cssnano: process.env.NODE_ENV === 'production' ? {} : false,
  },
}
```

- **Tailwind CSS build**: Tailwind uses PostCSS under the hood. Ensure content paths are configured for tree-shaking.
- **Vanilla Extract**: Compile-time CSS-in-JS. Requires Vite/webpack/esbuild plugin.

## Module Systems

### ESM vs CJS

| Feature | ESM | CJS |
|---|---|---|
| Syntax | `import`/`export` | `require()`/`module.exports` |
| Loading | Static, async | Dynamic, sync |
| Tree shaking | Yes | No |
| Top-level await | Yes | No |
| Browser support | Yes (native) | No (requires bundler) |

### Dual Package Exports

```json
// package.json for a library supporting both ESM and CJS
{
  "type": "module",
  "exports": {
    ".": {
      "import": "./dist/index.mjs",
      "require": "./dist/index.cjs",
      "types": "./dist/index.d.ts"
    },
    "./utils": {
      "import": "./dist/utils.mjs",
      "require": "./dist/utils.cjs",
      "types": "./dist/utils.d.ts"
    }
  },
  "main": "./dist/index.cjs",
  "module": "./dist/index.mjs",
  "types": "./dist/index.d.ts"
}
```

### Import Maps

```html
<!-- Browser-native import maps (no bundler needed) -->
<script type="importmap">
{
  "imports": {
    "react": "https://esm.sh/react@18",
    "react-dom/client": "https://esm.sh/react-dom@18/client"
  }
}
</script>
<script type="module">
  import React from 'react'
</script>
```

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Solution |
|---|---|---|
| No `.browserslistrc` | Shipping unnecessary polyfills or missing needed ones | Define target browsers explicitly |
| Babel + TypeScript both transpiling | Double processing, slow builds | Use SWC or esbuild for transpilation, `tsc` for type checking only |
| `any` in tsconfig paths | Bypasses type safety | Use strict mode, configure paths properly |
| No bundle size budget | Silent bloat over time | `size-limit` or `bundlesize` in CI |
| Single chunk output | Entire app loaded upfront | Route-based code splitting, manual chunks |
| Running Prettier via ESLint | Slow, conflicting rules | Run separately, use `eslint-config-prettier` |
| Lerna for task running | Deprecated task runner, no caching | Use Turborepo or Nx for task orchestration |
