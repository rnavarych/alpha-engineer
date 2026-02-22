---
name: accessibility-expert
description: |
  Accessibility expertise including WCAG 2.1 AA/AAA compliance, ARIA roles and
  attributes, keyboard navigation, screen reader optimization, color contrast
  requirements, focus management, semantic HTML, and live regions.
allowed-tools: Read, Grep, Glob, Bash
---

# Accessibility Expert

## WCAG 2.2 Compliance

### Level A (Minimum)

- **1.1.1 Non-text Content**: All images, icons, and graphics have text alternatives (`alt`, `aria-label`, or `aria-labelledby`).
- **1.3.1 Info and Relationships**: Structure and relationships conveyed visually are available programmatically (headings, lists, tables, form labels).
- **2.1.1 Keyboard**: All functionality is operable through a keyboard interface.
- **2.4.1 Bypass Blocks**: Provide skip navigation links to bypass repeated content.
- **3.1.1 Language of Page**: The default human language of the page is set via `<html lang="en">`.
- **4.1.2 Name, Role, Value**: All UI components have accessible names, roles, and states.

### Level AA (Baseline Target)

- **Perceivable**: All non-text content has text alternatives. Video has captions. Content is adaptable and distinguishable. Color is not the sole means of conveying information.
- **Operable**: All functionality is available from the keyboard. Users have enough time to read and interact. Content does not cause seizures. Navigation is consistent and predictable.
- **Understandable**: Text is readable. Pages behave predictably. Users are helped to avoid and correct errors with clear messaging.
- **Robust**: Content is compatible with current and future assistive technologies. Valid HTML and proper ARIA usage.
- **1.4.3 Contrast (Minimum)**: 4.5:1 for normal text, 3:1 for large text (18pt+ or 14pt+ bold).
- **1.4.11 Non-text Contrast**: 3:1 contrast ratio for UI components and graphical objects.
- **2.4.7 Focus Visible**: Keyboard focus indicator is visible on all interactive elements.
- **2.5.8 Target Size (Minimum)** (WCAG 2.2): Touch targets at least 24x24 CSS pixels, with exceptions for inline text links and browser-native controls.

### Level AAA (Critical Flows)

- Enhanced color contrast (7:1 for normal text, 4.5:1 for large text).
- Sign language interpretation for prerecorded audio. Extended audio descriptions.
- No timing limits on user interactions. No interruptions except emergencies.
- Apply AAA to login, checkout, medical forms, and legal agreement flows.

## ARIA Roles, States, and Properties

### First Rule of ARIA

- Do not use ARIA if a native HTML element provides the semantics. `<button>` is always better than `<div role="button">`.
- Using ARIA incorrectly is worse than not using it at all.

### Landmark Roles

```html
<header>         <!-- implicit role="banner" -->
<nav>            <!-- implicit role="navigation" -->
<main>           <!-- implicit role="main" -->
<aside>          <!-- implicit role="complementary" -->
<footer>         <!-- implicit role="contentinfo" -->
<form role="search">  <!-- search landmark -->

<!-- Label multiple landmarks of the same type -->
<nav aria-label="Primary">...</nav>
<nav aria-label="Footer">...</nav>
```

### Widget Patterns

#### Dialog Pattern

```html
<div role="dialog" aria-modal="true" aria-labelledby="dialog-title">
  <h2 id="dialog-title">Confirm Deletion</h2>
  <p id="dialog-desc">This action cannot be undone.</p>
  <div aria-describedby="dialog-desc">
    <button>Cancel</button>
    <button>Delete</button>
  </div>
</div>
```

#### Tabs Pattern

```html
<div role="tablist" aria-label="Account settings">
  <button role="tab" id="tab-1" aria-selected="true" aria-controls="panel-1">Profile</button>
  <button role="tab" id="tab-2" aria-selected="false" aria-controls="panel-2" tabindex="-1">Security</button>
</div>
<div role="tabpanel" id="panel-1" aria-labelledby="tab-1">
  <!-- Profile content -->
</div>
<div role="tabpanel" id="panel-2" aria-labelledby="tab-2" hidden>
  <!-- Security content -->
</div>
```

