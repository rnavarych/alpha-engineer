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

- **Target**: under 2.5 seconds. Measures when the largest visible content element finishes rendering.
- **Common LCP elements**: hero images, heading text blocks, video poster images, background images with text overlay.

#### LCP Causes and Optimization

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
- Reduce server response time (TTFB) with CDN edge caching, server-side caching, and HTTP/2 or HTTP/3.
- Avoid client-side rendering for the initial page load. Use SSR or SSG.

### Interaction to Next Paint (INP)

- **Target**: under 200 milliseconds. Measures the latency of all user interactions throughout the page lifecycle (replaced FID in March 2024).
- INP measures the full cycle: input delay + processing time + presentation delay.

#### INP Optimization

```typescript
// Break up long tasks with scheduler.yield() or setTimeout
async function processLargeDataset(items: Item[]) {
  const CHUNK_SIZE = 50
  for (let i = 0; i < items.length; i += CHUNK_SIZE) {
    const chunk = items.slice(i, i + CHUNK_SIZE)
    processChunk(chunk)

    // Yield to the main thread between chunks
    if (i + CHUNK_SIZE < items.length) {
      await scheduler.yield?.() ?? new Promise(r => setTimeout(r, 0))
    }
  }
}

// Debounce input handlers
function handleSearch(query: string) {
  // Debounce to avoid processing every keystroke
  clearTimeout(searchTimeout)
  searchTimeout = setTimeout(() => {
    performSearch(query)
  }, 150)
}
```

- Avoid layout thrashing: batch DOM reads before DOM writes. Use `requestAnimationFrame` for visual updates.

```typescript
// Bad: read-write-read-write causes forced reflows
elements.forEach(el => {
  const height = el.offsetHeight      // read (forces layout)
  el.style.height = height + 10 + 'px' // write (invalidates layout)
})

// Good: batch reads, then batch writes
const heights = elements.map(el => el.offsetHeight) // all reads
elements.forEach((el, i) => {
  el.style.height = heights[i] + 10 + 'px'          // all writes
})
```

- Minimize main-thread work during interactions: virtualize large lists, defer non-critical computations.
- Use `useTransition` (React) or `requestIdleCallback` to deprioritize non-urgent updates.

### Cumulative Layout Shift (CLS)

- **Target**: under 0.1. Measures unexpected layout shifts during the page lifecycle.

#### CLS Prevention Checklist

```html
<!-- Always set dimensions on images and videos -->
<img src="photo.webp" alt="Photo" width="800" height="600" />

<!-- Or use aspect-ratio for responsive images -->
<style>
  .responsive-img {
    width: 100%;
    height: auto;
    aspect-ratio: 16 / 9;
  }
</style>

<!-- Reserve space for ads/embeds with min-height -->
<div class="ad-slot" style="min-height: 250px;">
  <!-- ad loads here -->
</div>
```

- Avoid injecting content above existing content after initial render. Use fixed-size placeholders or skeleton screens.
- Use `font-display: optional` or `font-display: swap` with `size-adjust` to minimize layout shift from web fonts.
- Dynamically loaded content (banners, cookie notices) should overlay existing content or use reserved space.
- Use CSS `contain: layout` on elements that change size independently to limit shift impact.

## Image Optimization

### Format Selection

| Format | Compression | Browser Support | Best For |
|---|---|---|---|
| AVIF | Best (50% smaller than JPEG) | Chrome, Firefox, Safari 16.4+ | Photos, complex images |
| WebP | Good (25-35% smaller than JPEG) | All modern browsers | Universal fallback, photos |
| PNG | Lossless | Universal | Icons, screenshots, transparency |
| SVG | Vector (tiny for icons) | Universal | Icons, logos, illustrations |

### Responsive Images

