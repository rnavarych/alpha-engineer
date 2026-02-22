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

```vue
<script setup lang="ts">
import { ref, reactive, toRefs } from 'vue'

// ref for primitives
const count = ref(0)
const name = ref<string>('Vue')

// reactive for objects
const state = reactive({
  items: [] as string[],
  loading: false,
})

// safe destructuring from reactive
const { items, loading } = toRefs(state)
</script>
```

- **computed**: Use `computed()` for derived state. Computed values are cached and only recalculate when dependencies change. Prefer computed over watchers for synchronous derivations.

```ts
const filteredItems = computed(() =>
  items.value.filter(item => item.includes(searchQuery.value))
)

// Writable computed
const fullName = computed({
  get: () => `${firstName.value} ${lastName.value}`,
  set: (val: string) => {
    const [first, last] = val.split(' ')
    firstName.value = first
    lastName.value = last
  },
})
```

- **watch vs watchEffect**: Use `watch()` when you need access to previous and current values or want to watch specific sources. Use `watchEffect()` for side effects that automatically track all reactive dependencies. Always clean up side effects in the `onCleanup` callback.

```ts
// watch specific source with old/new values
watch(searchQuery, (newVal, oldVal) => {
  if (newVal !== oldVal) fetchResults(newVal)
}, { debounce: 300 })

// watchEffect auto-tracks dependencies
watchEffect((onCleanup) => {
  const controller = new AbortController()
  fetch(`/api/items?q=${query.value}`, { signal: controller.signal })
  onCleanup(() => controller.abort())
})
```

- **Composables**: Extract reusable logic into composable functions prefixed with `use`. Each composable should return reactive state and methods as a plain object. Composables can call other composables.

```ts
// composables/useFetch.ts
export function useFetch<T>(url: MaybeRefOrGetter<string>) {
  const data = ref<T | null>(null)
  const error = ref<Error | null>(null)
  const loading = ref(false)

  async function execute() {
    loading.value = true
    error.value = null
    try {
      const response = await fetch(toValue(url))
      data.value = await response.json()
    } catch (e) {
      error.value = e as Error
    } finally {
      loading.value = false
    }
  }

  watchEffect(() => {
    execute()
  })

  return { data, error, loading, execute }
}
```

- **Lifecycle hooks**: Use `onMounted`, `onUnmounted`, `onBeforeUpdate` inside `<script setup>`. Register cleanup logic in `onUnmounted` for timers, subscriptions, and event listeners.

## Vue 3 Script Setup Macros

- **defineProps**: Declare component props with full TypeScript support. Use the generic syntax for typed props.

```vue
<script setup lang="ts">
// Runtime declaration
const props = defineProps({
  title: { type: String, required: true },
  count: { type: Number, default: 0 },
})

// Type-based declaration (preferred)
const props = defineProps<{
  title: string
  count?: number
  items: string[]
}>()

// With defaults (use withDefaults)
const props = withDefaults(defineProps<{
  title: string
  count?: number
}>(), {
  count: 0,
})
</script>
```

- **defineEmits**: Declare component events with typed payloads.

```vue
<script setup lang="ts">
const emit = defineEmits<{
  update: [value: string]
  delete: [id: number]
  'update:modelValue': [value: boolean]
}>()

emit('update', 'new value')
</script>
```

- **defineModel**: Two-way binding macro (Vue 3.4+). Replaces the `modelValue` prop + `update:modelValue` emit pattern.

```vue
<script setup lang="ts">
const modelValue = defineModel<string>()         // default v-model
const title = defineModel<string>('title')        // named v-model
const count = defineModel<number>('count', { default: 0 })
</script>
```

- **defineExpose**: Explicitly expose component internals for `ref` template access. By default, `<script setup>` components expose nothing.

```vue
<script setup lang="ts">
const internalState = ref(0)
function reset() { internalState.value = 0 }

defineExpose({ reset })
</script>
```

- **defineSlots**: Type-safe slot definitions (Vue 3.3+).

```vue
<script setup lang="ts">
const slots = defineSlots<{
  default: (props: { item: Item; index: number }) => any
  header: () => any
}>()
</script>
```

## Pinia State Management

- Define stores with `defineStore` using the setup syntax for maximum flexibility, or the options syntax for simpler stores.