#### Combobox Pattern

```html
<label for="city-input">City</label>
<div role="combobox" aria-expanded="true" aria-haspopup="listbox" aria-owns="city-listbox">
  <input id="city-input" type="text" aria-autocomplete="list" aria-controls="city-listbox"
         aria-activedescendant="city-option-2" />
</div>
<ul role="listbox" id="city-listbox">
  <li role="option" id="city-option-1">New York</li>
  <li role="option" id="city-option-2" aria-selected="true">Los Angeles</li>
  <li role="option" id="city-option-3">Chicago</li>
</ul>
```

### States and Properties

| Attribute | Purpose | Example |
|---|---|---|
| `aria-expanded` | Indicates expandable state | Accordion, dropdown, tree node |
| `aria-selected` | Indicates selection | Tabs, listbox options |
| `aria-checked` | Indicates checked state | Checkboxes, toggle switches |
| `aria-disabled` | Indicates disabled (still focusable) | Disabled buttons with tooltip |
| `aria-hidden` | Removes from accessibility tree | Decorative icons, visual duplicates |
| `aria-current` | Indicates current item in set | Current page in nav, current step |
| `aria-invalid` | Indicates validation error | Form fields with errors |
| `aria-busy` | Content is loading/updating | Loading table, updating region |

- `aria-label` provides an accessible name when visible text is absent. `aria-labelledby` references a visible element as the label. `aria-describedby` provides supplementary description.
- Never set `aria-hidden="true"` on focusable elements. Use `inert` attribute to remove entire DOM subtrees from the accessibility tree and tab order.

## Keyboard Navigation

- Every interactive element must be reachable and operable with the keyboard alone: Tab, Shift+Tab, Enter, Space, Arrow keys, Escape.
- Use `tabindex="0"` to add custom elements to the tab order. Use `tabindex="-1"` for programmatic focus (dialogs, error summaries). Never use `tabindex` values greater than 0.

### Roving Tabindex

```typescript
// Only one item in the group has tabindex="0"; arrow keys move it
function handleKeyDown(event: KeyboardEvent, items: HTMLElement[], currentIndex: number) {
  let nextIndex = currentIndex
  switch (event.key) {
    case 'ArrowDown':
    case 'ArrowRight':
      nextIndex = (currentIndex + 1) % items.length
      break
    case 'ArrowUp':
    case 'ArrowLeft':
      nextIndex = (currentIndex - 1 + items.length) % items.length
      break
    case 'Home':
      nextIndex = 0
      break
    case 'End':
      nextIndex = items.length - 1
      break
    default:
      return
  }
  event.preventDefault()
  items[currentIndex].setAttribute('tabindex', '-1')
  items[nextIndex].setAttribute('tabindex', '0')
  items[nextIndex].focus()
}
```

### Focus Trap

```typescript
function trapFocus(container: HTMLElement) {
  const focusable = container.querySelectorAll<HTMLElement>(
    'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
  )
  const first = focusable[0]
  const last = focusable[focusable.length - 1]

  container.addEventListener('keydown', (e) => {
    if (e.key !== 'Tab') return
    if (e.shiftKey && document.activeElement === first) {
      e.preventDefault()
      last.focus()
    } else if (!e.shiftKey && document.activeElement === last) {
      e.preventDefault()
      first.focus()
    }
  })

  first.focus()
}
```

### Skip Links

```html
<a href="#main-content" class="skip-link">Skip to main content</a>
<!-- ... navigation ... -->
<main id="main-content" tabindex="-1">
  <!-- page content -->
</main>

<style>
.skip-link {
  position: absolute;
  top: -100%;
  left: 0;
  z-index: 100;
  padding: 8px 16px;
  background: var(--color-primary);
  color: white;
}
.skip-link:focus {
  top: 0;
}
</style>
```

