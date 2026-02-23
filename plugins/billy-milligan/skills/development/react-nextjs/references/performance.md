# Performance

## Core Web Vitals Targets
```
LCP (Largest Contentful Paint):  < 2.5s  — hero image/text visible
CLS (Cumulative Layout Shift):   < 0.1   — no layout jumps
INP (Interaction to Next Paint):  < 200ms — UI responds to clicks
TTFB (Time to First Byte):       < 800ms — server response time
```

## Bundle Analysis

```bash
# Install analyzer
npm install @next/bundle-analyzer

# next.config.ts
import withBundleAnalyzer from '@next/bundle-analyzer';
export default withBundleAnalyzer({ enabled: process.env.ANALYZE === 'true' })({});

# Run analysis
ANALYZE=true npx next build
```

### Common Bundle Offenders
```
moment.js     ~230KB  → date-fns (~20KB tree-shaken) or dayjs (~2KB)
lodash        ~70KB   → lodash-es (tree-shakeable) or native Array methods
@mui/material ~500KB  → tree-shake: import Button from '@mui/material/Button'
recharts      ~450KB  → visx (~50KB per chart type)
```

## Code Splitting

```tsx
// Dynamic imports — loaded only when needed
import dynamic from 'next/dynamic';

const HeavyChart = dynamic(() => import('@/components/RevenueChart'), {
  loading: () => <ChartSkeleton />,
  ssr: false, // Skip SSR for client-only components
});

// Route-level splitting is automatic in App Router
// Each page.tsx is its own chunk
```

## Image Optimization

```tsx
import Image from 'next/image';

// GOOD — automatic WebP/AVIF, srcset, lazy loading
<Image
  src="/hero.jpg"
  alt="Hero image"
  width={1200}
  height={600}
  priority          // Above the fold — preload, no lazy loading
  sizes="(max-width: 768px) 100vw, 50vw"
  quality={80}
/>

// BAD — unoptimized, no srcset, no lazy loading
<img src="/hero.jpg" alt="Hero" />

// Remote images — configure in next.config.ts
// images: { remotePatterns: [{ hostname: 'cdn.example.com' }] }
```

## LCP Optimization

```tsx
// 1. Preload critical resources
<head>
  <link rel="preload" as="image" href="/hero.webp" />
  <link rel="preload" as="font" href="/fonts/inter.woff2" crossOrigin="" />
</head>

// 2. Priority flag on hero image
<Image src="/hero.webp" priority alt="Hero" width={1200} height={600} />

// 3. Avoid client-side rendering for above-the-fold
// Use Server Components for hero section — HTML in initial response

// 4. Font optimization
import { Inter } from 'next/font/google';
const inter = Inter({ subsets: ['latin'], display: 'swap' });
```

## CLS Prevention

```tsx
// Always set dimensions on images
<Image width={400} height={300} ... />

// Reserve space for dynamic content
<div style={{ minHeight: '200px' }}>
  <Suspense fallback={<Skeleton height={200} />}>
    <DynamicContent />
  </Suspense>
</div>

// Avoid inserting content above existing content
// Bad: banner that pushes page down after load
// Good: reserved slot with fixed height
```

## INP Optimization

```tsx
// 1. Debounce search input
const debouncedSearch = useDeferredValue(searchQuery);

// 2. Virtualize long lists
import { useVirtualizer } from '@tanstack/react-virtual';

function VirtualList({ items }: { items: Item[] }) {
  const parentRef = useRef<HTMLDivElement>(null);
  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 60,
  });

  return (
    <div ref={parentRef} style={{ height: '400px', overflow: 'auto' }}>
      <div style={{ height: virtualizer.getTotalSize() }}>
        {virtualizer.getVirtualItems().map((vi) => (
          <div key={vi.key} style={{
            position: 'absolute',
            top: vi.start,
            height: vi.size,
          }}>
            <ItemRow item={items[vi.index]} />
          </div>
        ))}
      </div>
    </div>
  );
}

// 3. Use startTransition for non-urgent updates
import { useTransition } from 'react';
const [isPending, startTransition] = useTransition();
startTransition(() => setFilteredResults(filtered));
```

## Quick Reference
```
LCP: <2.5s — preload hero, priority Image, Server Components above fold
CLS: <0.1 — set width/height on images, reserve space for dynamic content
INP: <200ms — virtualize lists, debounce inputs, startTransition
Bundle: ANALYZE=true next build — find and replace heavy deps
Images: next/image with priority for above-fold, sizes for responsive
Fonts: next/font with display: 'swap' — no FOIT
```
