# CSS Methodologies, Modules, and CSS-in-JS

## When to load
Load when choosing a CSS architecture (BEM, ITCSS, CUBE CSS), setting up CSS Modules, or implementing styled-components, Emotion, Vanilla Extract, or Panda CSS.

## Methodologies Comparison

| Methodology | Core Idea | Best For |
|---|---|---|
| BEM | Block-Element-Modifier naming | Large teams, component libraries |
| ITCSS | Inverted triangle specificity layering | Enterprise projects |
| CUBE CSS | Composition, Utility, Block, Exception | Design-system-driven projects |
| SMACSS | Categorized rules (base, layout, module, state) | Legacy mixed CSS |
| Atomic CSS | One property per class | Utility-first (Tailwind, UnoCSS) |

### BEM

- Naming: `.card`, `.card__title`, `.card__title--highlighted`
- Never nest BEM selectors deeper than one level. `.block__element__subelement` is wrong — create a new block.
- Keep specificity flat: single-class selectors only. Avoid `!important` and ID selectors.

### ITCSS Layers

Settings → Tools → Generic → Elements → Objects → Components → Utilities

### CUBE CSS

- **Composition**: Layout primitives (Stack, Sidebar, Cluster, Grid)
- **Utility**: Single-purpose classes (`.text-center`, `.gap-m`)
- **Block**: Component-specific styles
- **Exception**: State-driven overrides via `data-*`: `[data-state="active"]`

## CSS Modules

```tsx
// Button.module.css
.button { padding: 8px 16px; border-radius: 4px; }
.button_primary { background: var(--color-primary); color: white; }
.button_disabled { opacity: 0.5; pointer-events: none; }

// Button.tsx
import styles from './Button.module.css'

export function Button({ variant, disabled, children }) {
  return (
    <button className={`${styles.button} ${styles[`button_${variant}`]} ${disabled ? styles.button_disabled : ''}`}>
      {children}
    </button>
  )
}
```

- Use `composes` for extending styles from other modules. Avoid `@import` for composition.
- Name files `.module.css` or `.module.scss` for bundler recognition.

## CSS-in-JS: Runtime

```tsx
// styled-components
const Button = styled.button<{ $variant: 'primary' | 'secondary' }>`
  padding: 8px 16px;
  background: ${({ $variant, theme }) =>
    $variant === 'primary' ? theme.colors.primary : theme.colors.secondary};
  &:hover { opacity: 0.9; }
  &:disabled { opacity: 0.5; pointer-events: none; }
`

// Always define styled components outside the render function
// Use shouldForwardProp to prevent custom props leaking to the DOM
```

## CSS-in-JS: Zero-Runtime

```ts
// Vanilla Extract — type-safe, compiled at build time, no runtime cost
import { style, styleVariants } from '@vanilla-extract/css'

export const base = style({ padding: '8px 16px', borderRadius: '4px' })
export const variants = styleVariants({
  primary: { background: 'blue', color: 'white' },
  secondary: { background: 'gray', color: 'black' },
})

// Panda CSS — design-token-driven, zero-runtime
import { css } from '../styled-system/css'
<button className={css({ padding: '8px 16px', bg: 'blue.500', color: 'white' })}>Submit</button>
```

- **StyleX** (Meta): Atomic CSS-in-JS with compile-time extraction.
- **Linaria**: Zero-runtime tagged template literals, same API as styled-components.
- Avoid generating styles at runtime in performance-critical paths. Choose zero-runtime for large-scale apps.
