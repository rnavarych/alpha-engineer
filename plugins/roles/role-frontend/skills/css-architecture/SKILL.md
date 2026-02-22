---
name: css-architecture
description: |
  CSS architecture expertise including BEM methodology, CSS Modules, Tailwind CSS,
  CSS-in-JS (styled-components, Emotion), design tokens, responsive design patterns,
  CSS Grid/Flexbox layouts, and container queries.
allowed-tools: Read, Grep, Glob, Bash
---

# CSS Architecture

## CSS Methodologies Comparison

| Methodology | Core Idea | Best For |
|---|---|---|
| BEM | Block-Element-Modifier naming | Large teams, component libraries |
| ITCSS | Inverted triangle specificity layering | Enterprise projects with many developers |
| CUBE CSS | Composition, Utility, Block, Exception | Design-system-driven projects |
| SMACSS | Categorized rules (base, layout, module, state, theme) | Legacy projects with mixed CSS |
| Atomic CSS | One property per class | Utility-first (Tailwind, UnoCSS) |

### BEM

- Use Block-Element-Modifier naming: `.card`, `.card__title`, `.card__title--highlighted`.
- Blocks are standalone entities (`.menu`, `.button`, `.form`). Elements are parts of a block (`.menu__item`). Modifiers describe variants (`.button--primary`, `.button--disabled`).
- Never nest BEM selectors deeper than one level. `.block__element` is correct; `.block__element__subelement` is wrong. Create a new block instead.
- Combine BEM with a utility-first approach for spacing and layout when pure BEM leads to excessive modifier classes.
- Keep specificity flat. BEM classes should be single-class selectors. Avoid `!important` and ID selectors.

### ITCSS (Inverted Triangle CSS)

- Layer CSS from generic to specific: Settings, Tools, Generic, Elements, Objects, Components, Utilities.
- Each layer has higher specificity than the previous, preventing specificity conflicts.
- Combine with BEM naming inside the Components layer.

### CUBE CSS

- **Composition**: Layout primitives (Stack, Sidebar, Cluster, Grid).
- **Utility**: Single-purpose classes (`.text-center`, `.gap-m`).
- **Block**: Component-specific styles.
- **Exception**: State-driven overrides using `data-*` attributes: `[data-state="active"]`.

## CSS Modules

- Use CSS Modules for component-scoped styles in React, Vue, and Angular projects. Class names are locally scoped by default.
- Import styles as objects: `import styles from './Button.module.css'` and apply as `className={styles.primary}`.

```tsx
// Button.module.css
.button { padding: 8px 16px; border-radius: 4px; }
.button_primary { background: var(--color-primary); color: white; }
.button_disabled { opacity: 0.5; pointer-events: none; }

// Button.tsx
import styles from './Button.module.css'

export function Button({ variant, disabled, children }) {
  return (
    <button className={`${styles.button} ${styles[`button_${variant}`]} ${disabled ? styles.button_disabled : ''}`}>
      {children}
    </button>
  )
}
```

- Use `composes` for extending styles from other modules or shared files. Avoid `@import` for composition.
- Combine with PostCSS for nesting, custom media queries, and autoprefixing.
- Name files with `.module.css` or `.module.scss` suffix for bundler recognition.

## CSS-in-JS

### styled-components

```tsx
import styled from 'styled-components'

const Button = styled.button<{ $variant: 'primary' | 'secondary' }>`
  padding: 8px 16px;
  border-radius: 4px;
  background: ${({ $variant, theme }) =>
    $variant === 'primary' ? theme.colors.primary : theme.colors.secondary};
  color: white;
  cursor: pointer;

  &:hover { opacity: 0.9; }
  &:disabled { opacity: 0.5; pointer-events: none; }
`

// Use ThemeProvider for theme injection
<ThemeProvider theme={theme}>
  <Button $variant="primary">Submit</Button>
</ThemeProvider>
```

- Use `shouldForwardProp` to prevent custom props from leaking to the DOM.
- Always define styled components outside the render function to avoid re-creating them on every render.

### Emotion

```tsx
/** @jsxImportSource @emotion/react */
import { css } from '@emotion/react'

const buttonStyles = css`
  padding: 8px 16px;
  border-radius: 4px;