- Implement arrow key navigation within composite widgets (tabs, menus, toolbars, listboxes) using roving tabindex or `aria-activedescendant`.
- Trap focus inside modal dialogs. When a dialog opens, focus the first focusable element. When it closes, return focus to the trigger element.

## Screen Reader Support

- Test with VoiceOver (macOS/iOS), NVDA (Windows, free), and JAWS (Windows, enterprise). Each has different behavior.

### Accessible Announcements

```typescript
// Visually hidden live region for announcements
function announce(message: string, priority: 'polite' | 'assertive' = 'polite') {
  const region = document.getElementById(`sr-${priority}`)!
  region.textContent = ''
  // Reset forces re-announcement of identical messages
  requestAnimationFrame(() => {
    region.textContent = message
  })
}
```

```html
<!-- Pre-existing live regions (must exist before content injection) -->
<div id="sr-polite" aria-live="polite" class="sr-only"></div>
<div id="sr-assertive" aria-live="assertive" class="sr-only"></div>
```

### Visually Hidden Text

```css
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}
```

### Alt Text Best Practices

| Image Type | Alt Text Strategy |
|---|---|
| Informative | Describe content: `alt="Bar chart showing sales up 23% in Q3"` |
| Decorative | Empty alt: `alt=""` (do not omit the attribute) |
| Functional (link/button) | Describe action: `alt="Search"`, `alt="Close dialog"` |
| Complex (chart/diagram) | Brief alt + linked long description |
| Text in image | Reproduce the text in alt |

- Ensure every form input has an associated `<label>` element using `for`/`id` pairing. Placeholder text is not a substitute for a label.
- Group related form fields with `<fieldset>` and `<legend>`. Use `aria-required` or the `required` attribute for mandatory fields.

## Forms Accessibility

### Error Messages

```html
<div class="form-group">
  <label for="email">Email address <span aria-hidden="true">*</span></label>
  <input id="email" type="email" required
         aria-required="true"
         aria-invalid="true"
         aria-describedby="email-error email-hint" />
  <span id="email-hint" class="hint">We will never share your email.</span>
  <span id="email-error" class="error" role="alert">
    Please enter a valid email address.
  </span>
</div>
```

### Inline Validation Announcements

```typescript
function validateField(input: HTMLInputElement) {
  const errorEl = document.getElementById(`${input.id}-error`)!
  if (!input.validity.valid) {
    input.setAttribute('aria-invalid', 'true')
    errorEl.textContent = input.validationMessage
  } else {
    input.removeAttribute('aria-invalid')
    errorEl.textContent = ''
  }
}

// Announce on blur, not on every keystroke
input.addEventListener('blur', () => validateField(input))
```

### Error Summary

```html
<!-- After form submission with errors, focus this element -->
<div role="alert" tabindex="-1" id="error-summary">
  <h2>There are 3 errors in the form</h2>
  <ul>
    <li><a href="#email">Email address is required</a></li>
    <li><a href="#password">Password must be at least 8 characters</a></li>
    <li><a href="#terms">You must accept the terms</a></li>
  </ul>
</div>
```

## Color and Contrast

- **AA minimum**: 4.5:1 contrast ratio for normal text (below 18pt/14pt bold). 3:1 for large text (18pt+ or 14pt+ bold). 3:1 for UI components and graphical elements.
- **AAA enhanced**: 7:1 for normal text, 4.5:1 for large text. Target AAA for body text and critical UI elements.
- Test contrast with browser DevTools (Chrome Accessibility pane), axe DevTools, or Colour Contrast Analyser.
- Do not rely on color alone to convey meaning. Supplement with icons, text labels, patterns, or underlines.

```html
<!-- Bad: color only -->
<span style="color: red">Error</span>

<!-- Good: color + icon + text -->
<span class="error">
  <svg aria-hidden="true"><!-- error icon --></svg>
  Error: Password is too short
</span>
```

- Ensure contrast is maintained in both light and dark themes. Retest all color combinations when adding or switching themes.

## Motion and Animation

