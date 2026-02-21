---
name: css-architecture
description: |
  CSS architecture expertise including BEM methodology, CSS Modules, Tailwind CSS,
  CSS-in-JS (styled-components, Emotion), design tokens, responsive design patterns,
  CSS Grid/Flexbox layouts, and container queries.
allowed-tools: Read, Grep, Glob, Bash
---

# CSS Architecture

## BEM Methodology

- Use Block-Element-Modifier naming: `.card`, `.card__title`, `.card__title--highlighted`.
- Blocks are standalone entities (`.menu`, `.button`, `.form`). Elements are parts of a block (`.menu__item`). Modifiers describe variants (`.button--primary`, `.button--disabled`).
- Never nest BEM selectors deeper than one level. `.block__element` is correct; `.block__element__subelement` is wrong. Create a new block instead.
- Combine BEM with a utility-first approach for spacing and layout when pure BEM leads to excessive modifier classes.
- Keep specificity flat. BEM classes should be single-class selectors. Avoid `!important` and ID selectors.

## CSS Modules

- Use CSS Modules for component-scoped styles in React, Vue, and Angular projects. Class names are locally scoped by default.
- Import styles as objects: `import styles from './Button.module.css'` and apply as `className={styles.primary}`.
- Use `composes` for extending styles from other modules or shared files. Avoid `@import` for composition.
- Combine with PostCSS for nesting, custom media queries, and autoprefixing.
- Name files with `.module.css` or `.module.scss` suffix for bundler recognition.

## Tailwind CSS

- Use Tailwind for rapid UI development with utility classes. Configure `tailwind.config.js` with project-specific design tokens (colors, spacing, fonts, breakpoints).
- Extract repeated patterns into components, not `@apply` rules. Overusing `@apply` defeats the purpose of utility-first CSS.
- Use Tailwind's responsive prefixes (`sm:`, `md:`, `lg:`, `xl:`, `2xl:`) mobile-first. Start with base styles, then add breakpoint overrides.
- Use the `group` and `peer` modifiers for styling based on parent or sibling state.
- Configure the content paths in `tailwind.config.js` to ensure tree-shaking removes unused utilities.
- Use `@layer base`, `@layer components`, `@layer utilities` for organizing custom CSS alongside Tailwind.
- Extend the theme for project-specific tokens: `theme.extend.colors`, `theme.extend.spacing`, `theme.extend.fontFamily`.

## CSS-in-JS

- **styled-components**: Use for React projects that need dynamic, prop-based styling. Define styled components with template literals. Use `ThemeProvider` for theme injection.
- **Emotion**: Use `@emotion/styled` for the styled API or `@emotion/react` with the `css` prop for inline-style ergonomics with full CSS support. Emotion supports SSR out of the box.
- Avoid generating styles at runtime in performance-critical paths. Consider zero-runtime alternatives (Vanilla Extract, Linaria, Panda CSS) for large-scale applications.
- Use `shouldForwardProp` to prevent custom props from leaking to the DOM.
- Always define styled components outside the render function to avoid re-creating them on every render.

## Design Tokens

- Define a single source of truth for colors, typography, spacing, shadows, border radii, and breakpoints.
- Implement tokens as CSS custom properties (variables) for runtime theming: `--color-primary: #2563eb;`.
- Structure tokens in tiers: global tokens (raw values), semantic tokens (purpose-based aliases), and component tokens (component-specific overrides).
- Use tokens for dark mode: swap semantic token values at the `:root[data-theme="dark"]` or `@media (prefers-color-scheme: dark)` level.
- Share tokens across platforms using tools like Style Dictionary or design token JSON files.

## Responsive Design

- Use mobile-first CSS. Write base styles for small screens, then add complexity with `min-width` media queries.
- Set breakpoints based on content, not devices. Common breakpoints: 640px, 768px, 1024px, 1280px, 1536px.
- Use `clamp()` for fluid typography: `font-size: clamp(1rem, 0.5rem + 1.5vw, 1.5rem)`.
- Use percentage or viewport-relative widths for layout. Avoid fixed pixel widths for containers.
- Test at every 100px increment from 320px to 1920px, not just at breakpoint boundaries.

## CSS Grid and Flexbox

- **Flexbox**: Use for one-dimensional layouts (rows or columns). Ideal for navigation bars, card rows, form layouts, and centering content.
- **Grid**: Use for two-dimensional layouts. Ideal for page layouts, dashboards, and any design with both row and column alignment.
- Use `grid-template-areas` for readable, named layout regions. Use `grid-template-columns: repeat(auto-fill, minmax(250px, 1fr))` for responsive grids without media queries.
- Use `gap` (works in both Grid and Flexbox) instead of margin for spacing between items.
- Combine Grid for the page shell and Flexbox for component internals. They complement each other.
- Use `place-items`, `place-content`, and `place-self` shorthands for alignment in Grid layouts.

## Container Queries

- Use container queries (`@container`) for component-level responsive design that adapts to the component's container width, not the viewport.
- Define containment: `container-type: inline-size` on the parent element. Name containers with `container-name` for specificity.
- Container queries enable truly reusable components that adapt their layout whether placed in a sidebar, main content area, or modal.
- Use container query units (`cqw`, `cqh`, `cqi`, `cqb`) for sizing relative to the container.
- Combine container queries with CSS Grid `auto-fill`/`auto-fit` for fully adaptive component layouts that require zero JavaScript.