`

// css prop approach
<button css={buttonStyles}>Click</button>

// styled approach (same API as styled-components)
import styled from '@emotion/styled'
const Card = styled.div`
  padding: 16px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
`
```

### Zero-Runtime CSS-in-JS

- **Vanilla Extract**: Type-safe styles compiled at build time. No runtime cost.

```ts
// button.css.ts
import { style, styleVariants } from '@vanilla-extract/css'

export const base = style({
  padding: '8px 16px',
  borderRadius: '4px',
})

export const variants = styleVariants({
  primary: { background: 'blue', color: 'white' },
  secondary: { background: 'gray', color: 'black' },
})
```

- **Panda CSS**: Design-token-driven, zero-runtime CSS-in-JS with type-safe utility patterns.

```tsx
import { css } from '../styled-system/css'

<button className={css({ padding: '8px 16px', bg: 'blue.500', color: 'white' })}>
  Submit
</button>
```

- **StyleX** (Meta): Atomic CSS-in-JS with compile-time extraction. Co-locates styles with components, outputs atomic classes.
- **Linaria**: Zero-runtime tagged template literals, similar API to styled-components but extracts to static CSS at build time.
- Avoid generating styles at runtime in performance-critical paths. Choose zero-runtime alternatives for large-scale applications.

## Tailwind CSS

- Use Tailwind for rapid UI development with utility classes. Configure `tailwind.config.js` with project-specific design tokens.

```js
// tailwind.config.js
export default {
  content: ['./src/**/*.{js,ts,jsx,tsx,vue}'],
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#eff6ff',
          500: '#3b82f6',
          900: '#1e3a5f',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      spacing: {
        '18': '4.5rem',
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
}
```

- Extract repeated patterns into components, not `@apply` rules. Overusing `@apply` defeats the purpose of utility-first CSS.
- Use Tailwind's responsive prefixes (`sm:`, `md:`, `lg:`, `xl:`, `2xl:`) mobile-first.
- Use the `group` and `peer` modifiers for styling based on parent or sibling state:

```html
<div class="group rounded-lg border p-4 hover:border-blue-500">
  <h3 class="text-gray-700 group-hover:text-blue-500">Title</h3>
</div>

<input class="peer" type="checkbox" id="toggle" />
<label class="peer-checked:text-blue-500" for="toggle">Option</label>
```

- Configure the content paths to ensure tree-shaking removes unused utilities.
- Use `@layer base`, `@layer components`, `@layer utilities` for organizing custom CSS alongside Tailwind.
- **Dark mode**: Use `dark:` prefix with `darkMode: 'class'` (manual toggle) or `darkMode: 'media'` (system preference).

```html
<div class="bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100">
  <button class="bg-blue-500 dark:bg-blue-400 hover:bg-blue-600 dark:hover:bg-blue-300">
    Action
  </button>
</div>
```

- **UnoCSS**: Alternative utility-first engine. Fully configurable, preset-based. Compatible with Tailwind classes via `@unocss/preset-wind`.

## Design Tokens and CSS Custom Properties

- Define a single source of truth for colors, typography, spacing, shadows, border radii, and breakpoints.
- Implement tokens as CSS custom properties for runtime theming.

```css
/* tokens.css */
:root {
  /* Color tokens */
  --color-primary-50: #eff6ff;
  --color-primary-500: #3b82f6;
  --color-primary-900: #1e3a5f;

  /* Semantic tokens */
  --color-bg-primary: var(--color-primary-50);
  --color-text-primary: var(--color-primary-900);
  --color-interactive: var(--color-primary-500);

  /* Spacing scale */
  --space-xs: 0.25rem;
  --space-sm: 0.5rem;
  --space-md: 1rem;
  --space-lg: 1.5rem;
  --space-xl: 2rem;

  /* Typography */
  --font-body: 'Inter', system-ui, sans-serif;
  --font-mono: 'JetBrains Mono', monospace;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;

  /* Shadows */
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.1);

  /* Radii */
  --radius-sm: 0.25rem;
  --radius-md: 0.5rem;
  --radius-lg: 1rem;
}
```

- Structure tokens in tiers: **global tokens** (raw values), **semantic tokens** (purpose-based aliases), and **component tokens** (component-specific overrides).
- Use tokens for dark mode: swap semantic token values at the theme level.