```html
<!-- Resolution switching with srcset and sizes -->
<img
  srcset="photo-400.webp 400w,
          photo-800.webp 800w,
          photo-1200.webp 1200w,
          photo-1600.webp 1600w"
  sizes="(max-width: 640px) 100vw,
         (max-width: 1024px) 50vw,
         33vw"
  src="photo-800.webp"
  alt="Product photo"
  loading="lazy"
  decoding="async"
  width="800"
  height="600"
/>

<!-- Art direction with <picture> -->
<picture>
  <source media="(min-width: 1024px)" srcset="hero-wide.avif" type="image/avif" />
  <source media="(min-width: 1024px)" srcset="hero-wide.webp" type="image/webp" />
  <source srcset="hero-narrow.avif" type="image/avif" />
  <source srcset="hero-narrow.webp" type="image/webp" />
  <img src="hero-narrow.jpg" alt="Hero" width="800" height="400"
       loading="eager" fetchpriority="high" />
</picture>
```

### Next.js Image Component

```tsx
import Image from 'next/image'

// Automatic optimization, lazy loading, responsive sizing
<Image
  src="/hero.jpg"
  alt="Hero banner"
  width={1200}
  height={600}
  priority           // for LCP images (disables lazy loading)
  placeholder="blur"  // shows blur placeholder while loading
  blurDataURL={blurHash}
  sizes="(max-width: 768px) 100vw, 50vw"
/>
```

### Placeholder Strategies

- **BlurHash / LQIP (Low Quality Image Placeholder)**: Generate a tiny base64 blur at build time, display while the full image loads. Prevents CLS and improves perceived performance.
- **Dominant color**: Extract the dominant color as a CSS background. Simpler than blur, still prevents CLS.
- **Skeleton**: Use a CSS skeleton shimmer for non-photo content areas.

## Font Optimization

### Font Loading Strategies

```css
/* Self-hosted font with optimal loading */
@font-face {
  font-family: 'Inter';
  src: url('/fonts/Inter-Regular.woff2') format('woff2');
  font-weight: 400;
  font-style: normal;
  font-display: swap;         /* show fallback immediately, swap when loaded */
  unicode-range: U+0000-00FF; /* Latin subset only */
}

/* Fallback font metrics matching to reduce CLS */
@font-face {
  font-family: 'Inter Fallback';
  src: local('Arial');
  size-adjust: 107%;
  ascent-override: 90%;
  descent-override: 22%;
  line-gap-override: 0%;
}

body {
  font-family: 'Inter', 'Inter Fallback', system-ui, sans-serif;
}
```

```html
<!-- Preload critical fonts -->
<link rel="preload" href="/fonts/Inter-Regular.woff2" as="font" type="font/woff2" crossorigin />
<link rel="preload" href="/fonts/Inter-Bold.woff2" as="font" type="font/woff2" crossorigin />
```

### Font Subsetting

```bash
# Using pyftsubset (fonttools)
pyftsubset Inter-Regular.ttf \
  --output-file=Inter-Regular-Latin.woff2 \
  --flavor=woff2 \
  --layout-features='kern,liga' \
  --unicodes=U+0000-00FF,U+2000-206F

# Using glyphhanger
glyphhanger --whitelist="US_ASCII" --subset=Inter-Regular.ttf --formats=woff2
```

- Latin-only subsets are 70-90% smaller than full Unicode fonts.
- Use variable fonts instead of multiple weight files. One variable font file replaces regular, medium, semibold, and bold.
- Limit font families and weights. Each variant is a separate file.

### font-display Comparison

| Value | Behavior | Use For |
|---|---|---|
| `swap` | Shows fallback immediately, swaps when ready | Body text (no invisible text) |
| `optional` | Shows fallback, only swaps if fast load | Hero text (minimizes CLS) |
| `fallback` | Brief invisible period (100ms), then fallback | Balance between swap and optional |
| `block` | Invisible up to 3s, then fallback | Icon fonts (avoid wrong glyphs) |

## Bundle Optimization

### Code Splitting Strategies

