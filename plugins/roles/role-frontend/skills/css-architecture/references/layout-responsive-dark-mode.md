# Layout, Responsive Design, and Dark Mode

## When to load
Load when building Grid/Flexbox layouts, implementing responsive design, adding dark mode support, or optimizing CSS performance with will-change and paint containment.

## CSS Grid and Flexbox

- **Flexbox**: one-dimensional (rows or columns). Navigation bars, card rows, form layouts, centering.
- **Grid**: two-dimensional. Page layouts, dashboards, row and column alignment.

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

/* Use gap instead of margin for spacing between items */
/* Use place-items, place-content, place-self shorthands for alignment */
```

## Responsive Design

- Use **mobile-first CSS**: base styles for small screens, add complexity with `min-width` media queries.
- **Container queries vs media queries**: media queries for page-level layout; container queries for component-level.
- Set breakpoints based on content, not devices. Test at every 100px from 320px to 1920px.

```html
<!-- Responsive images -->
<picture>
  <source media="(min-width: 1024px)" srcset="hero-wide.avif" type="image/avif" />
  <source media="(min-width: 1024px)" srcset="hero-wide.webp" type="image/webp" />
  <source srcset="hero-narrow.avif" type="image/avif" />
  <img src="hero-narrow.jpg" alt="Hero banner" loading="eager" fetchpriority="high" />
</picture>
```

## Dark Mode

```css
/* System preference detection */
@media (prefers-color-scheme: dark) {
  :root { --color-bg: #0f172a; --color-text: #f1f5f9; }
}

/* Manual toggle with data attribute */
[data-theme="dark"] { --color-bg: #0f172a; --color-text: #f1f5f9; }

/* Combined: respect system, allow override */
:root { color-scheme: light dark; }
```

```js
const prefersDark = window.matchMedia('(prefers-color-scheme: dark)')

function setTheme(theme) {
  document.documentElement.dataset.theme = theme
  localStorage.setItem('theme', theme)
}

const saved = localStorage.getItem('theme')
if (saved) setTheme(saved)
else setTheme(prefersDark.matches ? 'dark' : 'light')
```

## CSS Performance

```css
/* content-visibility: skip rendering off-screen content */
.card { content-visibility: auto; contain-intrinsic-size: auto 300px; }

/* will-change: hint browser to prepare for animation */
.animated-element:hover { will-change: transform; }
.animated-element:active { transform: scale(0.95); }

/* Paint containment: isolate re-paint boundaries */
.isolated-section { contain: layout paint; }
```

- Critical CSS extraction: inline above-the-fold CSS with `critters` (Vite/webpack plugin).
- Avoid universal selectors in expensive positions: `* { box-shadow: ... }` triggers paint on every element.

## Animation

```css
/* GPU-accelerated: animate only transform and opacity */
.card:hover { transform: translateY(-4px) scale(1.02); opacity: 0.95; }

/* View Transitions API */
::view-transition-old(root) { animation: fade-out 0.2s ease-out; }
::view-transition-new(root) { animation: fade-in 0.2s ease-in; }

/* prefers-reduced-motion */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { animation-duration: 0.01ms !important; transition-duration: 0.01ms !important; }
}
```

## Anti-Patterns

| Anti-Pattern | Problem | Solution |
|---|---|---|
| `!important` overuse | Breaks cascade, hard to override | Use cascade layers, specificity management |
| Deep nesting (4+ levels) | High specificity, fragile selectors | Flatten with BEM or utility classes |
| Magic numbers | Unmaintainable values | Use design tokens / CSS custom properties |
| Styling by element type (`.sidebar p`) | Fragile | Use class-based selectors |
| Overusing `@apply` in Tailwind | Defeats utility-first purpose | Extract components instead |
| Pixel-only responsive design | Does not adapt to user preferences | Use rem/em, clamp(), fluid typography |
| Animating layout properties | Janky animations | Animate transform and opacity only |
| ID selectors for styling | Specificity too high | Use classes for styling, IDs for JS/anchors |