```css
/* Respect user preference for reduced motion */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

- Auto-playing content: Provide pause, stop, or hide controls for any content that moves, blinks, or scrolls for more than 5 seconds.
- Avoid flashing content that flashes more than 3 times per second (seizure risk, WCAG 2.3.1).
- Animation timing: Provide enough time for users to perceive and react. Avoid animations that last less than 100ms or more than 5s for transitions.

```typescript
// Check user preference in JavaScript
const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches

function animateElement(el: HTMLElement) {
  if (prefersReducedMotion) {
    // Skip animation, apply final state directly
    el.style.opacity = '1'
    return
  }
  el.animate([{ opacity: 0 }, { opacity: 1 }], { duration: 300 })
}
```

## Focus Management

- All focusable elements must have a visible focus indicator. The default browser outline is acceptable; custom indicators must have a 3:1 contrast ratio against adjacent colors (WCAG 2.4.11).

```css
/* Custom focus indicator */
:focus-visible {
  outline: 2px solid var(--color-focus);
  outline-offset: 2px;
}

/* Remove for mouse users, keep for keyboard */
:focus:not(:focus-visible) {
  outline: none;
}
```

- Never use `outline: none` without providing a replacement.
- Manage focus programmatically during dynamic content changes: move focus to new content after route navigation, modal opening, or inline content insertion.
- After a destructive action (deleting a list item), move focus to a logical place: the next item, the previous item, or a summary heading.
- After SPA route navigation, move focus to the main heading or the main content area.

```typescript
// SPA route change focus management
router.afterEach((to) => {
  nextTick(() => {
    const main = document.querySelector('main h1') as HTMLElement
    if (main) {
      main.setAttribute('tabindex', '-1')
      main.focus()
    }
    document.title = to.meta.title as string
  })
})
```

## Semantic HTML

- Use the correct element: `<button>` for actions, `<a>` for navigation, `<input>` for data entry, `<select>` for choice lists, `<details>` for disclosure, `<dialog>` for modals.
- Structure content with heading hierarchy (`<h1>` through `<h6>`). Do not skip heading levels. Each page should have exactly one `<h1>`.
- Use `<ul>`/`<ol>` for lists of items. Screen readers announce the list length.
- Use `<time datetime="...">` for dates and times. Use `<abbr title="...">` for abbreviations.
- Use `<figure>` and `<figcaption>` for images, charts, and diagrams with descriptive captions.

### Document Structure Checklist

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Page Title - Site Name</title>   <!-- unique, descriptive -->
</head>
<body>
  <a href="#main" class="skip-link">Skip to main content</a>
  <header>
    <nav aria-label="Primary">...</nav>
  </header>
  <main id="main" tabindex="-1">
    <h1>Page Title</h1>
    <!-- content with proper heading hierarchy -->
  </main>
  <aside aria-label="Related articles">...</aside>
  <footer>
    <nav aria-label="Footer">...</nav>
  </footer>
</body>
</html>
```

## Live Regions

- Use `aria-live="polite"` for non-urgent updates (toast notifications, status changes, item counts).
- Use `aria-live="assertive"` for urgent updates (error alerts, session timeout warnings).
- Use `role="status"` (implicit `aria-live="polite"`) for status messages. Use `role="alert"` (implicit `aria-live="assertive"`) for error/warning alerts.
- The live region element must exist in the DOM before content is injected into it.
- Use `aria-atomic="true"` when the entire region content should be announced, not just the changed text.

## Accessible Component Patterns

### Accessible Modal

```typescript
function openModal(dialog: HTMLDialogElement, triggerEl: HTMLElement) {
  dialog.showModal()  // native <dialog> handles focus trap
  dialog.addEventListener('close', () => {
    triggerEl.focus() // return focus to trigger
  }, { once: true })
}
```

### Accessible Dropdown Menu

- Enter/Space opens the menu. Arrow keys navigate items. Escape closes the menu and returns focus to the trigger.
- Use `role="menu"`, `role="menuitem"`, `aria-expanded`, `aria-haspopup`.