```tsx
// Route-based splitting (React)
const Dashboard = lazy(() => import('./pages/Dashboard'))
const Settings = lazy(() => import('./pages/Settings'))

// Component-based splitting
const HeavyEditor = lazy(() => import('./components/RichTextEditor'))

// Library-based splitting (only import when needed)
async function handleExport() {
  const { jsPDF } = await import('jspdf')
  const doc = new jsPDF()
  // ...
}
```

### Tree Shaking

- Use ES module syntax (`import`/`export`) exclusively. CommonJS (`require`) cannot be tree-shaken.
- Ensure `package.json` includes `"sideEffects": false` for libraries.
- Import only what you need: `import { debounce } from 'lodash-es'` instead of `import _ from 'lodash'`.
- Avoid barrel files (`index.ts` re-exports) for large libraries. They can prevent tree shaking.

### Dynamic Import Patterns

```tsx
// Prefetch on hover (load before user clicks)
<Link
  to="/dashboard"
  onMouseEnter={() => import('./pages/Dashboard')}
>
  Dashboard
</Link>

// Load on interaction
function CommentSection() {
  const [Editor, setEditor] = useState<ComponentType | null>(null)

  return (
    <>
      {Editor ? (
        <Editor />
      ) : (
        <button onClick={async () => {
          const { RichEditor } = await import('./RichEditor')
          setEditor(() => RichEditor)
        }}>
          Write a comment
        </button>
      )}
    </>
  )
}
```

## JavaScript Performance

### Main Thread Optimization

```typescript
// Web Worker for CPU-intensive tasks
// worker.ts
self.onmessage = (event: MessageEvent<{ items: Item[] }>) => {
  const result = expensiveComputation(event.data.items)
  self.postMessage(result)
}

// main.ts
const worker = new Worker(new URL('./worker.ts', import.meta.url), { type: 'module' })
worker.postMessage({ items: largeDataset })
worker.onmessage = (event) => {
  updateUI(event.data)
}
```

### requestIdleCallback

```typescript
// Defer non-critical work to idle periods
function deferAnalytics(data: AnalyticsEvent) {
  if ('requestIdleCallback' in window) {
    requestIdleCallback(() => sendAnalytics(data), { timeout: 2000 })
  } else {
    setTimeout(() => sendAnalytics(data), 0)
  }
}
```

### Scheduling API

```typescript
// scheduler.postTask for priority-based scheduling
async function handleUserClick() {
  // High priority: update UI immediately
  await scheduler.postTask(() => updateClickFeedback(), { priority: 'user-blocking' })

  // Lower priority: analytics
  scheduler.postTask(() => trackClick(), { priority: 'background' })
}
```

## Network Optimization

### Resource Hints

```html
<!-- DNS prefetch: resolve DNS for third-party origins -->
<link rel="dns-prefetch" href="https://api.example.com" />

<!-- Preconnect: DNS + TCP + TLS handshake -->
<link rel="preconnect" href="https://fonts.googleapis.com" crossorigin />

<!-- Preload: fetch critical resources early -->
<link rel="preload" href="/critical.css" as="style" />
<link rel="preload" href="/hero.webp" as="image" type="image/webp" />

<!-- Prefetch: fetch resources for next navigation -->
<link rel="prefetch" href="/next-page.js" as="script" />

<!-- Modulepreload: preload ES modules with full dependency resolution -->
<link rel="modulepreload" href="/src/app.js" />
```

### HTTP/2 and HTTP/3

- **HTTP/2 multiplexing**: Multiple requests share a single TCP connection. No need to concatenate files or use sprite sheets.
- **HTTP/3 QUIC**: UDP-based transport. Eliminates head-of-line blocking. Faster connection establishment. Enable on CDN (Cloudflare, AWS CloudFront support it).
- With HTTP/2+, serving many small files is preferred over few large bundles. Granular code splitting is now a net positive.

### Service Workers for Caching

