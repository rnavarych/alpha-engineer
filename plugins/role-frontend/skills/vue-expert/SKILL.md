---
name: vue-expert
description: |
  Vue.js expertise including Composition API, Pinia state management, Nuxt.js 3,
  Vue Router, custom directives, provide/inject patterns, transition system,
  and Volar tooling configuration.
allowed-tools: Read, Grep, Glob, Bash
---

# Vue Expert

## Composition API

- Use `<script setup>` as the default for single-file components. It reduces boilerplate and provides better TypeScript inference.
- **ref vs reactive**: Use `ref()` for primitives and single values. Use `reactive()` for objects where you want to avoid `.value` access. Do not destructure reactive objects; it breaks reactivity. Use `toRefs()` if destructuring is needed.
- **computed**: Use `computed()` for derived state. Computed values are cached and only recalculate when dependencies change. Prefer computed over watchers for synchronous derivations.
- **watch vs watchEffect**: Use `watch()` when you need access to previous and current values or want to watch specific sources. Use `watchEffect()` for side effects that automatically track all reactive dependencies. Always clean up side effects in the `onCleanup` callback.
- **Composables**: Extract reusable logic into composable functions prefixed with `use`. Each composable should return reactive state and methods as a plain object. Composables can call other composables.
- **Lifecycle hooks**: Use `onMounted`, `onUnmounted`, `onBeforeUpdate` inside `<script setup>`. Register cleanup logic in `onUnmounted` for timers, subscriptions, and event listeners.

## Pinia State Management

- Define stores with `defineStore` using the setup syntax for maximum flexibility, or the options syntax for simpler stores.
- Structure stores by domain (useUserStore, useCartStore, useNotificationStore), not by data type.
- Use `storeToRefs()` to destructure store state while keeping reactivity. Destructuring actions directly is safe.
- Use `$subscribe` for reacting to state changes (e.g., persisting to localStorage). Use `$onAction` for logging or analytics.
- For persistent state, use `pinia-plugin-persistedstate` instead of manual localStorage logic.
- Keep stores lean. Business logic belongs in composables; stores hold shared state and simple mutations.

## Nuxt.js 3

- Use the `app/` directory structure with file-based routing. Dynamic routes use bracket syntax: `[id].vue`, `[...slug].vue`.
- **Data fetching**: Use `useFetch` for SSR-compatible data fetching. Use `useAsyncData` when you need a custom key or when composing multiple async operations. Use `$fetch` for client-only requests.
- **Server routes**: Create API endpoints in `server/api/` and `server/routes/`. Use `defineEventHandler` for request handling. Access query params with `getQuery`, body with `readBody`.
- **Auto-imports**: Components in `components/`, composables in `composables/`, and utilities in `utils/` are auto-imported. Avoid manual imports for these.
- **Middleware**: Use route middleware in `middleware/` for auth guards and redirects. Use `defineNuxtRouteMiddleware` with `navigateTo` for redirects.
- **SEO**: Use `useHead` or `useSeoMeta` composables for page-level meta tags. Define global head config in `nuxt.config.ts`.

## Vue Router

- Use named routes for navigation. Avoid hardcoded path strings in `router.push()`.
- Implement route guards with `beforeEach` for authentication and `beforeResolve` for data prefetching.
- Use lazy-loaded route components: `component: () => import('./views/Dashboard.vue')` for code splitting.
- Use nested routes with `<RouterView>` for layout composition. Shared layouts should be parent routes.
- Leverage route meta fields for declaring page-level metadata (required auth, page title, breadcrumbs).

## Custom Directives

- Use custom directives for low-level DOM manipulation that does not fit into the component model.
- Common patterns: `v-click-outside`, `v-tooltip`, `v-intersection`, `v-focus-trap`, `v-auto-resize`.
- Implement the `mounted`, `updated`, and `unmounted` hooks. Always clean up event listeners in `unmounted`.
- Prefer composables over directives when the logic involves reactive state or complex behavior.

## Provide / Inject

- Use `provide`/`inject` for dependency injection across deeply nested component trees.
- Always define injection keys as `InjectionKey<T>` symbols for type safety.
- Provide reactive values (refs or reactive objects) so injecting components stay in sync.
- Use `inject` with a default value or throw an error if the provider is required. Never silently return undefined.

## Transition System

- Use `<Transition>` for single-element enter/leave animations. Use `<TransitionGroup>` for list animations.
- Define CSS transitions with `-enter-active`, `-enter-from`, `-enter-to`, `-leave-active`, `-leave-from`, `-leave-to` classes.
- Use `mode="out-in"` for route transitions to prevent overlapping elements.
- For complex animations, use JavaScript hooks (`@before-enter`, `@enter`, `@leave`) with GSAP or Motion One.
- Respect `prefers-reduced-motion`. Disable or simplify animations for users who request it.

## Volar Tooling

- Use Volar (Vue Language Features) as the primary IDE extension for Vue 3. Disable Vetur if migrating.
- Enable `vue-tsc` for type-checking `.vue` files in CI. Add `vue-tsc --noEmit` to the build pipeline.
- Configure `tsconfig.json` with `"moduleResolution": "bundler"` and include `"vue/macros-global"` for macro support.
- Use `defineProps<T>()` and `defineEmits<T>()` with TypeScript generics for fully typed component APIs.
