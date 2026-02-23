---
name: accessibility-expert
description: |
  Accessibility expertise including WCAG 2.1 AA/AAA compliance, ARIA roles and
  attributes, keyboard navigation, screen reader optimization, color contrast
  requirements, focus management, semantic HTML, and live regions.
allowed-tools: Read, Grep, Glob, Bash
---

# Accessibility Expert

## When to use
- Auditing or implementing WCAG 2.2 AA compliance
- Building interactive widgets (dialogs, tabs, comboboxes, accordions) with correct ARIA
- Implementing keyboard navigation with roving tabindex or focus traps
- Making forms accessible with error messages, live regions, and labels
- Managing focus after dynamic content changes (route navigation, modal open/close)
- Setting up automated a11y testing in CI with jest-axe or Playwright
- Checking legal requirements (ADA, EAA, Section 508, AODA)

## Core principles
1. **Native HTML first** — `<button>` beats `<div role="button">` every time; ARIA is a last resort
2. **Keyboard before mouse** — if it cannot be done with Tab/Enter/Space/Arrow/Escape, it is broken
3. **Focus must go somewhere** — every dynamic change (modal, route, delete) needs explicit focus management
4. **Color is never enough** — supplement every color signal with text, icon, or pattern
5. **Test with real screen readers** — axe catches ~30% of issues; NVDA and VoiceOver catch the rest

## Reference Files

- `references/wcag-aria-keyboard.md` — WCAG 2.2 AA/AAA requirements, landmark roles, dialog/tabs/combobox ARIA patterns, states reference table, roving tabindex implementation, focus trap, skip links
- `references/screen-readers-forms-focus.md` — live regions (polite/assertive), sr-only CSS, alt text strategy, accessible form error messages and validation, error summary, focus management after SPA navigation, accordion and tooltip patterns
- `references/testing-color-motion-legal.md` — color contrast ratios, touch target sizing, prefers-reduced-motion, semantic document structure, jest-axe and Playwright automated testing, Pa11y CI config, manual tool comparison, legal requirements table