```typescript
// service-worker.ts with Workbox
import { precacheAndRoute } from 'workbox-precaching'
import { registerRoute } from 'workbox-routing'
import { CacheFirst, NetworkFirst, StaleWhileRevalidate } from 'workbox-strategies'
import { ExpirationPlugin } from 'workbox-expiration'

// Precache build assets
precacheAndRoute(self.__WB_MANIFEST)

// Cache-first for static assets
registerRoute(
  ({ request }) => request.destination === 'image' || request.destination === 'font',
  new CacheFirst({
    cacheName: 'static-assets',
    plugins: [new ExpirationPlugin({ maxEntries: 100, maxAgeSeconds: 30 * 24 * 60 * 60 })],
  }),
)

// Network-first for API data
registerRoute(
  ({ url }) => url.pathname.startsWith('/api/'),
  new NetworkFirst({
    cacheName: 'api-cache',
    plugins: [new ExpirationPlugin({ maxEntries: 50, maxAgeSeconds: 5 * 60 })],
  }),
)

// Stale-while-revalidate for semi-dynamic content
registerRoute(
  ({ request }) => request.destination === 'document',
  new StaleWhileRevalidate({ cacheName: 'pages' }),
)
```

## Rendering Strategies

| Strategy | When HTML is Generated | Hydration | Best For |
|---|---|---|---|
| CSR (Client-Side) | In the browser | None (full render) | SPAs behind auth, dashboards |
| SSR (Server-Side) | On each request | Full hydration | Dynamic, SEO-critical pages |
| SSG (Static Generation) | At build time | Full hydration | Blogs, docs, marketing |
| ISR (Incremental Static) | At build + on-demand | Full hydration | E-commerce, large content sites |
| Streaming SSR | Progressively on request | Progressive hydration | Complex pages with slow data |
| Islands Architecture | Static HTML + interactive islands | Partial hydration | Content-heavy sites (Astro) |
| React Server Components | Server (no client JS) | Selective (client components only) | Next.js App Router |

### React Server Components

```tsx
// Server Component (no client JS, direct data access)
async function ProductPage({ id }: { id: string }) {
  const product = await db.products.findById(id) // direct DB access
  return (
    <div>
      <h1>{product.name}</h1>
      <p>{product.description}</p>
      <AddToCartButton product={product} />  {/* Client Component */}
    </div>
  )
}

// Client Component (interactive, hydrated)
'use client'
function AddToCartButton({ product }: { product: Product }) {
  const [added, setAdded] = useState(false)
  return <button onClick={() => { addToCart(product); setAdded(true) }}>
    {added ? 'Added' : 'Add to Cart'}
  </button>
}
```

### Partial Hydration / Islands (Astro)

```astro
---
// Only this interactive island ships JavaScript
import Counter from '../components/Counter.tsx'
---
<html>
  <body>
    <h1>Static content (zero JS)</h1>
    <p>This text is pure HTML. No hydration cost.</p>

    <!-- Only this component sends JavaScript to the client -->
    <Counter client:visible />
  </body>
</html>
```

## Third-Party Script Performance

### Impact Analysis

```typescript
// Measure third-party impact with Performance Observer
const observer = new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) {
    if (entry.name.includes('third-party-domain.com')) {
      console.log(`Third-party resource: ${entry.name}, Duration: ${entry.duration}ms`)
    }
  }
})
observer.observe({ entryTypes: ['resource'] })
```

### Loading Strategies

```html
<!-- Defer non-critical scripts -->
<script src="https://analytics.example.com/script.js" defer></script>

<!-- Async for independent scripts -->
<script src="https://ads.example.com/tag.js" async></script>
```

### Partytown (Web Workers for Third-Party Scripts)

```html
<!-- Move third-party scripts off the main thread -->
<script type="text/partytown" src="https://analytics.example.com/script.js"></script>
```

### Facade Pattern

