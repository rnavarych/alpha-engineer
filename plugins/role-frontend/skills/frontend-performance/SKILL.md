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

## Core Web Vitals

### Largest Contentful Paint (LCP)
- Target: under 2.5 seconds. Measures when the largest visible content element finishes rendering.
- Optimize the critical rendering path: inline critical CSS, preload hero images and fonts, defer non-essential JavaScript.
- Use `<link rel="preload">` for above-the-fold images and `fetchpriority="high"` on the LCP element.
- Avoid client-side rendering for the initial page load. Use SSR or SSG to deliver the LCP element in the HTML response.
- Reduce server response time (TTFB) with CDN edge caching, server-side caching, and HTTP/2 or HTTP/3.

### Interaction to Next Paint (INP)
- Target: under 200 milliseconds. Measures the latency of all user interactions throughout the page lifecycle.
- Break up long tasks (>50ms) using `requestIdleCallback`, `setTimeout(fn, 0)`, or `scheduler.yield()`.
- Avoid layout thrashing: batch DOM reads before DOM writes. Use `requestAnimationFrame` for visual updates.
- Minimize main-thread work during interactions: debounce input handlers, virtualize large lists, defer non-critical computations.
- Use `useTransition` (React) or `requestIdleCallback` to deprioritize non-urgent updates during user interactions.

### Cumulative Layout Shift (CLS)
- Target: under 0.1. Measures unexpected layout shifts during the page lifecycle.
- Always set explicit `width` and `height` (or `aspect-ratio`) on images and videos. Use `<img width="800" height="600">`.
- Reserve space for dynamic content: ads, embeds, lazy-loaded components, and font-swapped text.
- Avoid injecting content above existing content after initial render. Use fixed-size placeholders or skeleton screens.
- Use `font-display: optional` or `font-display: swap` with `size-adjust` to minimize layout shift from web fonts.

## Code Splitting

- Split by route: each route loads its own JavaScript bundle. All major frameworks (React, Vue, Angular) support this natively.
- Split by component: use `React.lazy()`, Vue `defineAsyncComponent()`, or Angular `loadComponent` for heavy components (editors, charts, maps).
- Split by vendor: separate `node_modules` into a vendor chunk that changes less frequently and benefits from long-term caching.
- Analyze the dependency graph. Use dynamic `import()` to defer loading libraries only needed on interaction (date pickers, rich text editors).
- Set maximum chunk size limits in the bundler config. Warn or fail the build if any single chunk exceeds the budget.

## Tree Shaking

- Use ES module syntax (`import`/`export`) exclusively. CommonJS (`require`) cannot be tree-shaken.
- Ensure `package.json` includes `"sideEffects": false` for libraries, or list specific files with side effects.
- Import only what you need: `import { debounce } from 'lodash-es'` instead of `import _ from 'lodash'`.
- Verify tree shaking works by inspecting the bundle output. Unused exports should not appear in the production build.
- Avoid barrel files (`index.ts` re-exports) for large libraries. They can prevent tree shaking by forcing the bundler to evaluate all modules.

## Image Optimization

- Serve modern formats: WebP for broad support, AVIF for best compression. Use `<picture>` with fallbacks: `<source type="image/avif">`, `<source type="image/webp">`, `<img src="fallback.jpg">`.
- Implement responsive images with `srcset` and `sizes` attributes. Serve different resolutions for different viewport widths.
- Lazy-load below-the-fold images with `loading="lazy"`. Do not lazy-load the LCP image; use `loading="eager"` and `fetchpriority="high"` instead.
- Compress images at build time or via a CDN image service (Cloudinary, Imgix, Vercel Image Optimization).
- Use CSS `background-image` sparingly. Prefer `<img>` for content images because they support `loading="lazy"`, `srcset`, and accessibility (`alt` text).
- Set explicit dimensions or aspect ratios on all images to prevent CLS.

## Font Loading

- Self-host fonts for performance and privacy. Avoid Google Fonts CDN for GDPR-sensitive applications.
- Use `font-display: swap` for body text (shows fallback immediately, swaps when loaded). Use `font-display: optional` for hero text (avoids layout shift if the font does not load in time).
- Preload critical fonts: `<link rel="preload" href="/fonts/Inter.woff2" as="font" type="font/woff2" crossorigin>`.
- Subset fonts to include only needed character ranges. Latin-only subsets are 70-90% smaller than full Unicode fonts.
- Use `size-adjust`, `ascent-override`, `descent-override` on the fallback font face to match metrics and minimize CLS.
- Limit font families and weights. Each variant is a separate file. Two families with three weights each means six font files.

## Service Workers

- Use service workers for offline support, cache-first strategies, and background sync.
- **Cache strategies**: Cache-first for static assets (fonts, images, CSS). Network-first for API data. Stale-while-revalidate for semi-dynamic content (blog posts, product pages).
- Use Workbox for service worker generation and precaching. Integrate with the build pipeline to auto-generate the precache manifest.
- Implement a skip-waiting and claim-clients strategy with a user-facing update prompt for new versions.
- Cache API responses with a versioned cache name. Clean up old caches in the `activate` event.
- Test service workers in Chrome DevTools Application panel. Clear caches between deployments to avoid stale content.

## Bundle Analysis

- **webpack-bundle-analyzer**: Generate a treemap visualization of bundle contents. Run as part of CI to detect size regressions.
- **source-map-explorer**: Analyze actual source map data for precise per-file size attribution.
- Set performance budgets in the bundler config. Fail the build if total JS exceeds 200KB gzipped or any single route bundle exceeds 100KB gzipped.
- Track bundle size over time. Use tools like `bundlesize` or `size-limit` in CI to compare against the baseline.
- Identify and eliminate duplicate dependencies. Use `npm ls <package>` or bundler deduplication plugins.
- Monitor real user metrics (RUM) with web-vitals library or a monitoring service to correlate bundle changes with performance regressions.