```ts
// Setup syntax (recommended for complex stores)
export const useCartStore = defineStore('cart', () => {
  const items = ref<CartItem[]>([])
  const total = computed(() =>
    items.value.reduce((sum, item) => sum + item.price * item.qty, 0)
  )

  function addItem(product: Product) {
    const existing = items.value.find(i => i.id === product.id)
    if (existing) existing.qty++
    else items.value.push({ ...product, qty: 1 })
  }

  function removeItem(id: string) {
    items.value = items.value.filter(i => i.id !== id)
  }

  return { items, total, addItem, removeItem }
})

// Options syntax (simpler stores)
export const useAuthStore = defineStore('auth', {
  state: () => ({ user: null as User | null, token: '' }),
  getters: {
    isLoggedIn: (state) => !!state.token,
  },
  actions: {
    async login(credentials: Credentials) {
      const { user, token } = await api.login(credentials)
      this.user = user
      this.token = token
    },
  },
})
```

- Structure stores by domain (useUserStore, useCartStore, useNotificationStore), not by data type.
- Use `storeToRefs()` to destructure store state while keeping reactivity. Destructuring actions directly is safe.

```ts
const store = useCartStore()
const { items, total } = storeToRefs(store) // reactive refs
const { addItem, removeItem } = store        // plain functions
```

- Use `$subscribe` for reacting to state changes (e.g., persisting to localStorage). Use `$onAction` for logging or analytics.
- For persistent state, use `pinia-plugin-persistedstate` instead of manual localStorage logic.

```ts
// main.ts
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate'
const pinia = createPinia()
pinia.use(piniaPluginPersistedstate)

// store
export const useSettingsStore = defineStore('settings', {
  state: () => ({ theme: 'light', locale: 'en' }),
  persist: true, // or { storage: sessionStorage, paths: ['theme'] }
})
```

- **Store composition**: Stores can use other stores inside their setup function or actions.

```ts
export const useCheckoutStore = defineStore('checkout', () => {
  const cart = useCartStore()
  const auth = useAuthStore()

  async function checkout() {
    if (!auth.isLoggedIn) throw new Error('Must be logged in')
    await api.createOrder(cart.items)
    cart.$reset()
  }

  return { checkout }
})
```

- Keep stores lean. Business logic belongs in composables; stores hold shared state and simple mutations.

## Nuxt 3

- Use the `app/` directory structure with file-based routing. Dynamic routes use bracket syntax: `[id].vue`, `[...slug].vue`.
- **Data fetching**: Use `useFetch` for SSR-compatible data fetching. Use `useAsyncData` when you need a custom key or when composing multiple async operations. Use `$fetch` for client-only requests.

```vue
<script setup lang="ts">
// SSR-compatible fetch
const { data: posts, pending, error, refresh } = await useFetch('/api/posts', {
  query: { page: currentPage },
  transform: (response) => response.data,
})

// useAsyncData for complex cases
const { data } = await useAsyncData('dashboard', async () => {
  const [users, stats] = await Promise.all([
    $fetch('/api/users'),
    $fetch('/api/stats'),
  ])
  return { users, stats }
})

// Client-only fetch (not SSR)
const result = await $fetch('/api/analytics', { method: 'POST', body: payload })
</script>
```

- **Server routes**: Create API endpoints in `server/api/` and `server/routes/`. Use `defineEventHandler` for request handling.

```ts
// server/api/posts/[id].get.ts
export default defineEventHandler(async (event) => {
  const id = getRouterParam(event, 'id')
  const query = getQuery(event)
  return await db.posts.findById(id)
})

// server/api/posts.post.ts
export default defineEventHandler(async (event) => {
  const body = await readBody(event)
  return await db.posts.create(body)
})
```

- **Auto-imports**: Components in `components/`, composables in `composables/`, and utilities in `utils/` are auto-imported. Avoid manual imports for these.
- **Middleware**: Use route middleware in `middleware/` for auth guards and redirects. Use `defineNuxtRouteMiddleware` with `navigateTo` for redirects.

```ts
// middleware/auth.ts
export default defineNuxtRouteMiddleware((to, from) => {
  const auth = useAuthStore()
  if (!auth.isLoggedIn && to.meta.requiresAuth) {
    return navigateTo('/login')
  }
})
```

- **SEO**: Use `useHead` or `useSeoMeta` composables for page-level meta tags. Define global head config in `nuxt.config.ts`.

