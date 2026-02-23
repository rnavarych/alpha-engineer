# Image and Font Optimization

## When to load
Load when optimizing images (formats, responsive, placeholders) or fonts (loading strategies, subsetting, font-display) to reduce page weight and eliminate CLS from resource loading.

## Image Format Selection

| Format | Compression | Browser Support | Best For |
|---|---|---|---|
| AVIF | Best (50% smaller than JPEG) | Chrome, Firefox, Safari 16.4+ | Photos, complex images |
| WebP | Good (25-35% smaller than JPEG) | All modern browsers | Universal fallback, photos |
| PNG | Lossless | Universal | Icons, screenshots, transparency |
| SVG | Vector (tiny for icons) | Universal | Icons, logos, illustrations |

## Responsive Images

```html
<!-- Resolution switching with srcset and sizes -->
<img
  srcset="photo-400.webp 400w, photo-800.webp 800w, photo-1200.webp 1200w, photo-1600.webp 1600w"
  sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
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

<Image
  src="/hero.jpg"
  alt="Hero banner"
  width={1200}
  height={600}
  priority           // for LCP images (disables lazy loading)
  placeholder="blur"
  blurDataURL={blurHash}
  sizes="(max-width: 768px) 100vw, 50vw"
/>
```

### Placeholder Strategies

- **BlurHash / LQIP**: Generate a tiny base64 blur at build time. Prevents CLS, improves perceived performance.
- **Dominant color**: Extract dominant color as CSS background. Simpler than blur, still prevents CLS.
- **Skeleton**: CSS skeleton shimmer for non-photo content areas.

## Font Loading

```css
/* Self-hosted font with optimal loading */
@font-face {
  font-family: 'Inter';
  src: url('/fonts/Inter-Regular.woff2') format('woff2');
  font-weight: 400;
  font-style: normal;
  font-display: swap;
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

body { font-family: 'Inter', 'Inter Fallback', system-ui, sans-serif; }
```

```html
<!-- Preload critical fonts -->
<link rel="preload" href="/fonts/Inter-Regular.woff2" as="font" type="font/woff2" crossorigin />
```

### font-display Values

| Value | Behavior | Use For |
|---|---|---|
| `swap` | Shows fallback immediately, swaps when ready | Body text (no invisible text) |
| `optional` | Shows fallback, only swaps if fast load | Hero text (minimizes CLS) |
| `fallback` | Brief invisible period (100ms), then fallback | Balance between swap and optional |
| `block` | Invisible up to 3s, then fallback | Icon fonts (avoid wrong glyphs) |

### Font Subsetting

```bash
# Using pyftsubset (fonttools)
pyftsubset Inter-Regular.ttf \
  --output-file=Inter-Regular-Latin.woff2 \
  --flavor=woff2 \
  --layout-features='kern,liga' \
  --unicodes=U+0000-00FF,U+2000-206F
```

- Latin-only subsets are 70-90% smaller than full Unicode fonts.
- Use variable fonts instead of multiple weight files. One file replaces regular, medium, semibold, and bold.
- Limit font families and weights — each variant is a separate file.