### Accessible Accordion

```html
<div class="accordion">
  <h3>
    <button aria-expanded="false" aria-controls="section-1-content" id="section-1-header">
      Section 1
    </button>
  </h3>
  <div role="region" id="section-1-content" aria-labelledby="section-1-header" hidden>
    <p>Section content...</p>
  </div>
</div>
```

### Accessible Tooltip

```html
<button aria-describedby="tooltip-1">
  Settings
  <span role="tooltip" id="tooltip-1" class="tooltip">Configure application preferences</span>
</button>
```

## Touch Targets

- Minimum touch target size: 44x44 CSS pixels (WCAG 2.5.5 AAA) or 24x24 CSS pixels (WCAG 2.5.8 AA, WCAG 2.2).
- Ensure adequate spacing between adjacent touch targets to prevent accidental activation.
- Mobile accessibility: test with screen readers on iOS (VoiceOver) and Android (TalkBack).

```css
/* Minimum touch target */
.touch-target {
  min-width: 44px;
  min-height: 44px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

/* Spacing between adjacent targets */
.button-group > * + * {
  margin-left: 8px;
}
```

## Testing Tools and Automation

### Manual Testing Tools

| Tool | Type | Use For |
|---|---|---|
| axe DevTools | Browser extension | Quick page audits, issue identification |
| WAVE | Browser extension | Visual overlay of accessibility issues |
| Lighthouse | Built into Chrome | Automated scoring and recommendations |
| Colour Contrast Analyser | Desktop app | Precise color contrast measurement |
| NVDA | Screen reader (Windows) | Free screen reader testing |
| VoiceOver | Screen reader (macOS/iOS) | Built-in Apple screen reader |
| JAWS | Screen reader (Windows) | Enterprise screen reader |

### Automated Testing

```typescript
// jest-axe: Unit test accessibility
import { axe, toHaveNoViolations } from 'jest-axe'
expect.extend(toHaveNoViolations)

it('should have no accessibility violations', async () => {
  const { container } = render(<LoginForm />)
  const results = await axe(container)
  expect(results).toHaveNoViolations()
})

// cypress-axe: E2E accessibility testing
describe('Home page', () => {
  it('passes axe audit', () => {
    cy.visit('/')
    cy.injectAxe()
    cy.checkA11y(null, {
      rules: { 'color-contrast': { enabled: true } },
    })
  })
})

// Playwright accessibility assertions
test('page is accessible', async ({ page }) => {
  await page.goto('/')
  const snapshot = await page.accessibility.snapshot()
  // or use @axe-core/playwright
  const results = await new AxeBuilder({ page }).analyze()
  expect(results.violations).toEqual([])
})
```

### CI Integration

```yaml
# Pa11y CI configuration (.pa11yci.json)
{
  "defaults": {
    "standard": "WCAG2AA",
    "runners": ["axe"],
    "chromeLaunchConfig": { "args": ["--no-sandbox"] }
  },
  "urls": [
    "http://localhost:3000/",
    "http://localhost:3000/login",
    "http://localhost:3000/dashboard"
  ]
}
```

## Legal Requirements

| Regulation | Region | Requirements |
|---|---|---|
| ADA (Americans with Disabilities Act) | United States | No specific standard; courts reference WCAG 2.1 AA |
| Section 508 | US Federal | WCAG 2.0 AA for federal agencies and contractors |
| EAA (European Accessibility Act) | EU | WCAG 2.1 AA, enforcement begins June 2025 |
| AODA | Ontario, Canada | WCAG 2.0 AA |
| EN 301 549 | EU | Technical standard referencing WCAG 2.1 |

- **VPAT/ACR**: Voluntary Product Accessibility Template / Accessibility Conformance Report. Required for selling to US government and many enterprises. Document conformance level for each WCAG criterion.
- EAA enforcement begins June 28, 2025. All digital products and services in the EU must comply with WCAG 2.1 AA. This includes e-commerce, banking, transportation, and telecommunications.