```vue
<script setup lang="ts">
useSeoMeta({
  title: 'My Page Title',
  ogTitle: 'My Page Title',
  description: 'Page description for search engines',
  ogDescription: 'Page description for social sharing',
  ogImage: 'https://example.com/og.png',
})
</script>
```

- **Nuxt modules**: Use the module ecosystem for common needs: `@nuxtjs/i18n`, `@nuxt/image`, `@pinia/nuxt`, `@vueuse/nuxt`, `@nuxt/fonts`.
- **Runtime config**: Use `useRuntimeConfig()` for environment-specific values. Public values go in `runtimeConfig.public`, server-only in `runtimeConfig`.

```ts
// nuxt.config.ts
export default defineNuxtConfig({
  runtimeConfig: {
    apiSecret: process.env.API_SECRET,  // server-only
    public: {
      apiBase: process.env.API_BASE,    // available on client
    },
  },
})
```

## Vue Router

- Use named routes for navigation. Avoid hardcoded path strings in `router.push()`.

```ts
// Define routes with names
const routes = [
  {
    path: '/users/:id',
    name: 'user-profile',
    component: () => import('./views/UserProfile.vue'),
    meta: { requiresAuth: true, title: 'User Profile' },
  },
  {
    path: '/dashboard',
    component: () => import('./layouts/DashboardLayout.vue'),
    children: [
      { path: '', name: 'dashboard-home', component: () => import('./views/DashboardHome.vue') },
      { path: 'settings', name: 'dashboard-settings', component: () => import('./views/Settings.vue') },
    ],
  },
]

// Navigate with named routes
router.push({ name: 'user-profile', params: { id: userId } })
```

- Implement route guards with `beforeEach` for authentication and `beforeResolve` for data prefetching.

```ts
router.beforeEach(async (to, from) => {
  const auth = useAuthStore()
  if (to.meta.requiresAuth && !auth.isLoggedIn) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }
})
```

- Use lazy-loaded route components for code splitting.
- Use nested routes with `<RouterView>` for layout composition. Shared layouts should be parent routes.
- Leverage route meta fields for declaring page-level metadata (required auth, page title, breadcrumbs).
- **Scroll behavior**: Customize scroll position on navigation.

```ts
const router = createRouter({
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) return savedPosition
    if (to.hash) return { el: to.hash, behavior: 'smooth' }
    return { top: 0 }
  },
})
```

- **Dynamic route addition**: Use `router.addRoute()` for permission-based route registration at runtime.

## Performance

- **defineAsyncComponent**: Lazy-load heavy components with loading and error states.

```ts
const HeavyChart = defineAsyncComponent({
  loader: () => import('./HeavyChart.vue'),
  loadingComponent: LoadingSpinner,
  errorComponent: ErrorFallback,
  delay: 200,       // show loading after 200ms
  timeout: 10000,   // error after 10s
})
```

- **keep-alive**: Cache component instances to preserve state when switching between them.

```vue
<KeepAlive :include="['DashboardView', 'SettingsView']" :max="5">
  <RouterView />
</KeepAlive>
```

- **v-memo**: Skip re-rendering list items when their dependencies have not changed (Vue 3.2+).

```vue
<div v-for="item in list" :key="item.id" v-memo="[item.id, item.updated]">
  <ExpensiveComponent :item="item" />
</div>
```

- **v-once**: Render content once and skip all future updates. Use for truly static content.
- **Suspense**: Orchestrate async component loading with fallback content.

```vue
<Suspense>
  <template #default>
    <AsyncDashboard />
  </template>
  <template #fallback>
    <SkeletonLoader />
  </template>
</Suspense>
```

- **Virtual scrolling**: Use `@tanstack/vue-virtual` or `vue-virtual-scroller` for lists with thousands of items. Only render visible items in the DOM.
- **Computed with caching**: Avoid expensive operations in templates. Move them to `computed` properties which cache results.
- **shallowRef / shallowReactive**: Use for large objects where you only need to track top-level changes, not deep reactivity.

```ts
const largeList = shallowRef<Item[]>([])
// trigger update by assigning a new array reference
largeList.value = [...largeList.value, newItem]
```

## Testing

- **Vitest + Vue Test Utils**: The standard testing stack for Vue 3 projects.

