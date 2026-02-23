# Webpack 5, Turbopack, and Module Federation

## When to load
Load when working on webpack 5 projects requiring Module Federation, persistent caching, or advanced code splitting — or configuring Turbopack for Next.js development.

## Webpack 5

### Persistent Caching

```js
module.exports = {
  cache: {
    type: 'filesystem',
    buildDependencies: { config: [__filename] },
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
      vendor: { test: /[\\/]node_modules[\\/]/, name: 'vendors', chunks: 'all', priority: 10 },
      common: { minChunks: 2, priority: 5, reuseExistingChunk: true },
    },
  },
},
```

### Build Analysis

```bash
npx webpack --profile --json > stats.json
npx webpack-bundle-analyzer stats.json
```

- Use webpack 5 for projects that require Module Federation, advanced loader configurations, or legacy plugin support.
- Use SWC-loader or esbuild-loader instead of babel-loader for faster transpilation.

## Turbopack

| Feature | Vite | Turbopack |
|---|---|---|
| Dev server | Native ESM, fast startup | Bundled, incremental compilation |
| Framework support | React, Vue, Svelte, Angular, Solid | Next.js (primary) |
| Production build | Rollup-based | Webpack (in Next.js) |
| Plugin ecosystem | Rich (Rollup-compatible) | Limited (Next.js plugins) |
| Language | JavaScript/TypeScript | Rust |

- Use with Next.js (`next dev --turbo`). Only recompiles changed modules and their dependents.
- Supports RSC, CSS Modules, PostCSS, TypeScript out of the box. Zero configuration.
- Production builds still use webpack in Next.js. Turbopack production is maturing.

## Module Federation

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
      remotes: { remote_app: 'remote_app@http://localhost:3001/remoteEntry.js' },
      shared: { react: { singleton: true }, 'react-dom': { singleton: true } },
    }),
  ],
}
```

- Use `@module-federation/enhanced` for Vite and Rspack support beyond webpack.
- Handle versioning carefully — mismatched shared dependency versions cause runtime errors.
- Implement a fallback strategy for when a remote module is unavailable.
