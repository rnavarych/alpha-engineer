# Nuxt 3, TypeScript Patterns, and Advanced Vue

## When to load
Load when working with Nuxt 3 (data fetching, server routes, middleware, SEO), TypeScript generic components, custom directives, provide/inject, or the Vue transition system.

## Nuxt 3 Data Fetching

```vue
<script setup lang="ts">
// SSR-compatible fetch
const { data: posts, pending, error, refresh } = await useFetch('/api/posts', {
  query: { page: currentPage },
  transform: (response) => response.data,
})

// useAsyncData for complex parallel cases
const { data } = await useAsyncData('dashboard', async () => {
  const [users, stats] = await Promise.all([$fetch('/api/users'), $fetch('/api/stats')])
  return { users, stats }
})

// Client-only (not SSR)
const result = await $fetch('/api/analytics', { method: 'POST', body: payload })
</script>
```

### Server Routes

```ts
// server/api/posts/[id].get.ts
export default defineEventHandler(async (event) => {
  const id = getRouterParam(event, 'id')
  return await db.posts.findById(id)
})

// server/api/posts.post.ts
export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  return await db.posts.create(body)
})
```

### Nuxt Patterns

```ts
// Middleware — auth guard
export default defineNuxtRouteMiddleware((to, from) => {
  const auth = useAuthStore()
  if (!auth.isLoggedIn && to.meta.requiresAuth) return navigateTo('/login')
})

// Runtime config
export default defineNuxtConfig({
  runtimeConfig: {
    apiSecret: process.env.API_SECRET,          // server-only
    public: { apiBase: process.env.API_BASE },  // available on client
  },
})
```

- Auto-imports: `components/`, `composables/`, and `utils/` are auto-imported. Avoid manual imports.
- SEO: use `useSeoMeta({ title, ogTitle, description, ogImage })` for page-level meta.
- Modules: `@nuxtjs/i18n`, `@nuxt/image`, `@pinia/nuxt`, `@vueuse/nuxt`, `@nuxt/fonts`.

## TypeScript Patterns

```vue
<!-- Generic components (Vue 3.3+) -->
<script setup lang="ts" generic="T extends { id: string }">
defineProps<{ items: T[]; selected: T | null }>()
defineEmits<{ select: [item: T] }>()
</script>
```

```ts
// Typed composable return
interface UsePaginationReturn {
  page: Ref<number>
  pageSize: Ref<number>
  totalPages: ComputedRef<number>
  next: () => void
  prev: () => void
}
export function usePagination(total: Ref<number>): UsePaginationReturn { /* ... */ }

// Typed provide/inject with InjectionKey
import type { InjectionKey, Ref } from 'vue'
export const ThemeKey: InjectionKey<Ref<'light' | 'dark'>> = Symbol('theme')
provide(ThemeKey, theme)
const theme = inject(ThemeKey, ref('light'))
```

## Custom Directives

```ts
// directives/vClickOutside.ts
import type { Directive } from 'vue'

export const vClickOutside: Directive<HTMLElement, () => void> = {
  mounted(el, binding) {
    el._clickOutside = (event: Event) => {
      if (!el.contains(event.target as Node)) binding.value()
    }
    document.addEventListener('click', el._clickOutside)
  },
  unmounted(el) {
    document.removeEventListener('click', el._clickOutside)
  },
}
```

- Common patterns: `v-click-outside`, `v-tooltip`, `v-intersection`, `v-focus-trap`, `v-auto-resize`.
- Always clean up event listeners in `unmounted`. Prefer composables over directives for stateful logic.

## Transitions

- Use `<Transition>` for single-element enter/leave, `<TransitionGroup>` for lists.
- Use `mode="out-in"` for route transitions to prevent overlapping elements.
- For complex animations use JavaScript hooks (`@enter`, `@leave`) with GSAP or Motion One.
- Always respect `prefers-reduced-motion` — disable or simplify animations for users who request it.

## Anti-Patterns

| Anti-Pattern | Problem | Solution |
|---|---|---|
| Destructuring reactive objects | Breaks reactivity | Use `toRefs()` or access via `state.prop` |
| Mutating props directly | Vue warns; breaks one-way data flow | Emit events or use `defineModel` |
| Watchers for derived state | Harder to trace | Use `computed()` instead |
| Global event bus | No type safety; memory leaks | Use composables, Pinia, or provide/inject |
| `ref` for large nested objects | Deep reactivity overhead | Use `shallowRef` and replace by reference |
| Blocking `<script setup>` with await | Requires Suspense boundary | Move async to `onMounted` or `useFetch` |