```ts
import { mount } from '@vue/test-utils'
import { describe, it, expect, vi } from 'vitest'
import Counter from './Counter.vue'

describe('Counter', () => {
  it('increments count on click', async () => {
    const wrapper = mount(Counter, {
      props: { initialCount: 0 },
    })
    await wrapper.find('button').trigger('click')
    expect(wrapper.text()).toContain('1')
  })

  it('emits update event', async () => {
    const wrapper = mount(Counter)
    await wrapper.find('button').trigger('click')
    expect(wrapper.emitted('update')).toHaveLength(1)
    expect(wrapper.emitted('update')![0]).toEqual([1])
  })
})
```

- **Testing composables**: Test composables in isolation using a component wrapper or `@vue/test-utils` `renderComposable`.

```ts
import { ref } from 'vue'
import { useCounter } from './useCounter'

function withSetup<T>(composable: () => T): T {
  let result!: T
  const app = createApp({
    setup() {
      result = composable()
      return () => {}
    },
  })
  app.mount(document.createElement('div'))
  return result
}

it('useCounter increments', () => {
  const { count, increment } = withSetup(() => useCounter())
  expect(count.value).toBe(0)
  increment()
  expect(count.value).toBe(1)
})
```

- **Testing with Pinia**: Use `createTestingPinia` for store testing in components.

```ts
import { createTestingPinia } from '@pinia/testing'

const wrapper = mount(ShoppingCart, {
  global: {
    plugins: [createTestingPinia({
      initialState: { cart: { items: mockItems } },
      stubActions: false,
    })],
  },
})
```

- **Component testing with Cypress**: Use `@cypress/vue` for integration-level component tests that run in a real browser.

## TypeScript Patterns

- **Typed props and emits**: Always use the generic form of `defineProps<T>()` and `defineEmits<T>()`.
- **Typed composables**: Define explicit return types for composables.

```ts
interface UsePaginationReturn {
  page: Ref<number>
  pageSize: Ref<number>
  totalPages: ComputedRef<number>
  next: () => void
  prev: () => void
}

export function usePagination(total: Ref<number>): UsePaginationReturn {
  // implementation
}
```

- **Generic components** (Vue 3.3+): Use the `generic` attribute for type-parameterized components.

```vue
<script setup lang="ts" generic="T extends { id: string }">
defineProps<{
  items: T[]
  selected: T | null
}>()

defineEmits<{
  select: [item: T]
}>()
</script>
```

- **Typed provide/inject**: Always use `InjectionKey<T>` symbols.

```ts
// keys.ts
import type { InjectionKey, Ref } from 'vue'
export const ThemeKey: InjectionKey<Ref<'light' | 'dark'>> = Symbol('theme')

// provider
provide(ThemeKey, theme)

// consumer
const theme = inject(ThemeKey) // type: Ref<'light' | 'dark'> | undefined
const theme = inject(ThemeKey, ref('light')) // with default
```

## Build and Vite Configuration

- Configure `vite.config.ts` with Vue-specific plugins and settings.

```ts
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath } from 'node:url'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true,
      },
    },
  },
})
```

- Environment variables: use `import.meta.env.VITE_*` for client-exposed variables.
- Enable `vue-tsc` for type-checking `.vue` files in CI. Add `vue-tsc --noEmit` to the build pipeline.
- Configure `tsconfig.json` with `"moduleResolution": "bundler"` and include `"vue/macros-global"` for macro support.

## Custom Directives

- Use custom directives for low-level DOM manipulation that does not fit into the component model.
- Common patterns: `v-click-outside`, `v-tooltip`, `v-intersection`, `v-focus-trap`, `v-auto-resize`.

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

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Solution |
|---|---|---|
| Destructuring reactive objects | Breaks reactivity | Use `toRefs()` or access via `state.prop` |
| Mutating props directly | Vue warns; breaks one-way data flow | Emit events or use `defineModel` |
| Watchers for derived state | Unnecessary; harder to trace | Use `computed()` instead |
| Global event bus | No type safety; memory leaks | Use composables, Pinia, or provide/inject |
| Barrel exports in large apps | Hurts tree-shaking; slow HMR | Import directly from source files |
| `ref` for large nested objects | Deep reactivity overhead | Use `shallowRef` and replace by reference |
| Blocking `<script setup>` with await | Requires Suspense boundary | Move async to `onMounted` or `useFetch` |