```tsx
// Show a lightweight placeholder until interaction
function YouTubeEmbed({ videoId }: { videoId: string }) {
  const [loaded, setLoaded] = useState(false)

  if (!loaded) {
    return (
      <button
        onClick={() => setLoaded(true)}
        style={{ backgroundImage: `url(https://i.ytimg.com/vi/${videoId}/hqdefault.jpg)` }}
        className="youtube-facade"
        aria-label="Play video"
      >
        <PlayIcon />
      </button>
    )
  }

  return <iframe src={`https://www.youtube.com/embed/${videoId}?autoplay=1`} ... />
}
```

## React Performance

### Memoization

```tsx
// React.memo: skip re-render when props haven't changed
const ExpensiveList = memo(function ExpensiveList({ items }: { items: Item[] }) {
  return items.map(item => <ExpensiveItem key={item.id} item={item} />)
})

// useMemo: memoize expensive computations
const filteredItems = useMemo(
  () => items.filter(item => item.name.includes(search)),
  [items, search],
)

// useCallback: stable function references for child components
const handleClick = useCallback((id: string) => {
  setSelected(id)
}, [])
```

### React Compiler (React 19+)

- The React Compiler automatically adds memoization (`memo`, `useMemo`, `useCallback`) at build time.
- When using the React Compiler, remove manual memoization. The compiler produces better results than hand-written memos.
- Enabled via Babel plugin: `babel-plugin-react-compiler`.

### Virtualization

```tsx
import { useVirtualizer } from '@tanstack/react-virtual'

function VirtualList({ items }: { items: Item[] }) {
  const parentRef = useRef<HTMLDivElement>(null)

  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 50,     // estimated row height
    overscan: 5,                // render 5 extra items above/below viewport
  })

  return (
    <div ref={parentRef} style={{ height: '400px', overflow: 'auto' }}>
      <div style={{ height: `${virtualizer.getTotalSize()}px`, position: 'relative' }}>
        {virtualizer.getVirtualItems().map((virtualRow) => (
          <div
            key={virtualRow.key}
            style={{
              position: 'absolute',
              top: 0,
              transform: `translateY(${virtualRow.start}px)`,
              height: `${virtualRow.size}px`,
            }}
          >
            {items[virtualRow.index].name}
          </div>
        ))}
      </div>
    </div>
  )
}
```

### Concurrent Rendering

```tsx
// useTransition: mark state updates as non-urgent
function SearchResults() {
  const [query, setQuery] = useState('')
  const [isPending, startTransition] = useTransition()

  function handleChange(e: ChangeEvent<HTMLInputElement>) {
    setQuery(e.target.value)              // urgent: update input immediately
    startTransition(() => {
      setFilteredResults(filterLargeList(e.target.value)) // non-urgent: can be interrupted
    })
  }

  return (
    <>
      <input value={query} onChange={handleChange} />
      {isPending && <Spinner />}
      <ResultsList results={filteredResults} />
    </>
  )
}

// useDeferredValue: defer expensive re-renders
function Dashboard({ data }: { data: Data }) {
  const deferredData = useDeferredValue(data)
  const isStale = data !== deferredData

  return (
    <div style={{ opacity: isStale ? 0.7 : 1 }}>
      <ExpensiveChart data={deferredData} />
    </div>
  )
}
```

## Animation Performance

### GPU-Accelerated Properties

- Animate only `transform` and `opacity` for 60fps performance. These run on the compositor thread, avoiding layout and paint.

```css
/* Good: GPU-accelerated */
.card:hover {
  transform: translateY(-4px) scale(1.02);
  opacity: 0.95;
}