```css
[data-theme="dark"] {
  --color-bg-primary: var(--color-primary-900);
  --color-text-primary: var(--color-primary-50);
}
```

- **Responsive tokens**: Adjust tokens at breakpoints for fluid design.

```css
:root {
  --space-section: 2rem;
}
@media (min-width: 768px) {
  :root { --space-section: 4rem; }
}
@media (min-width: 1280px) {
  :root { --space-section: 6rem; }
}
```

- Share tokens across platforms using tools like Style Dictionary or design token JSON files.

## Modern CSS Features

### Container Queries

```css
.card-container {
  container-type: inline-size;
  container-name: card;
}

@container card (min-width: 400px) {
  .card { display: grid; grid-template-columns: 200px 1fr; }
}

@container card (max-width: 399px) {
  .card { display: flex; flex-direction: column; }
}
```

- Container queries enable truly reusable components that adapt to their container, not the viewport.
- Use container query units (`cqw`, `cqh`, `cqi`, `cqb`) for sizing relative to the container.

### CSS Nesting (native)

```css
.card {
  padding: 1rem;

  & .title {
    font-size: 1.25rem;
  }

  &:hover {
    box-shadow: var(--shadow-md);
  }

  @media (min-width: 768px) {
    padding: 2rem;
  }
}
```

### :has() Selector

```css
/* Style a card that contains an image */
.card:has(img) {
  padding: 0;
}

/* Style a form group with an invalid input */
.form-group:has(:invalid) {
  border-color: red;
}

/* Style a label when its associated input is focused */
label:has(+ input:focus) {
  color: var(--color-primary-500);
}
```

### @layer (Cascade Layers)

```css
@layer reset, base, components, utilities;

@layer reset {
  *, *::before, *::after { box-sizing: border-box; margin: 0; }
}

@layer base {
  body { font-family: var(--font-body); line-height: 1.6; }
}

@layer components {
  .button { padding: 8px 16px; border-radius: var(--radius-md); }
}

@layer utilities {
  .sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0,0,0,0); }
}
```

- Layers defined earlier have lower priority regardless of specificity. This eliminates specificity wars.

### @scope

```css
@scope (.card) to (.card__footer) {
  p { margin-bottom: 1rem; }    /* only applies inside .card but not in .card__footer */
}
```

### Subgrid

```css
.grid-parent {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1rem;
}

.grid-child {
  display: grid;
  grid-template-columns: subgrid; /* inherits parent's column tracks */
  grid-column: span 3;
}
```

### Modern Color Functions

```css
:root {
  --brand: oklch(60% 0.15 250);
  --brand-light: oklch(from var(--brand) calc(l + 0.2) c h);
  --brand-dark: oklch(from var(--brand) calc(l - 0.2) c h);
  --overlay: color-mix(in oklch, var(--brand), transparent 50%);
}
```

## Responsive Design

- Use mobile-first CSS. Write base styles for small screens, then add complexity with `min-width` media queries.
- **Fluid typography** with `clamp()`:

```css
h1 { font-size: clamp(1.75rem, 1rem + 2vw, 3rem); }
h2 { font-size: clamp(1.25rem, 0.75rem + 1.5vw, 2.25rem); }
p  { font-size: clamp(1rem, 0.875rem + 0.25vw, 1.125rem); }
```

- **Container queries vs media queries**: Use media queries for page-level layout. Use container queries for component-level adaptation.
- **Responsive images**: Use `srcset` and `sizes` for resolution switching. Use `<picture>` for art direction.

```html
<picture>
  <source media="(min-width: 1024px)" srcset="hero-wide.avif" type="image/avif" />
  <source media="(min-width: 1024px)" srcset="hero-wide.webp" type="image/webp" />
  <source srcset="hero-narrow.avif" type="image/avif" />
  <img src="hero-narrow.jpg" alt="Hero banner" loading="eager" fetchpriority="high" />
</picture>
```

- Set breakpoints based on content, not devices. Common breakpoints: 640px, 768px, 1024px, 1280px, 1536px.
- Test at every 100px increment from 320px to 1920px, not just at breakpoint boundaries.

## CSS Grid and Flexbox

- **Flexbox**: Use for one-dimensional layouts (rows or columns). Ideal for navigation bars, card rows, form layouts, and centering content.
- **Grid**: Use for two-dimensional layouts. Ideal for page layouts, dashboards, and any design with both row and column alignment.

