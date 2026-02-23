# Core Web Vitals

## When to load
Load when diagnosing or fixing LCP, INP, or CLS scores — measuring, debugging, and optimizing the three primary Google performance metrics.

## LCP — Largest Contentful Paint

**Target**: under 2.5 seconds. Measures when the largest visible content element finishes rendering.
Common LCP elements: hero images, heading text blocks, video poster images, background images with text overlay.

| Cause | Solution |
|---|---|
| Slow server response (TTFB > 800ms) | CDN edge caching, server-side caching, HTTP/2 or HTTP/3 |
| Render-blocking resources | Inline critical CSS, defer non-critical JS, preload key resources |
| Slow resource load (image/font) | Compress images, preload LCP image, use CDN, modern formats |
| Client-side rendering | Use SSR or SSG to deliver LCP element in the HTML response |

```html
<!-- Preload the LCP image -->
<link rel="preload" href="/hero.webp" as="image" type="image/webp" fetchpriority="high" />

<!-- Set fetchpriority on the LCP element -->
<img src="/hero.webp" alt="Hero" width="1200" height="600"
     fetchpriority="high" loading="eager" decoding="async" />
```

- Avoid lazy-loading the LCP image. Use `loading="eager"` and `fetchpriority="high"` explicitly.
- Reduce TTFB with CDN edge caching and HTTP/2 or HTTP/3.
- Avoid client-side rendering for the initial page load. Use SSR or SSG.

## INP — Interaction to Next Paint

**Target**: under 200ms. Measures the latency of all user interactions (replaced FID in March 2024).
INP measures the full cycle: input delay + processing time + presentation delay.

```typescript
// Break up long tasks with scheduler.yield() or setTimeout
async function processLargeDataset(items: Item[]) {
  const CHUNK_SIZE = 50
  for (let i = 0; i < items.length; i += CHUNK_SIZE) {
    const chunk = items.slice(i, i + CHUNK_SIZE)
    processChunk(chunk)
    if (i + CHUNK_SIZE < items.length) {
      await scheduler.yield?.() ?? new Promise(r => setTimeout(r, 0))
    }
  }
}

// Batch DOM reads before DOM writes
const heights = elements.map(el => el.offsetHeight) // all reads first
elements.forEach((el, i) => {
  el.style.height = heights[i] + 10 + 'px'          // then all writes
})
```

- Minimize main-thread work: virtualize large lists, defer non-critical computations.
- Use `useTransition` (React) or `requestIdleCallback` to deprioritize non-urgent updates.

## CLS — Cumulative Layout Shift

**Target**: under 0.1. Measures unexpected layout shifts during the page lifecycle.

```html
<!-- Always set dimensions on images and videos -->
<img src="photo.webp" alt="Photo" width="800" height="600" />

<!-- Or use aspect-ratio for responsive images -->
<style>
  .responsive-img { width: 100%; height: auto; aspect-ratio: 16 / 9; }
</style>

<!-- Reserve space for ads/embeds with min-height -->
<div class="ad-slot" style="min-height: 250px;"><!-- ad loads here --></div>
```

- Avoid injecting content above existing content after initial render. Use fixed-size placeholders or skeleton screens.
- Use `font-display: optional` or `font-display: swap` with `size-adjust` to minimize font layout shift.
- Use CSS `contain: layout` on elements that change size independently to limit shift impact.

## Monitoring

```typescript
import { onLCP, onINP, onCLS } from 'web-vitals'

onLCP(metric => sendToAnalytics('LCP', metric))
onINP(metric => sendToAnalytics('INP', metric))
onCLS(metric => sendToAnalytics('CLS', metric))

function sendToAnalytics(name: string, metric: Metric) {
  navigator.sendBeacon('/api/vitals', JSON.stringify({
    name, value: metric.value, rating: metric.rating,
    delta: metric.delta, id: metric.id,
  }))
}
```

- CrUX provides real-user field data from Chrome users. Use for field data; Lighthouse for lab data. Both needed.
- CrUX data is used by Google for search ranking (Page Experience signals).
