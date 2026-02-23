# Tailwind, Design Tokens, and Modern CSS

## When to load
Load when configuring Tailwind CSS, setting up design tokens with CSS custom properties, or using modern CSS features (container queries, nesting, :has(), @layer, subgrid, color functions).

## Tailwind CSS

```js
// tailwind.config.js
export default {
  content: ['./src/**/*.{js,ts,jsx,tsx,vue}'],
  theme: {
    extend: {
      colors: { brand: { 50: '#eff6ff', 500: '#3b82f6', 900: '#1e3a5f' } },
      fontFamily: { sans: ['Inter', 'system-ui', 'sans-serif'] },
      spacing: { '18': '4.5rem' },
    },
  },
  plugins: [require('@tailwindcss/forms'), require('@tailwindcss/typography')],
}
```

- Extract repeated patterns into components, not `@apply` rules — overusing `@apply` defeats utility-first CSS.
- Use responsive prefixes (`sm:`, `md:`, `lg:`) mobile-first.
- Use `group` and `peer` modifiers for parent/sibling state:

```html
<div class="group rounded-lg border p-4 hover:border-blue-500">
  <h3 class="text-gray-700 group-hover:text-blue-500">Title</h3>
</div>
<input class="peer" type="checkbox" />
<label class="peer-checked:text-blue-500">Option</label>
```

- **Dark mode**: `dark:` prefix with `darkMode: 'class'` (manual toggle) or `darkMode: 'media'` (system).
- **UnoCSS**: Alternative utility-first engine, preset-based, compatible with Tailwind via `@unocss/preset-wind`.

## Design Tokens

```css
:root {
  /* Global tokens */
  --color-primary-50: #eff6ff;
  --color-primary-500: #3b82f6;
  --color-primary-900: #1e3a5f;

  /* Semantic tokens */
  --color-bg-primary: var(--color-primary-50);
  --color-text-primary: var(--color-primary-900);
  --color-interactive: var(--color-primary-500);

  /* Spacing scale */
  --space-xs: 0.25rem; --space-sm: 0.5rem;
  --space-md: 1rem; --space-lg: 1.5rem; --space-xl: 2rem;

  /* Typography */
  --font-body: 'Inter', system-ui, sans-serif;
  --text-sm: 0.875rem; --text-base: 1rem; --text-lg: 1.125rem;

  /* Shadows and Radii */
  --shadow-sm: 0 1px 2px rgba(0,0,0,0.05);
  --shadow-md: 0 4px 6px rgba(0,0,0,0.1);
  --radius-sm: 0.25rem; --radius-md: 0.5rem; --radius-lg: 1rem;
}

/* Dark mode token swap */
[data-theme="dark"] {
  --color-bg-primary: var(--color-primary-900);
  --color-text-primary: var(--color-primary-50);
}

/* Responsive tokens */
@media (min-width: 768px) { :root { --space-section: 4rem; } }
```

- Three token tiers: **global** (raw values) → **semantic** (purpose aliases) → **component** (overrides).
- Share across platforms with Style Dictionary or design token JSON files.

## Modern CSS Features

```css
/* Container Queries */
.card-container { container-type: inline-size; container-name: card; }
@container card (min-width: 400px) { .card { display: grid; grid-template-columns: 200px 1fr; } }

/* Native Nesting */
.card {
  padding: 1rem;
  & .title { font-size: 1.25rem; }
  &:hover { box-shadow: var(--shadow-md); }
  @media (min-width: 768px) { padding: 2rem; }
}

/* :has() Selector */
.card:has(img) { padding: 0; }
.form-group:has(:invalid) { border-color: red; }

/* @layer — Cascade Layers */
@layer reset, base, components, utilities;
@layer reset { *, *::before, *::after { box-sizing: border-box; margin: 0; } }
@layer utilities { .sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; } }

/* Subgrid */
.grid-child { display: grid; grid-template-columns: subgrid; grid-column: span 3; }

/* Modern Color */
:root {
  --brand: oklch(60% 0.15 250);
  --brand-light: oklch(from var(--brand) calc(l + 0.2) c h);
  --overlay: color-mix(in oklch, var(--brand), transparent 50%);
}

/* Fluid Typography */
h1 { font-size: clamp(1.75rem, 1rem + 2vw, 3rem); }
p  { font-size: clamp(1rem, 0.875rem + 0.25vw, 1.125rem); }

/* Scroll-driven Animations */
@keyframes reveal { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
.reveal-on-scroll {
  animation: reveal linear both;
  animation-timeline: view();
  animation-range: entry 0% entry 100%;
}

/* content-visibility for performance */
.card { content-visibility: auto; contain-intrinsic-size: auto 300px; }
```

- Layers defined earlier have lower priority regardless of specificity — eliminates specificity wars.
- Container queries enable reusable components that adapt to their container, not the viewport.
