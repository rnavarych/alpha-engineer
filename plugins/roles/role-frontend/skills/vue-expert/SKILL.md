---
name: role-frontend:vue-expert
description: |
  Vue.js expertise including Composition API, Pinia state management, Nuxt.js 3,
  Vue Router, custom directives, provide/inject patterns, transition system,
  and Volar tooling configuration.
allowed-tools: Read, Grep, Glob, Bash
---

# Vue Expert

## When to use
- Building or reviewing Vue 3 single-file components with `<script setup>`
- Choosing between ref/reactive/computed/watch for state and derived values
- Designing Pinia stores or migrating from Vuex
- Setting up Vue Router with guards, nested routes, and lazy loading
- Working with Nuxt 3 — data fetching, server routes, middleware, SEO
- Implementing typed composables, generic components, or provide/inject
- Debugging reactivity loss, performance bottlenecks, or transition behavior

## Core principles
1. **`<script setup>` always** — less boilerplate, better TypeScript inference, no option to go back
2. **`ref` for primitives, `reactive` for objects** — never destructure reactive; use `toRefs()`
3. **`computed` over `watch` for derived state** — synchronous derivations should never need watchers
4. **Domain stores, not type stores** — `useCartStore`, `useAuthStore`; not `useArrayStore`
5. **`storeToRefs()` for reactive destructuring** — functions can be destructured directly

## Reference Files

- `references/composition-api-reactivity.md` — ref/reactive/toRefs, computed, watch/watchEffect, script setup macros (defineProps, defineEmits, defineModel, defineExpose), composables, shallowRef, defineAsyncComponent
- `references/pinia-vue-router.md` — Pinia setup vs options syntax, storeToRefs, persistence, store composition, Vue Router named routes, guards, scroll behavior, composable testing, createTestingPinia
- `references/nuxt3-typescript-directives.md` — Nuxt 3 useFetch/useAsyncData, server routes, middleware, runtime config, typed composables, generic components, InjectionKey, custom directives, transition system, anti-patterns
