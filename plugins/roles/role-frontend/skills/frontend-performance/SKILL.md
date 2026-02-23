---
name: frontend-performance
description: |
  Frontend performance expertise including Core Web Vitals (LCP, INP, CLS),
  code splitting, tree shaking, image optimization (WebP, AVIF, lazy loading),
  font loading strategies, service workers, and bundle analysis with
  webpack-bundle-analyzer.
allowed-tools: Read, Grep, Glob, Bash
---

# Frontend Performance

## When to use
- Diagnosing or improving Core Web Vitals scores (LCP, INP, CLS)
- Reducing JavaScript bundle size or fixing slow load times
- Optimizing images, fonts, or network resource loading
- Choosing between SSR, SSG, RSC, Islands rendering strategies
- Implementing animations without janking the main thread
- Setting up performance monitoring and budgets in CI

## Core principles
1. **Measure before optimizing** — profile first, then fix the specific bottleneck
2. **LCP image must never be lazy-loaded** — `fetchpriority="high"` + `loading="eager"` always
3. **Budget enforced in CI** — `size-limit` or Lighthouse CI blocks regressions before they ship
4. **Animate transform and opacity only** — everything else triggers layout or paint
5. **Server state before client state** — SSR/SSG gives you LCP for free; hydrate selectively

## Reference Files

- `references/core-web-vitals.md` — LCP/INP/CLS targets, optimization techniques, web-vitals library, CrUX monitoring
- `references/image-font-optimization.md` — AVIF/WebP format selection, responsive srcset, Next.js Image, BlurHash, font subsetting, font-display comparison
- `references/bundle-js-performance.md` — code splitting, tree shaking, dynamic imports, Web Workers, React memoization, virtualization, performance budgets
- `references/network-rendering-strategies.md` — resource hints, HTTP/2, Workbox service worker strategies, SSR/SSG/RSC/Islands comparison, third-party script facades
- `references/animation-monitoring.md` — GPU-accelerated properties, layout thrashing, View Transitions API, Lighthouse CI config, anti-patterns table
