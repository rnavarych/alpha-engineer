# Linting, Formatting, and TypeScript Config

## When to load
Load when setting up Biome, ESLint flat config, Prettier, pre-commit hooks, or TypeScript strict mode configuration for a project.

## Biome (Replaces ESLint + Prettier)

```json
{
  "$schema": "https://biomejs.dev/schemas/1.9.0/schema.json",
  "organizeImports": { "enabled": true },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true,
      "complexity": { "noForEach": "warn" },
      "suspicious": { "noExplicitAny": "error" }
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
biome check --write .  # format + lint with fixes
biome ci .             # CI check (no writes)
```

- Run `biome migrate` to convert existing ESLint/Prettier configs. Not all ESLint rules have Biome equivalents.
- Single tool, fast (Rust), consistent formatting + linting. Smaller plugin ecosystem than ESLint.

## ESLint 9+ Flat Config

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
    plugins: { 'react-hooks': reactHooks, 'jsx-a11y': jsxA11y, 'import': importPlugin },
    rules: {
      'react-hooks/rules-of-hooks': 'error',
      'react-hooks/exhaustive-deps': 'warn',
      'jsx-a11y/alt-text': 'error',
      'import/order': ['error', {
        groups: ['builtin', 'external', 'internal', 'parent', 'sibling'],
        'newlines-between': 'always',
        alphabetize: { order: 'asc' },
      }],
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_', varsIgnorePattern: '^_' }],
    },
    languageOptions: { parserOptions: { project: './tsconfig.json' } },
  },
  { ignores: ['dist/', 'node_modules/', '*.config.js'] },
)
```

## Prettier + Pre-commit Hooks

```json
{ "singleQuote": true, "trailingComma": "all", "printWidth": 100, "semi": false, "tabWidth": 2, "arrowParens": "always", "endOfLine": "lf" }
```

```json
// package.json lint-staged
{
  "lint-staged": {
    "*.{ts,tsx,js,jsx}": ["eslint --fix", "prettier --write"],
    "*.{css,scss,md,json}": ["prettier --write"]
  }
}
```

```bash
npx husky init
echo "npx lint-staged" > .husky/pre-commit
```

## TypeScript Strict Mode

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "forceConsistentCasingInFileNames": true,
    "isolatedModules": true,
    "moduleResolution": "bundler",
    "module": "ESNext",
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "jsx": "react-jsx",
    "skipLibCheck": true,
    "paths": { "@/*": ["./src/*"], "@components/*": ["./src/components/*"] }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### Project References (Monorepo)

```json
// tsconfig.json (root)
{ "references": [{ "path": "./packages/shared" }, { "path": "./apps/web" }], "files": [] }

// packages/shared/tsconfig.json
{ "compilerOptions": { "composite": true, "declaration": true, "declarationMap": true, "outDir": "./dist" } }
```

- Use `"moduleResolution": "bundler"` for Vite/webpack projects; `"node16"` for Node.js libraries.
- Use `"isolatedModules": true` for compatibility with esbuild and SWC.
