---
name: role-frontend:css-architecture
description: |
  CSS architecture expertise including BEM methodology, CSS Modules, Tailwind CSS,
  CSS-in-JS (styled-components, Emotion), design tokens, responsive design patterns,
  CSS Grid/Flexbox layouts, and container queries.
allowed-tools: Read, Grep, Glob, Bash
---

# CSS Architecture

## When to use
- Choosing a CSS methodology (BEM, ITCSS, CUBE CSS) for a new project or team
- Setting up CSS Modules, styled-components, Vanilla Extract, or Panda CSS
- Configuring Tailwind with custom design tokens
- Implementing a design token system with CSS custom properties
- Using modern CSS (container queries, :has(), @layer, native nesting, subgrid)
- Building responsive layouts with Grid/Flexbox
- Adding dark mode support or scroll-driven animations
- Diagnosing specificity wars, paint performance, or layout thrashing

## Core principles
1. **Native HTML semantics before CSS tricks** — right element reduces styling complexity
2. **Flat specificity** — BEM single-class selectors, `@layer` for ordering, never `!important`
3. **Design tokens as single source of truth** — global → semantic → component tiers
4. **Zero-runtime CSS-in-JS for scale** — Vanilla Extract or Panda CSS over styled-components in large apps
5. **Container queries for components, media queries for pages** — components should not know viewport size

## Reference Files

- `references/methodologies-modules-css-in-js.md` — BEM/ITCSS/CUBE CSS comparison, CSS Modules with composes, styled-components with ThemeProvider, Emotion, Vanilla Extract, Panda CSS, StyleX, Linaria
- `references/tailwind-tokens-modern-css.md` — Tailwind config, group/peer modifiers, dark mode, UnoCSS; design token three-tier system, CSS custom properties, responsive tokens; container queries, native nesting, :has(), @layer, subgrid, oklch color, fluid typography, scroll-driven animations, content-visibility
- `references/layout-responsive-dark-mode.md` — CSS Grid named areas, auto-fill grid, Flexbox guidance, mobile-first responsive design, responsive images, dark mode system/manual toggle, CSS performance (will-change, paint containment, critical CSS), animation GPU properties, anti-patterns table