```css
/* Responsive grid without media queries */
.auto-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(min(250px, 100%), 1fr));
  gap: 1rem;
}

/* Named grid areas */
.page-layout {
  display: grid;
  grid-template-areas:
    "header header"
    "sidebar main"
    "footer footer";
  grid-template-columns: 250px 1fr;
  grid-template-rows: auto 1fr auto;
  min-height: 100dvh;
}
```

- Use `gap` (works in both Grid and Flexbox) instead of margin for spacing between items.
- Use `place-items`, `place-content`, and `place-self` shorthands for alignment.

## CSS Performance

- **Critical CSS extraction**: Inline above-the-fold CSS in `<head>` to avoid render-blocking. Use tools like `critters` (Vite/webpack plugin) for automatic extraction.
- **content-visibility: auto**: Skip rendering off-screen content until it is near the viewport.

```css
.card {
  content-visibility: auto;
  contain-intrinsic-size: auto 300px; /* estimated height for layout */
}
```

- **will-change**: Hint browser to prepare for animations. Only apply immediately before animation, remove after.

```css
.animated-element:hover { will-change: transform; }
.animated-element:active { transform: scale(0.95); }
```

- **Paint containment**: Use `contain: layout paint` to isolate re-paint boundaries.
- Avoid universal selectors in expensive positions: `* { box-shadow: ... }` triggers paint on every element.
- Minimize use of complex selectors (`:nth-child(odd)`, `:has()` on large DOMs) in performance-critical loops.

## Animation

- **CSS transitions**: Use for simple state changes (hover, focus, active). Single property changes with predictable timing.
- **CSS animations**: Use for multi-step animations with `@keyframes`. Good for loading spinners, entrance effects.
- **View Transitions API**: Animate between page/state changes with minimal code.

```css
::view-transition-old(root) { animation: fade-out 0.2s ease-out; }
::view-transition-new(root) { animation: fade-in 0.2s ease-in; }
```

- **Scroll-driven animations**: Animate elements based on scroll position (CSS-only, no JS).

```css
@keyframes reveal {
  from { opacity: 0; transform: translateY(20px); }
  to   { opacity: 1; transform: translateY(0); }
}

.reveal-on-scroll {
  animation: reveal linear both;
  animation-timeline: view();
  animation-range: entry 0% entry 100%;
}
```

- **GPU-accelerated properties**: Animate only `transform` and `opacity` for 60fps performance. Avoid animating `width`, `height`, `top`, `left`, `margin`, `padding`.
- Respect `prefers-reduced-motion`:

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

## Dark Mode Implementation

```css
/* System preference detection */
@media (prefers-color-scheme: dark) {
  :root {
    --color-bg: #0f172a;
    --color-text: #f1f5f9;
  }
}

/* Manual toggle with data attribute */
[data-theme="dark"] {
  --color-bg: #0f172a;
  --color-text: #f1f5f9;
}

/* Combined: respect system, allow override */
:root {
  color-scheme: light dark;
}
```

```js
// Toggle script
const toggle = document.querySelector('#theme-toggle')
const prefersDark = window.matchMedia('(prefers-color-scheme: dark)')

function setTheme(theme) {
  document.documentElement.dataset.theme = theme
  localStorage.setItem('theme', theme)
}

// Initialize from saved preference or system
const saved = localStorage.getItem('theme')
if (saved) setTheme(saved)
else setTheme(prefersDark.matches ? 'dark' : 'light')
```

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Solution |
|---|---|---|
| `!important` overuse | Breaks cascade, hard to override | Use cascade layers, specificity management |
| Deep nesting (4+ levels) | High specificity, fragile selectors | Flatten with BEM or utility classes |
| Magic numbers | Unmaintainable values | Use design tokens / CSS custom properties |
| Styling by element type | Fragile (`.sidebar p`) | Use class-based selectors |
| Overusing `@apply` in Tailwind | Defeats utility-first purpose | Extract components instead |
| Pixel-only responsive design | Does not adapt to user preferences | Use rem/em, clamp(), fluid typography |
| Animating layout properties | Janky 60fps animations | Animate transform and opacity only |
| ID selectors for styling | Specificity too high | Use classes for styling, IDs for JS/anchors |