/* Bad: triggers layout and paint */
.card:hover {
  top: -4px;         /* triggers layout */
  width: 102%;       /* triggers layout */
  box-shadow: 0 4px 8px rgba(0,0,0,0.2); /* triggers paint */
}
```

### Layout Thrashing Prevention

```typescript
// Use requestAnimationFrame to batch DOM updates
function animateElements(elements: HTMLElement[]) {
  requestAnimationFrame(() => {
    elements.forEach(el => {
      el.style.transform = `translateX(${el.dataset.targetX}px)`
    })
  })
}
```

### View Transitions API

```typescript
// Smooth page transitions (SPA)
if (document.startViewTransition) {
  document.startViewTransition(() => {
    updateDOM() // swap content
  })
} else {
  updateDOM() // fallback: instant swap
}
```

```css
::view-transition-old(root) {
  animation: fade-out 200ms ease-out;
}
::view-transition-new(root) {
  animation: fade-in 200ms ease-in;
}

/* Named transitions for specific elements */
.hero-image {
  view-transition-name: hero;
}
```

## Monitoring and Measurement

### Web Vitals Library

```typescript
import { onLCP, onINP, onCLS } from 'web-vitals'

onLCP(metric => sendToAnalytics('LCP', metric))
onINP(metric => sendToAnalytics('INP', metric))
onCLS(metric => sendToAnalytics('CLS', metric))

function sendToAnalytics(name: string, metric: Metric) {
  const body = JSON.stringify({
    name,
    value: metric.value,
    rating: metric.rating,    // 'good', 'needs-improvement', 'poor'
    delta: metric.delta,
    id: metric.id,
    navigationType: metric.navigationType,
  })
  // Use sendBeacon for reliability
  navigator.sendBeacon('/api/vitals', body)
}
```

### Lighthouse CI

```yaml
# lighthouserc.js
module.exports = {
  ci: {
    collect: {
      url: ['http://localhost:3000/', 'http://localhost:3000/products'],
      numberOfRuns: 3,
    },
    assert: {
      assertions: {
        'categories:performance': ['error', { minScore: 0.9 }],
        'largest-contentful-paint': ['error', { maxNumericValue: 2500 }],
        'interactive': ['error', { maxNumericValue: 3500 }],
        'cumulative-layout-shift': ['error', { maxNumericValue: 0.1 }],
      },
    },
    upload: {
      target: 'temporary-public-storage',
    },
  },
}
```

### CrUX (Chrome User Experience Report)

- CrUX provides real-user performance data from Chrome users who opted in.
- Access via BigQuery, CrUX API, or PageSpeed Insights.
- CrUX data is used by Google for search ranking (Page Experience signals).
- Use CrUX for field data; use Lighthouse for lab data. Both are needed for a complete picture.

### Performance Budget

```json
// size-limit config in package.json
{
  "size-limit": [
    { "path": "dist/index.js", "limit": "80 KB", "gzip": true },
    { "path": "dist/vendor.js", "limit": "150 KB", "gzip": true },
    { "path": "dist/**/*.css", "limit": "30 KB", "gzip": true }
  ]
}
```

| Resource Type | Budget (gzipped) |
|---|---|
| Total JavaScript | < 200 KB |
| Single route bundle | < 80 KB |
| Total CSS | < 50 KB |
| Hero image | < 100 KB |
| Web fonts | < 100 KB |
| Total page weight | < 1 MB |

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Solution |
|---|---|---|
| Lazy-loading the LCP image | Delays largest paint | Use `loading="eager"` + `fetchpriority="high"` |
| No image dimensions | Causes layout shifts (CLS) | Always set `width`/`height` or `aspect-ratio` |
| Synchronous third-party scripts | Blocks rendering | Use `async`/`defer`, Partytown, or facade pattern |
| Manual memoization everywhere | Code noise, often wrong deps | Use React Compiler, or memo only measured bottlenecks |
| Animating layout properties | Janky 60fps animations | Animate `transform` and `opacity` only |
| No performance budget | Silent regression over time | `size-limit` or Lighthouse CI in CI pipeline |
| Loading all fonts upfront | Slow first paint, wasted bandwidth | Subset fonts, use `font-display`, preload critical only |
| Full hydration on static pages | Unnecessary JavaScript | Islands architecture (Astro), RSC, partial hydration |
