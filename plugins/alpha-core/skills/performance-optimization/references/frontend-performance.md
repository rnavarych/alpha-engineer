# Frontend Performance

## When to load
Load when optimizing Core Web Vitals, analyzing bundle size, implementing code splitting, or tuning network performance.

## Core Web Vitals Targets

| Metric | Good | Needs Improvement | Poor | What It Measures |
|--------|------|-------------------|------|-----------------|
| **LCP** (Largest Contentful Paint) | < 2.5s | 2.5s - 4.0s | > 4.0s | Loading performance |
| **INP** (Interaction to Next Paint) | < 200ms | 200ms - 500ms | > 500ms | Responsiveness |
| **CLS** (Cumulative Layout Shift) | < 0.1 | 0.1 - 0.25 | > 0.25 | Visual stability |

## LCP Optimization
- Preload hero images: `<link rel="preload" as="image" href="hero.webp" fetchpriority="high">`
- Use `fetchpriority="high"` on LCP image element
- Serve responsive images: `<img srcset="..." sizes="...">`
- Optimize server response time (TTFB < 800ms)
- Avoid render-blocking CSS/JS (inline critical CSS, defer non-critical)

```html
<picture>
  <source srcset="hero-400.avif 400w, hero-800.avif 800w" type="image/avif" sizes="100vw">
  <source srcset="hero-400.webp 400w, hero-800.webp 800w" type="image/webp" sizes="100vw">
  <img src="hero-800.jpg" alt="Hero" width="1200" height="600" fetchpriority="high" decoding="async">
</picture>
```

## INP Optimization
```javascript
// Break long tasks (>50ms) with scheduler.yield()
async function processLargeList(items) {
  for (let i = 0; i < items.length; i++) {
    processItem(items[i]);
    if (i % 100 === 0) {
      await scheduler.yield();  // Yield to browser for rendering/input
    }
  }
}
```
- Debounce input handlers: 150-300ms for search, `requestAnimationFrame` for scroll/resize
- Use Web Workers for CPU-intensive operations (parsing, sorting, image processing)
- Virtualize long lists with `@tanstack/react-virtual` or `content-visibility: auto`

## CLS Optimization
- Always set `width` and `height` on images/video (or `aspect-ratio: 16/9`)
- Reserve space for dynamic content (ads, embeds) with `min-height`
- Use `font-display: optional` to prevent layout shift, or preload + `swap`
- Avoid inserting content above existing content

## Image Optimization
| Format | Use Case | Compression | Browser Support |
|--------|----------|-------------|-----------------|
| **WebP** | Photos, illustrations | 25-35% smaller than JPEG | 97%+ |
| **AVIF** | Photos (best compression) | 50% smaller than JPEG | 92%+ |
| **SVG** | Icons, logos, illustrations | Vector (infinite scale) | All |
| **PNG** | Screenshots, transparency | Lossless | All |

## Bundle Analysis and Code Splitting
```bash
npx webpack-bundle-analyzer stats.json
npx vite-bundle-visualizer
npx source-map-explorer dist/main.*.js

# Common wins:
# - Replace moment.js (330KB) with date-fns (tree-shakeable) or dayjs (2KB)
# - Replace lodash (71KB) with lodash-es or native methods
# - Dynamic import() for route-level and heavy component splitting
```

```javascript
// React route-based splitting
const Dashboard = React.lazy(() => import('./pages/Dashboard'));

// Next.js dynamic imports with loading state
import dynamic from 'next/dynamic';
const Map = dynamic(() => import('./Map'), {
  loading: () => <MapSkeleton />,
  ssr: false,
});

// Vue async components
const HeavyChart = defineAsyncComponent(() => import('./HeavyChart.vue'));
```

## Network Performance

### Protocol Comparison
| Feature | HTTP/1.1 | HTTP/2 | HTTP/3 (QUIC) |
|---------|----------|--------|---------------|
| **Multiplexing** | No (6 connections/domain) | Yes (single connection) | Yes (no head-of-line blocking) |
| **Header compression** | None | HPACK | QPACK |
| **Connection setup** | TCP + TLS (2-3 RTT) | TCP + TLS (2-3 RTT) | 0-1 RTT (QUIC) |
| **Best for** | Legacy | Most web traffic | Mobile, lossy networks |

### Compression
- **Brotli** (`br`): 15-25% smaller than gzip. Use for static assets.
- **gzip**: Universal support. Level 6 is a good default balance.
- **zstd**: Emerging standard. Better ratio than gzip, faster than brotli.

### Connection Optimization
- `<link rel="dns-prefetch" href="//api.example.com">`
- `<link rel="preconnect" href="https://api.example.com">` (DNS + TCP + TLS)
- HTTP keep-alive: Reuse TCP connections (default in HTTP/1.1+)
