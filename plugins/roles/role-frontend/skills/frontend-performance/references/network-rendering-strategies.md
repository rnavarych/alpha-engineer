# Network Optimization and Rendering Strategies

## When to load
Load when choosing a rendering strategy (SSR, SSG, RSC, Islands) or optimizing network resource loading (resource hints, HTTP/2, service workers, third-party scripts).

## Resource Hints

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

## HTTP/2 and HTTP/3

- **HTTP/2 multiplexing**: Multiple requests share a single TCP connection. No need to concatenate files.
- **HTTP/3 QUIC**: UDP-based. Eliminates head-of-line blocking. Enable on CDN (Cloudflare, AWS CloudFront).
- With HTTP/2+, serving many small files is preferred over few large bundles. Granular code splitting is a net positive.

## Service Workers (Workbox)

```typescript
import { precacheAndRoute } from 'workbox-precaching'
import { registerRoute } from 'workbox-routing'
import { CacheFirst, NetworkFirst, StaleWhileRevalidate } from 'workbox-strategies'
import { ExpirationPlugin } from 'workbox-expiration'

precacheAndRoute(self.__WB_MANIFEST)

// Cache-first for static assets (images, fonts)
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

// Stale-while-revalidate for documents
registerRoute(
  ({ request }) => request.destination === 'document',
  new StaleWhileRevalidate({ cacheName: 'pages' }),
)
```

## Rendering Strategies

| Strategy | When HTML is Generated | Best For |
|---|---|---|
| CSR (Client-Side) | In the browser | SPAs behind auth, dashboards |
| SSR (Server-Side) | On each request | Dynamic, SEO-critical pages |
| SSG (Static Generation) | At build time | Blogs, docs, marketing |
| ISR (Incremental Static) | At build + on-demand | E-commerce, large content sites |
| Streaming SSR | Progressively on request | Complex pages with slow data |
| Islands Architecture | Static HTML + interactive islands | Content-heavy sites (Astro) |
| React Server Components | Server (no client JS) | Next.js App Router |

```tsx
// Server Component (no client JS, direct data access)
async function ProductPage({ id }: { id: string }) {
  const product = await db.products.findById(id)
  return (
    <div>
      <h1>{product.name}</h1>
      <AddToCartButton product={product} />  {/* Client Component */}
    </div>
  )
}

// Islands Architecture (Astro)
// ---
// import Counter from '../components/Counter.tsx'
// ---
// <h1>Static content (zero JS)</h1>
// <Counter client:visible />   ← only this ships JS
```

## Third-Party Scripts

```html
<!-- Defer non-critical scripts -->
<script src="https://analytics.example.com/script.js" defer></script>

<!-- Move third-party scripts off the main thread via Partytown -->
<script type="text/partytown" src="https://analytics.example.com/script.js"></script>
```

### Facade Pattern

```tsx
// Show lightweight placeholder until interaction
function YouTubeEmbed({ videoId }: { videoId: string }) {
  const [loaded, setLoaded] = useState(false)
  if (!loaded) {
    return (
      <button
        onClick={() => setLoaded(true)}
        style={{ backgroundImage: `url(https://i.ytimg.com/vi/${videoId}/hqdefault.jpg)` }}
        aria-label="Play video"
      >
        <PlayIcon />
      </button>
    )
  }
  return <iframe src={`https://www.youtube.com/embed/${videoId}?autoplay=1`} />
}
```

- Measure third-party impact with `PerformanceObserver` for `entryTypes: ['resource']`.
