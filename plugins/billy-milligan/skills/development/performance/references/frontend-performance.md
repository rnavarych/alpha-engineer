# Frontend Performance

## Core Web Vitals Targets

```
LCP (Largest Contentful Paint):  < 2.5s   — hero image/text visible
CLS (Cumulative Layout Shift):   < 0.1    — no layout jumps
INP (Interaction to Next Paint):  < 200ms  — UI responds to clicks/taps
TTFB (Time to First Byte):       < 800ms  — server response time
FCP (First Contentful Paint):    < 1.8s   — first content rendered
```

## LCP Optimization

```html
<!-- 1. Preload critical resources -->
<link rel="preload" as="image" href="/hero.webp" fetchpriority="high" />
<link rel="preload" as="font" href="/fonts/inter.woff2" crossorigin type="font/woff2" />

<!-- 2. Priority hints on hero image -->
<img src="/hero.webp" fetchpriority="high" alt="Hero" width="1200" height="600" />

<!-- 3. Inline critical CSS (above-the-fold styles) -->
<style>/* Critical CSS here — avoids render-blocking stylesheet */</style>

<!-- 4. Defer non-critical CSS -->
<link rel="stylesheet" href="/full.css" media="print" onload="this.media='all'" />
```

```typescript
// Next.js: priority flag on hero image
import Image from 'next/image';
<Image src="/hero.webp" priority alt="Hero" width={1200} height={600} />

// Font optimization — no FOIT (Flash of Invisible Text)
import { Inter } from 'next/font/google';
const inter = Inter({ subsets: ['latin'], display: 'swap' });
```

## CLS Prevention

```css
/* Always set dimensions — prevents layout shift */
img, video { aspect-ratio: 16 / 9; width: 100%; height: auto; }

/* Reserve space for dynamic content */
.ad-slot { min-height: 250px; }
.skeleton { min-height: 200px; background: #f0f0f0; }

/* Avoid inserting content above existing content */
/* BAD: banner that pushes page down after load */
/* GOOD: reserved slot at top with fixed height */
```

## INP Optimization

```typescript
// 1. Debounce search input
import { useDeferredValue } from 'react';
const deferredQuery = useDeferredValue(searchQuery);

// 2. Non-urgent updates with startTransition
import { startTransition } from 'react';
startTransition(() => {
  setFilteredResults(heavyFilter(allItems)); // Low priority
});

// 3. Virtualize long lists — only render visible items
import { useVirtualizer } from '@tanstack/react-virtual';

// 4. Web Workers for CPU-intensive tasks
const worker = new Worker(new URL('./heavy-task.worker.ts', import.meta.url));
worker.postMessage({ data: largeDataset });
worker.onmessage = (e) => setResult(e.data);

// 5. Avoid synchronous localStorage in event handlers
// BAD: localStorage.setItem('prefs', JSON.stringify(prefs)); // Synchronous, blocks main thread
// GOOD: requestIdleCallback(() => localStorage.setItem(...));
```

## Bundle Optimization

```bash
# Analyze bundle size
ANALYZE=true npx next build

# Common offenders and replacements:
# moment.js (230KB)  -> date-fns (20KB) or dayjs (2KB)
# lodash (70KB)      -> lodash-es or native methods
# @mui full (500KB)  -> import { Button } from '@mui/material/Button'
# recharts (450KB)   -> visx (50KB per chart type)
```

```typescript
// Dynamic imports — loaded on demand
const HeavyChart = dynamic(() => import('@/components/Chart'), {
  loading: () => <Skeleton />,
  ssr: false,
});

// Route-level code splitting (automatic in Next.js App Router)
// Each page.tsx is its own chunk

// Tree-shaking: use named imports
import { debounce } from 'lodash-es';  // Only debounce is included
// NOT: import _ from 'lodash';        // Entire library included
```

## Image Optimization

```
Format priority: AVIF > WebP > PNG/JPEG
Responsive: srcset with multiple sizes
Lazy loading: loading="lazy" for below-fold images
Priority: fetchpriority="high" for hero image only
CDN: serve from edge, cache headers

Next.js Image component handles all of this:
  - Automatic format negotiation (AVIF/WebP)
  - Responsive srcset generation
  - Lazy loading by default
  - Blur placeholder support
```

## Anti-Patterns
- Optimizing without measuring — profile first, optimize the actual bottleneck
- Loading entire library for one function — tree-shake or use lighter alternative
- Render-blocking CSS/JS in `<head>` — defer non-critical resources
- No dimensions on images — causes CLS (layout shift)
- Heavy computation on main thread — use Web Workers or startTransition

## Quick Reference
```
LCP: <2.5s — preload hero, priority image, inline critical CSS
CLS: <0.1 — set width/height, reserve space, no above-fold insertion
INP: <200ms — debounce, startTransition, virtualize, Web Workers
Bundle: analyze -> replace heavy deps -> dynamic imports -> tree-shake
Images: AVIF/WebP, srcset, lazy (below-fold), priority (hero only)
Fonts: display: swap, preload, subset
Measure: Lighthouse, CrUX, web-vitals library
```
