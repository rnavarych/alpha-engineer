# Global State: Zustand, Jotai, Redux Toolkit

## When to load
Load when building global client state stores — choosing between Zustand, Jotai, or Redux Toolkit, or implementing URL state, form state, XState machines, or signals.

## Zustand

```tsx
import { create } from 'zustand'
import { devtools, persist, immer } from 'zustand/middleware'

interface CartStore {
  items: CartItem[]
  total: number
  addItem: (product: Product) => void
  removeItem: (id: string) => void
  clear: () => void
}

export const useCartStore = create<CartStore>()(
  devtools(
    persist(
      immer((set) => ({
        items: [],
        total: 0,
        addItem: (product) => set((state) => {
          const existing = state.items.find(i => i.id === product.id)
          if (existing) existing.qty += 1
          else state.items.push({ ...product, qty: 1 })
          state.total = state.items.reduce((s, i) => s + i.price * i.qty, 0)
        }),
        removeItem: (id) => set((state) => {
          state.items = state.items.filter(i => i.id !== id)
          state.total = state.items.reduce((s, i) => s + i.price * i.qty, 0)
        }),
        clear: () => set({ items: [], total: 0 }),
      })),
      { name: 'cart-storage' },
    ),
  ),
)

// Granular selectors prevent unnecessary re-renders
const total = useCartStore(state => state.total)
import { useShallow } from 'zustand/react/shallow'
const { items, addItem } = useCartStore(useShallow(state => ({ items: state.items, addItem: state.addItem })))
```

- Use `useCartStore.getState()` and `useCartStore.setState()` outside React components.
- Split large stores by domain — multiple small stores beat one monolithic store.

## Jotai

```tsx
import { atom, useAtom, useAtomValue, useSetAtom } from 'jotai'
import { atomWithStorage } from 'jotai/utils'

const countAtom = atom(0)
const themeAtom = atomWithStorage<'light' | 'dark'>('theme', 'light')
const doubleCountAtom = atom((get) => get(countAtom) * 2)

// Read-write derived atom
const countWithMinAtom = atom(
  (get) => get(countAtom),
  (get, set, newValue: number) => set(countAtom, Math.max(0, newValue)),
)

// Async atom
const userAtom = atom(async () => {
  const response = await fetch('/api/user')
  return response.json()
})

function Counter() {
  const [count, setCount] = useAtom(countAtom)
  const doubleCount = useAtomValue(doubleCountAtom)
  const setTheme = useSetAtom(themeAtom)
}
```

- Atoms are bottom-up: start primitive, compose into derived. Eliminates Context for most use cases.
- Use `Provider` only for state isolation (tests, embedded widgets).

## Redux Toolkit

```tsx
const userSlice = createSlice({
  name: 'user',
  initialState: { users: [] as User[], loading: false, error: null as string | null },
  reducers: {
    userUpdated: (state, action: PayloadAction<User>) => {
      const index = state.users.findIndex(u => u.id === action.payload.id)
      if (index >= 0) state.users[index] = action.payload
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchUsers.pending, (state) => { state.loading = true })
      .addCase(fetchUsers.fulfilled, (state, action) => { state.users = action.payload; state.loading = false })
      .addCase(fetchUsers.rejected, (state, action) => { state.error = action.error.message ?? 'Failed'; state.loading = false })
  },
})
```

- Use `createEntityAdapter` for normalized collections. Use `createSelector` for memoized derived state.

## URL State, Forms, XState, Signals

```tsx
// nuqs: type-safe URL search params
import { useQueryState, parseAsInteger } from 'nuqs'
const [page, setPage] = useQueryState('page', parseAsInteger.withDefault(1))

// React Hook Form + Zod
const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
  resolver: zodResolver(schema),
  defaultValues: { email: '', password: '' },
})

// XState for complex state machines
const fetchMachine = createMachine({
  id: 'fetch', initial: 'idle',
  states: {
    idle: { on: { FETCH: 'loading' } },
    loading: { invoke: { src: 'fetchData', onDone: 'success', onError: 'error' } },
    success: { on: { REFRESH: 'loading' } },
    error: { on: { RETRY: { target: 'loading' } } },
  },
})

// Preact signals (fine-grained reactivity)
import { signal, computed } from '@preact/signals-react'
const count = signal(0)
const doubled = computed(() => count.value * 2)
```

## Anti-Patterns

| Anti-Pattern | Problem | Solution |
|---|---|---|
| Prop drilling through 5+ levels | Verbose, fragile | Zustand, Jotai, Context, or composition |
| Duplicating server data in stores | Two sources of truth | TanStack Query / SWR as single cache |
| Single global store for everything | Everything re-renders | Domain-specific stores, colocation |
| Form state in global store | Over-coupling | React Hook Form, local state |
