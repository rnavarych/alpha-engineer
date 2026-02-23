# A11y Testing, Color, Motion, and Legal

## When to load
Load when setting up automated accessibility testing (jest-axe, Playwright, Pa11y CI), checking color contrast, implementing reduced-motion, or understanding legal compliance requirements.

## Color and Contrast

- **AA minimum**: 4.5:1 for normal text; 3:1 for large text (18pt+ or 14pt+ bold); 3:1 for UI components.
- **AAA enhanced**: 7:1 for normal text; 4.5:1 for large text. Target for body text and critical UI.
- Test with Chrome DevTools Accessibility pane, axe DevTools, or Colour Contrast Analyser.
- Do not rely on color alone to convey meaning. Supplement with icons, text labels, or underlines.

```html
<!-- Bad: color only -->
<span style="color: red">Error</span>

<!-- Good: color + icon + text -->
<span class="error">
  <svg aria-hidden="true"><!-- error icon --></svg>
  Error: Password is too short
</span>
```

## Touch Targets

```css
/* WCAG 2.5.5 AAA: 44×44px. WCAG 2.5.8 AA: 24×24px */
.touch-target { min-width: 44px; min-height: 44px; display: inline-flex; align-items: center; justify-content: center; }
.button-group > * + * { margin-left: 8px; }
```

## Motion and Animation

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

```typescript
const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches

function animateElement(el: HTMLElement) {
  if (prefersReducedMotion) { el.style.opacity = '1'; return }
  el.animate([{ opacity: 0 }, { opacity: 1 }], { duration: 300 })
}
```

- Auto-playing content: provide pause/stop/hide controls for content that moves for more than 5 seconds.
- Avoid flashing more than 3 times per second (WCAG 2.3.1 — seizure risk).

## Semantic HTML Document Structure

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Page Title - Site Name</title>
</head>
<body>
  <a href="#main" class="skip-link">Skip to main content</a>
  <header><nav aria-label="Primary">...</nav></header>
  <main id="main" tabindex="-1">
    <h1>Page Title</h1>
  </main>
  <aside aria-label="Related articles">...</aside>
  <footer><nav aria-label="Footer">...</nav></footer>
</body>
</html>
```

- Use `<button>` for actions, `<a>` for navigation, `<details>` for disclosure, `<dialog>` for modals.
- Heading hierarchy must not skip levels. Each page has exactly one `<h1>`.

## Automated Testing

```typescript
// jest-axe: unit test accessibility
import { axe, toHaveNoViolations } from 'jest-axe'
expect.extend(toHaveNoViolations)

it('should have no accessibility violations', async () => {
  const { container } = render(<LoginForm />)
  const results = await axe(container)
  expect(results).toHaveNoViolations()
})

// Playwright accessibility assertions
test('page is accessible', async ({ page }) => {
  await page.goto('/')
  const results = await new AxeBuilder({ page }).analyze()
  expect(results.violations).toEqual([])
})
```

```json
// Pa11y CI (.pa11yci.json)
{
  "defaults": { "standard": "WCAG2AA", "runners": ["axe"] },
  "urls": ["http://localhost:3000/", "http://localhost:3000/login"]
}
```

### Manual Testing Tools

| Tool | Type | Use For |
|---|---|---|
| axe DevTools | Browser extension | Quick page audits |
| WAVE | Browser extension | Visual overlay of issues |
| Lighthouse | Chrome built-in | Scoring and recommendations |
| NVDA | Screen reader (Windows, free) | Free screen reader testing |
| VoiceOver | Screen reader (macOS/iOS) | Built-in Apple screen reader |
| JAWS | Screen reader (Windows) | Enterprise screen reader |

## Legal Requirements

| Regulation | Region | Requirements |
|---|---|---|
| ADA | United States | Courts reference WCAG 2.1 AA |
| Section 508 | US Federal | WCAG 2.0 AA for federal agencies |
| EAA | EU | WCAG 2.1 AA, enforcement began June 2025 |
| AODA | Ontario, Canada | WCAG 2.0 AA |

- **VPAT/ACR**: Required for selling to US government and many enterprises.
- EAA covers e-commerce, banking, transportation, and telecommunications in the EU.
