# Pinia State Management and Vue Router

## When to load
Load when building Pinia stores (setup syntax, persistence, composition), configuring Vue Router (named routes, guards, nested routes), or testing components with stores.

## Pinia Stores

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
  getters: { isLoggedIn: (state) => !!state.token },
  actions: {
    async login(credentials: Credentials) {
      const { user, token } = await api.login(credentials)
      this.user = user
      this.token = token
    },
  },
})
```

- Use `storeToRefs()` to destructure store state while keeping reactivity. Destructuring actions directly is safe.

```ts
const store = useCartStore()
const { items, total } = storeToRefs(store)  // reactive refs
const { addItem, removeItem } = store          // plain functions
```

- Use `pinia-plugin-persistedstate` for localStorage persistence. Store composition: stores can use other stores.

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

## Vue Router

```ts
const routes = [
  {
    path: '/users/:id',
    name: 'user-profile',
    component: () => import('./views/UserProfile.vue'),  // lazy-loaded
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

router.push({ name: 'user-profile', params: { id: userId } })
```

### Navigation Guards

```ts
router.beforeEach(async (to, from) => {
  const auth = useAuthStore()
  if (to.meta.requiresAuth && !auth.isLoggedIn) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }
})
```

### Scroll Behavior

```ts
const router = createRouter({
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) return savedPosition
    if (to.hash) return { el: to.hash, behavior: 'smooth' }
    return { top: 0 }
  },
})
```

- Use named routes to avoid hardcoded path strings. Use `router.addRoute()` for permission-based routes at runtime.

## Testing with Pinia

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

```ts
// Testing composables in isolation
function withSetup<T>(composable: () => T): T {
  let result!: T
  const app = createApp({ setup() { result = composable(); return () => {} } })
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
