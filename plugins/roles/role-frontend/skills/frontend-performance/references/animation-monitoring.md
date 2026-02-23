# Animation Performance and Monitoring

## When to load
Load when implementing performant animations (GPU-accelerated, View Transitions, layout thrashing) or setting up performance monitoring (Lighthouse CI, budgets, anti-patterns).

## GPU-Accelerated Animation

- Animate only `transform` and `opacity` for 60fps. These run on the compositor thread, avoiding layout and paint.

```css
/* Good: GPU-accelerated */
.card:hover {
  transform: translateY(-4px) scale(1.02);
  opacity: 0.95;
}

/* Bad: triggers layout and paint */
.card:hover {
  top: -4px;       /* triggers layout */
  width: 102%;     /* triggers layout */
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
if (document.startViewTransition) {
  document.startViewTransition(() => updateDOM())
} else {
  updateDOM()
}
```

```css
::view-transition-old(root) { animation: fade-out 200ms ease-out; }
::view-transition-new(root) { animation: fade-in 200ms ease-in; }

/* Named transitions for specific elements */
.hero-image { view-transition-name: hero; }
```

## Lighthouse CI

```js
// lighthouserc.js
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
    upload: { target: 'temporary-public-storage' },
  },
}
```

## Anti-Patterns

| Anti-Pattern | Problem | Solution |
|---|---|---|
| Lazy-loading the LCP image | Delays largest paint | Use `loading="eager"` + `fetchpriority="high"` |
| No image dimensions | Causes layout shifts (CLS) | Always set `width`/`height` or `aspect-ratio` |
| Synchronous third-party scripts | Blocks rendering | Use `async`/`defer`, Partytown, or facade pattern |
| Manual memoization everywhere | Code noise, often wrong deps | Use React Compiler, or memo only measured bottlenecks |
| Animating layout properties | Janky animations | Animate `transform` and `opacity` only |
| No performance budget | Silent regression | `size-limit` or Lighthouse CI in CI pipeline |
| Loading all fonts upfront | Slow first paint | Subset fonts, use `font-display`, preload critical only |
| Full hydration on static pages | Unnecessary JavaScript | Islands architecture (Astro), RSC, partial hydration |
