# Screen Readers, Forms, and Focus Management

## When to load
Load when implementing accessible forms (error messages, validation, live regions), managing focus programmatically after dynamic content changes, or testing with screen readers.

## Screen Reader Support

- Test with VoiceOver (macOS/iOS), NVDA (Windows, free), and JAWS (Windows, enterprise). Each behaves differently.

### Live Regions and Announcements

```typescript
function announce(message: string, priority: 'polite' | 'assertive' = 'polite') {
  const region = document.getElementById(`sr-${priority}`)!
  region.textContent = ''
  requestAnimationFrame(() => { region.textContent = message })
}
```

```html
<!-- Must exist in DOM before content is injected -->
<div id="sr-polite" aria-live="polite" class="sr-only"></div>
<div id="sr-assertive" aria-live="assertive" class="sr-only"></div>
```

```css
.sr-only {
  position: absolute; width: 1px; height: 1px; padding: 0;
  margin: -1px; overflow: hidden; clip: rect(0, 0, 0, 0);
  white-space: nowrap; border: 0;
}
```

- `aria-live="polite"` for non-urgent updates (toasts, item counts).
- `aria-live="assertive"` for urgent updates (errors, session timeout).
- Use `role="status"` (implicit polite) or `role="alert"` (implicit assertive).
- Use `aria-atomic="true"` when entire region content should be announced, not just changed text.

### Alt Text Strategy

| Image Type | Alt Text |
|---|---|
| Informative | Describe content: `alt="Bar chart showing sales up 23% in Q3"` |
| Decorative | Empty: `alt=""` (do not omit the attribute) |
| Functional (link/button) | Describe action: `alt="Search"`, `alt="Close dialog"` |
| Complex (chart/diagram) | Brief alt + linked long description |

## Accessible Forms

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

```typescript
// Announce on blur, not on every keystroke
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
input.addEventListener('blur', () => validateField(input))
```

### Error Summary (after failed submission)

```html
<!-- Focus this element after form submission with errors -->
<div role="alert" tabindex="-1" id="error-summary">
  <h2>There are 3 errors in the form</h2>
  <ul>
    <li><a href="#email">Email address is required</a></li>
    <li><a href="#password">Password must be at least 8 characters</a></li>
  </ul>
</div>
```

- Every form input needs an associated `<label>` with `for`/`id` pairing. Placeholder is not a substitute.
- Group related fields with `<fieldset>` and `<legend>`.

## Focus Management

```css
:focus-visible { outline: 2px solid var(--color-focus); outline-offset: 2px; }
:focus:not(:focus-visible) { outline: none; }
```

- Never use `outline: none` without providing a replacement.
- Custom focus indicators must have 3:1 contrast ratio against adjacent colors (WCAG 2.4.11).

```typescript
// SPA route change — move focus to main heading
router.afterEach((to) => {
  nextTick(() => {
    const main = document.querySelector('main h1') as HTMLElement
    if (main) { main.setAttribute('tabindex', '-1'); main.focus() }
    document.title = to.meta.title as string
  })
})

// Accessible modal
function openModal(dialog: HTMLDialogElement, triggerEl: HTMLElement) {
  dialog.showModal()  // native <dialog> handles focus trap
  dialog.addEventListener('close', () => triggerEl.focus(), { once: true })
}
```

- After deleting a list item, move focus to the next item, previous item, or summary heading.
- After SPA navigation, move focus to the main heading or main content area.

## Component Patterns

```html
<!-- Accordion -->
<h3>
  <button aria-expanded="false" aria-controls="section-1-content" id="section-1-header">Section 1</button>
</h3>
<div role="region" id="section-1-content" aria-labelledby="section-1-header" hidden>
  <p>Content...</p>
</div>

<!-- Tooltip -->
<button aria-describedby="tooltip-1">
  Settings
  <span role="tooltip" id="tooltip-1" class="tooltip">Configure application preferences</span>
</button>
```
