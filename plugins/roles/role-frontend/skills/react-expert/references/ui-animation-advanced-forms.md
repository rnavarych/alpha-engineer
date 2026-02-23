# UI Libraries, Animation, Advanced Patterns, DevTools, and Forms

## When to load
Load when selecting or using shadcn/ui, Radix UI, Ark UI, React Aria; implementing Framer Motion animations; working with React Three Fiber, React Email, or Million.js; profiling with React DevTools; or building forms with React Hook Form and Zod.

## UI Libraries and Component Systems

### shadcn/ui
- Not a library — a collection of copy-paste components built on Radix UI primitives and Tailwind CSS.
- Add components via `npx shadcn-ui@latest add button`. Components go to `components/ui/` and are fully owned.
- Each component is a thin, styled wrapper around a Radix UI primitive. Customize Tailwind classes directly.
- Configure via `components.json`: set the style (default/new-york), base color, CSS variables, TypeScript preference.

### Radix UI Primitives
- Unstyled, accessible primitives: `Dialog`, `DropdownMenu`, `Select`, `Popover`, `Tooltip`, `Accordion`, `Tabs`, `Toast`.
- All primitives follow WAI-ARIA patterns. Focus management, keyboard navigation, and screen reader support built in.
- Use `asChild` prop to delegate rendering to a custom element: `<Trigger asChild><button>Click</button></Trigger>`.

### Ark UI
- Headless, framework-agnostic (React, Vue, Solid). Built on Zag.js state machines.
- Components: `DatePicker`, `ColorPicker`, `FileUpload`, `NumberInput`, `RangeSlider`, `TagsInput`, `TreeView`.
- Use with Park UI for pre-styled variants, or style raw components yourself.

### React Aria (Adobe)
- Fully accessible, unstyled, WAI-ARIA-compliant hooks and components.
- `useButton`, `useTextField`, `useSelect`, `useDialog`, `useDatePicker`, `useCalendar` — all with keyboard support and i18n.
- `react-aria-components` provides pre-composed components. Supports RTL, high-contrast mode, and mobile touch.

## Animation — Framer Motion

- Use `motion.div` for declarative animations. Define `initial`, `animate`, and `exit` states.
- `AnimatePresence` handles exit animations when components unmount. Required for mount/unmount transitions.
- Layout animations: `layout` prop animates between layout changes (resize, reorder) automatically.
- `useMotionValue` and `useTransform` for physics-based scroll animations and drag interactions.
- Variants system: define named animation states and orchestrate children with `staggerChildren` and `delayChildren`.
- Use `LazyMotion` with `domAnimation` feature pack to reduce bundle size from ~34KB to ~16KB gzipped.
- `useScroll` for scroll-driven animations: track scroll progress and transform to opacity, scale, or position.

## Advanced Patterns

### React Three Fiber
- Declarative Three.js in React. JSX describes the 3D scene graph: `<mesh>`, `<boxGeometry>`, `<meshStandardMaterial>`.
- `useFrame` hook runs a callback every animation frame. `useThree` accesses renderer, camera, and scene.
- Drei library provides abstractions: `<OrbitControls>`, `<Environment>`, `<Text>`, `<Html>` overlay.
- Performance: use `instancedMesh` for repeated geometries, `useMemo` for materials, `Suspense` for async assets.

### React Email
- `@react-email/components` provides email-safe primitives: `Button`, `Text`, `Section`, `Container`, `Img`, `Link`, `Hr`.
- Render to HTML with `render(<MyEmail />)` from `@react-email/render`. Preview with `email dev` CLI.
- Send via Resend, SendGrid, Postmark, or Nodemailer. Inline critical styles. Avoid flexbox and grid.

### Million.js
- Compiler replacing React's virtual DOM reconciler with block-based diffing for list-heavy UIs.
- Wrap components with `block()` HOC or use `million/compiler` Vite/webpack plugin for automatic optimization.
- Best for static components rendering large arrays. Benchmark before enabling — not all components benefit.

## React DevTools Profiler

- Open Profiler tab. Record a render sequence. Inspect flame graph for slow components.
- **Commit detail view**: shows which components re-rendered and why (props changed, hooks changed, parent re-rendered).
- **Ranked chart**: lists all components by render duration in a single commit.
- **Why did this render?**: enable "Record why each component rendered" to see the specific prop or state that triggered.
- Use `<Profiler id="..." onRender={callback}>` for production-safe profiling of specific subtrees.

## Form Handling — React Hook Form + Zod

- Use React Hook Form (RHF) for performant, uncontrolled form management. Only the changed field re-renders.
- `useForm<FormValues>({ resolver: zodResolver(schema) })` integrates Zod validation.
- `register` attaches fields. `handleSubmit` validates and calls the submit handler. `formState.errors` provides typed errors.
- `Controller` wraps controlled components (Radix, Material UI) that cannot use `register` directly.
- `useFieldArray` for dynamic field lists (line items, tags, addresses).
- Define the Zod schema as the source of truth. Derive `FormValues` with `z.infer<typeof schema>`.
- Use `mode: 'onBlur'` for validation-on-blur in long forms. Use `mode: 'onChange'` for real-time feedback in short forms.
