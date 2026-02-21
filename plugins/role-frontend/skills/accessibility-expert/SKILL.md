---
name: accessibility-expert
description: |
  Accessibility expertise including WCAG 2.1 AA/AAA compliance, ARIA roles and
  attributes, keyboard navigation, screen reader optimization, color contrast
  requirements, focus management, semantic HTML, and live regions.
allowed-tools: Read, Grep, Glob, Bash
---

# Accessibility Expert

## WCAG 2.1 Compliance

### AA Requirements (Baseline)
- **Perceivable**: All non-text content has text alternatives. Video has captions. Content is adaptable and distinguishable. Color is not the sole means of conveying information.
- **Operable**: All functionality is available from the keyboard. Users have enough time to read and interact. Content does not cause seizures. Navigation is consistent and predictable.
- **Understandable**: Text is readable. Pages behave predictably. Users are helped to avoid and correct errors with clear messaging.
- **Robust**: Content is compatible with current and future assistive technologies. Valid HTML and proper ARIA usage.

### AAA Targets (Critical Flows)
- Enhanced color contrast (7:1 for normal text, 4.5:1 for large text).
- Sign language interpretation for prerecorded audio. Extended audio descriptions.
- No timing limits on user interactions. No interruptions except emergencies.
- Apply AAA to login, checkout, medical forms, and legal agreement flows.

## ARIA Roles and Attributes

- **First rule of ARIA**: Do not use ARIA if a native HTML element provides the semantics. `<button>` is always better than `<div role="button">`.
- **Landmark roles**: Use `<main>`, `<nav>`, `<aside>`, `<header>`, `<footer>` instead of ARIA landmarks. Add `role="search"` to search forms.
- **Widget roles**: Use `role="dialog"`, `role="alertdialog"`, `role="tablist"`, `role="tab"`, `role="tabpanel"`, `role="menu"`, `role="menuitem"` for custom widgets.
- **States and properties**: Use `aria-expanded`, `aria-selected`, `aria-checked`, `aria-disabled`, `aria-hidden`, `aria-current` to communicate dynamic state.
- `aria-label` provides an accessible name when visible text is absent. `aria-labelledby` references a visible element as the label. `aria-describedby` provides supplementary description.
- Never set `aria-hidden="true"` on focusable elements. Use `inert` attribute to remove entire DOM subtrees from the accessibility tree and tab order.

## Keyboard Navigation

- Every interactive element must be reachable and operable with the keyboard alone: Tab, Shift+Tab, Enter, Space, Arrow keys, Escape.
- Use `tabindex="0"` to add custom elements to the tab order. Use `tabindex="-1"` for programmatic focus (dialogs, error summaries). Never use `tabindex` values greater than 0.
- Implement arrow key navigation within composite widgets (tabs, menus, toolbars, listboxes) using the roving tabindex pattern or `aria-activedescendant`.
- Trap focus inside modal dialogs. When a dialog opens, focus the first focusable element. When it closes, return focus to the trigger element.
- Provide visible skip links: "Skip to main content" as the first focusable element on the page.

## Screen Reader Optimization

- Test with VoiceOver (macOS/iOS), NVDA (Windows, free), and JAWS (Windows, enterprise). Each has different behavior.
- Ensure every form input has an associated `<label>` element using `for`/`id` pairing. Placeholder text is not a substitute for a label.
- Group related form fields with `<fieldset>` and `<legend>`. Use `aria-required` or the `required` attribute for mandatory fields.
- Announce form errors: link error messages with `aria-describedby` on the invalid input. Use `aria-invalid="true"` on fields with validation errors.
- Use `<table>` with `<caption>`, `<thead>`, `<th scope="col|row">` for data tables. Screen readers use this structure to announce cell positions.
- Avoid CSS `content` for meaningful text. Screen reader support for `::before`/`::after` content is inconsistent.

## Color Contrast

- **AA minimum**: 4.5:1 contrast ratio for normal text (below 18pt/14pt bold). 3:1 for large text (18pt+ or 14pt+ bold). 3:1 for UI components and graphical elements.
- **AAA enhanced**: 7:1 for normal text, 4.5:1 for large text. Target AAA for body text and critical UI elements.
- Test contrast with browser DevTools (Chrome Accessibility pane), axe DevTools, or Colour Contrast Analyser.
- Do not rely on color alone to convey meaning. Supplement with icons, text labels, patterns, or underlines. Example: error states need both red color and an error icon/text.
- Ensure contrast is maintained in both light and dark themes. Retest all color combinations when adding or switching themes.

## Focus Management

- All focusable elements must have a visible focus indicator. The default browser outline is acceptable; custom indicators must have a 3:1 contrast ratio against adjacent colors (WCAG 2.4.11).
- Never use `outline: none` without providing a replacement. Use `:focus-visible` to show focus rings only for keyboard navigation, not mouse clicks.
- Manage focus programmatically during dynamic content changes: move focus to new content after route navigation, modal opening, or inline content insertion.
- After a destructive action (deleting a list item), move focus to a logical place: the next item, the previous item, or a summary heading.

## Semantic HTML

- Use the correct element: `<button>` for actions, `<a>` for navigation, `<input>` for data entry, `<select>` for choice lists, `<details>` for disclosure, `<dialog>` for modals.
- Structure content with heading hierarchy (`<h1>` through `<h6>`). Do not skip heading levels. Each page should have exactly one `<h1>`.
- Use `<ul>`/`<ol>` for lists of items. Screen readers announce the list length, helping users understand content structure.
- Use `<time datetime="...">` for dates and times. Use `<abbr title="...">` for abbreviations.
- Use `<figure>` and `<figcaption>` for images, charts, and diagrams with descriptive captions.

## Live Regions

- Use `aria-live="polite"` for non-urgent updates (toast notifications, status changes, item counts). The announcement waits until the user is idle.
- Use `aria-live="assertive"` for urgent updates (error alerts, session timeout warnings). The announcement interrupts the current screen reader output.
- Use `role="status"` (implicit `aria-live="polite"`) for status messages. Use `role="alert"` (implicit `aria-live="assertive"`) for error/warning alerts.
- The live region element must exist in the DOM before content is injected into it. Dynamically creating a live region and immediately populating it will not be announced.
- Use `aria-atomic="true"` when the entire region content should be announced, not just the changed text. Use on counters and summary panels.
