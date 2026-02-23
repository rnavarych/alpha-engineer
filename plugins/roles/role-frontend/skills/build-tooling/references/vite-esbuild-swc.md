# Vite, esbuild, and SWC

## When to load
Load when configuring Vite for a new project, setting up esbuild for library/CLI builds, or replacing Babel with SWC for faster transpilation.

## Vite Configuration

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
      alias: { '@': '/src', '@components': '/src/components', '@lib': '/src/lib' },
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
  AutoImport({ imports: ['react', 'react-router-dom'], dts: 'src/auto-imports.d.ts' }),
  VitePWA({ registerType: 'autoUpdate', workbox: { globPatterns: ['**/*.{js,css,html,ico,png,svg}'] } }),
  tsconfigPaths(),
]
```

### HMR and Environment Variables

```ts
// Preserve state across HMR updates
if (import.meta.hot) {
  import.meta.hot.accept()
  import.meta.hot.dispose(() => { /* cleanup */ })
}
```

```bash
# .env files (VITE_ prefix exposes to client)
VITE_API_URL=https://api.example.com
DATABASE_URL=postgres://...  # server-side only, never exposed
```

### Library Mode

```ts
export default defineConfig({
  build: {
    lib: { entry: 'src/index.ts', name: 'MyLib', formats: ['es', 'cjs'], fileName: (fmt) => `my-lib.${fmt}.js` },
    rollupOptions: { external: ['react', 'react-dom'] },
  },
})
```

- Vite supports SSR with `vite.ssrLoadModule()`. Frameworks like Nuxt 3, SvelteKit, and Astro use this internally.

## esbuild

```ts
import * as esbuild from 'esbuild'

await esbuild.build({
  entryPoints: ['src/index.ts'],
  bundle: true,
  outfile: 'dist/index.js',
  platform: 'node',
  target: 'node18',
  format: 'esm',
  minify: true,
  sourcemap: true,
  external: ['express'],
  define: { 'process.env.NODE_ENV': '"production"' },
})
```

- 10-100x faster than webpack for raw bundling.
- Limitations: no HMR, limited plugin ecosystem, no CSS Modules. Use Vite for full app builds.
- Use for TypeScript type-stripping in CI scripts and serverless functions.

## SWC

```json
{
  "jsc": {
    "parser": { "syntax": "typescript", "tsx": true, "decorators": true },
    "transform": { "react": { "runtime": "automatic" } },
    "target": "es2022"
  },
  "module": { "type": "es6" }
}
```

```json
// jest.config.json — faster test execution
{
  "transform": {
    "^.+\\.(t|j)sx?$": ["@swc/jest", {
      "jsc": { "transform": { "react": { "runtime": "automatic" } } }
    }]
  }
}
```

- Next.js uses SWC by default. 20-70x faster than Babel for transpilation.
- Use `@swc/jest` as a Jest transformer. Use `swc-loader` in webpack as a faster alternative to `babel-loader`.
