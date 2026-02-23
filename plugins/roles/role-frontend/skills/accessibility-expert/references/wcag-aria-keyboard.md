# WCAG Compliance, ARIA, and Keyboard Navigation

## When to load
Load when implementing WCAG 2.2 AA/AAA compliance, adding ARIA roles/states/properties, or building keyboard-navigable interactive widgets.

## WCAG 2.2 Key Requirements

### Level AA (Baseline Target)
- **1.4.3 Contrast**: 4.5:1 for normal text, 3:1 for large text (18pt+ or 14pt+ bold)
- **1.4.11 Non-text Contrast**: 3:1 for UI components and graphical objects
- **2.4.7 Focus Visible**: Keyboard focus indicator visible on all interactive elements
- **2.5.8 Target Size** (WCAG 2.2): Touch targets at least 24×24 CSS pixels
- **4.1.2 Name, Role, Value**: All UI components have accessible names, roles, and states
- **1.3.1 Info and Relationships**: Structure conveyed visually available programmatically
- **2.1.1 Keyboard**: All functionality operable via keyboard

### Level AAA (Critical Flows)
- Enhanced contrast: 7:1 for normal text, 4.5:1 for large text
- Apply AAA to login, checkout, medical forms, and legal agreement flows

## First Rule of ARIA

- Do not use ARIA if a native HTML element provides the semantics. `<button>` is always better than `<div role="button">`.
- Using ARIA incorrectly is worse than not using it at all.

## Landmark Roles

```html
<header>   <!-- role="banner" -->
<nav>      <!-- role="navigation" -->
<main>     <!-- role="main" -->
<aside>    <!-- role="complementary" -->
<footer>   <!-- role="contentinfo" -->

<!-- Label multiple landmarks of same type -->
<nav aria-label="Primary">...</nav>
<nav aria-label="Footer">...</nav>
```

## Widget Patterns

```html
<!-- Dialog -->
<div role="dialog" aria-modal="true" aria-labelledby="dialog-title">
  <h2 id="dialog-title">Confirm Deletion</h2>
  <button>Cancel</button>
  <button>Delete</button>
</div>

<!-- Tabs -->
<div role="tablist" aria-label="Account settings">
  <button role="tab" id="tab-1" aria-selected="true" aria-controls="panel-1">Profile</button>
  <button role="tab" id="tab-2" aria-selected="false" aria-controls="panel-2" tabindex="-1">Security</button>
</div>
<div role="tabpanel" id="panel-1" aria-labelledby="tab-1"><!-- content --></div>
```

## ARIA States Reference

| Attribute | Purpose | Example |
|---|---|---|
| `aria-expanded` | Expandable state | Accordion, dropdown |
| `aria-selected` | Selection | Tabs, listbox options |
| `aria-checked` | Checked state | Checkboxes, toggles |
| `aria-disabled` | Disabled (still focusable) | Buttons with tooltip |
| `aria-hidden` | Removes from a11y tree | Decorative icons |
| `aria-current` | Current item in set | Active nav link, step |
| `aria-invalid` | Validation error | Form fields with errors |
| `aria-busy` | Content is loading | Updating regions |

- Never set `aria-hidden="true"` on focusable elements. Use `inert` to remove entire subtrees.

## Keyboard Navigation

```typescript
// Roving tabindex: one item has tabindex="0", arrow keys move it
function handleKeyDown(event: KeyboardEvent, items: HTMLElement[], currentIndex: number) {
  let nextIndex = currentIndex
  switch (event.key) {
    case 'ArrowDown': case 'ArrowRight': nextIndex = (currentIndex + 1) % items.length; break
    case 'ArrowUp': case 'ArrowLeft': nextIndex = (currentIndex - 1 + items.length) % items.length; break
    case 'Home': nextIndex = 0; break
    case 'End': nextIndex = items.length - 1; break
    default: return
  }
  event.preventDefault()
  items[currentIndex].setAttribute('tabindex', '-1')
  items[nextIndex].setAttribute('tabindex', '0')
  items[nextIndex].focus()
}

// Focus trap for modals
function trapFocus(container: HTMLElement) {
  const focusable = container.querySelectorAll<HTMLElement>(
    'a[href], button:not([disabled]), input:not([disabled]), [tabindex]:not([tabindex="-1"])'
  )
  const first = focusable[0]
  const last = focusable[focusable.length - 1]
  container.addEventListener('keydown', (e) => {
    if (e.key !== 'Tab') return
    if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus() }
    else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus() }
  })
  first.focus()
}
```

## Skip Links

```html
<a href="#main-content" class="skip-link">Skip to main content</a>
<main id="main-content" tabindex="-1"><!-- content --></main>

<style>
.skip-link { position: absolute; top: -100%; left: 0; z-index: 100; padding: 8px 16px; background: var(--color-primary); color: white; }
.skip-link:focus { top: 0; }
</style>
```

- Use `tabindex="0"` to add custom elements to tab order. Use `tabindex="-1"` for programmatic focus. Never use `tabindex > 0`.
- Trap focus inside modal dialogs. Return focus to the trigger element when dialog closes.
