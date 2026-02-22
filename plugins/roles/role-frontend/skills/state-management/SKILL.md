---
name: state-management
description: |
  State management expertise including local vs global state decisions, Redux Toolkit,
  Zustand, Jotai, MobX, Context API patterns, server state (React Query, SWR) vs
  client state, optimistic updates, and state machines with XState.
allowed-tools: Read, Grep, Glob, Bash
---

# State Management

## State Categories

| Category | Examples | Recommended Tool |
|---|---|---|
| Local UI state | Modal open/close, toggle, hover | `useState`, `useReducer`, `ref()`, `signal()` |
| Shared UI state | Theme, sidebar collapsed, toast notifications | Zustand, Jotai, Context, Pinia |
| Server cache state | User profiles, product lists, API data | TanStack Query, SWR, RTK Query |
| URL state | Pagination, filters, search, sort | `nuqs`, `searchParams`, router state |
| Form state | Input values, validation, dirty/touched | React Hook Form, VeeValidate, Angular Reactive Forms |

### Decision Criteria

- **Keep it local** if the state resets when the component unmounts and that is correct behavior.
- **Lift to global** if lifting state up requires passing props through more than two intermediate components.
- **Use server state tools** for any data that originates from an API. Never copy server data into a client state store.
- **Use the URL** for anything the user should be able to bookmark or share: pagination, filters, search queries, selected tabs.
- **Use form libraries** for transient input values. Do not store form drafts in global state.

## React State Primitives

### useState

```tsx
const [count, setCount] = useState(0)
const [items, setItems] = useState<Item[]>([])

// Functional updates for state derived from previous state
setCount(prev => prev + 1)
setItems(prev => [...prev, newItem])

// Lazy initialization for expensive computations
const [data, setData] = useState(() => computeExpensiveDefault())
```

### useReducer

```tsx
type Action =
  | { type: 'add'; item: Item }
  | { type: 'remove'; id: string }
  | { type: 'toggle'; id: string }

function reducer(state: Item[], action: Action): Item[] {
  switch (action.type) {
    case 'add':
      return [...state, action.item]
    case 'remove':
      return state.filter(i => i.id !== action.id)
    case 'toggle':
      return state.map(i =>
        i.id === action.id ? { ...i, done: !i.done } : i
      )
  }
}

const [items, dispatch] = useReducer(reducer, [])
dispatch({ type: 'add', item: newItem })
```

- Use `useReducer` when state transitions are complex, when multiple state values change together, or when the next state depends on the previous state in non-trivial ways.

### useContext

- Use React Context for low-frequency global state: theme, locale, auth status, feature flags.
- Do not use Context for high-frequency updates (form inputs, animation state, search results). Every context change re-renders all consumers.
- Split contexts by concern: `ThemeContext`, `AuthContext`, `LocaleContext`. Avoid a single "AppContext" that combines unrelated state.

```tsx
const ThemeContext = createContext<ThemeContextType | null>(null)

function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setTheme] = useState<'light' | 'dark'>('light')
  const value = useMemo(() => ({ theme, setTheme }), [theme])
  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>
}

function useTheme() {
  const context = useContext(ThemeContext)
  if (!context) throw new Error('useTheme must be used within ThemeProvider')
  return context
}
```

### useSyncExternalStore

```tsx
// Subscribe to external stores (browser APIs, third-party state)
function useOnlineStatus() {
  return useSyncExternalStore(
    (callback) => {
      window.addEventListener('online', callback)
      window.addEventListener('offline', callback)
      return () => {
        window.removeEventListener('online', callback)
        window.removeEventListener('offline', callback)
      }
    },
    () => navigator.onLine,       // client snapshot
    () => true,                   // server snapshot (SSR)
  )
}
```

### React 19 use()

```tsx
// use() can read promises and contexts inside render
function UserProfile({ userPromise }: { userPromise: Promise<User> }) {
  const user = use(userPromise) // suspends until resolved
  return <h1>{user.name}</h1>
}

// Conditional context reading (not possible with useContext)
function ConditionalTheme({ themed }: { themed: boolean }) {
  if (themed) {
    const theme = use(ThemeContext)
    return <div style={{ color: theme.primary }}>Themed</div>
  }
  return <div>Unthemed</div>
}
```

## Server State: TanStack Query

### Queries

```tsx
function useUsers(filters: UserFilters) {
  return useQuery({
    queryKey: ['users', filters],
    queryFn: () => fetchUsers(filters),
    staleTime: 5 * 60 * 1000,          // fresh for 5 minutes
    gcTime: 30 * 60 * 1000,            // garbage collect after 30 min
    placeholderData: keepPreviousData,  // show stale data during refetch
    retry: 3,
    retryDelay: (attempt) => Math.min(1000 * 2 ** attempt, 30000),
  })
}
```

### Mutations with Optimistic Updates

```tsx
function useToggleTodo() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (todoId: string) => api.toggleTodo(todoId),
    onMutate: async (todoId) => {
      // Cancel outgoing refetches
      await queryClient.cancelQueries({ queryKey: ['todos'] })

      // Snapshot previous state
      const previousTodos = queryClient.getQueryData<Todo[]>(['todos'])

      // Optimistic update
      queryClient.setQueryData<Todo[]>(['todos'], (old) =>
        old?.map(todo =>
          todo.id === todoId ? { ...todo, done: !todo.done } : todo
        )
      )

      return { previousTodos }
    },
    onError: (_err, _todoId, context) => {
      // Rollback on error
      queryClient.setQueryData(['todos'], context?.previousTodos)
    },
    onSettled: () => {
      // Refetch to ensure consistency
      queryClient.invalidateQueries({ queryKey: ['todos'] })
    },
  })
}
```

### Infinite Queries

```tsx
function useInfiniteUsers() {
  return useInfiniteQuery({
    queryKey: ['users'],
    queryFn: ({ pageParam }) => fetchUsers({ cursor: pageParam }),
    initialPageParam: 0,
    getNextPageParam: (lastPage) => lastPage.nextCursor ?? undefined,
    getPreviousPageParam: (firstPage) => firstPage.prevCursor ?? undefined,
  })
}
```

### Prefetching

```tsx
// Prefetch on hover for instant navigation
function UserLink({ userId }: { userId: string }) {
  const queryClient = useQueryClient()

  return (
    <Link
      to={`/users/${userId}`}
      onMouseEnter={() => {
        queryClient.prefetchQuery({
          queryKey: ['user', userId],
          queryFn: () => fetchUser(userId),
          staleTime: 60 * 1000,
        })
      }}
    >
      View User
    </Link>
  )
}
```

### SWR (Alternative)

```tsx
import useSWR from 'swr'

const fetcher = (url: string) => fetch(url).then(r => r.json())

function useUser(id: string) {
  const { data, error, isLoading, mutate } = useSWR(`/api/users/${id}`, fetcher, {
    revalidateOnFocus: true,
    dedupingInterval: 2000,
  })
  return { user: data, error, isLoading, mutate }
}
```

## Global State: Zustand

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
        addItem: (product) =>
          set((state) => {
            const existing = state.items.find(i => i.id === product.id)
            if (existing) existing.qty += 1
            else state.items.push({ ...product, qty: 1 })
            state.total = state.items.reduce((s, i) => s + i.price * i.qty, 0)
          }),
        removeItem: (id) =>
          set((state) => {
            state.items = state.items.filter(i => i.id !== id)
            state.total = state.items.reduce((s, i) => s + i.price * i.qty, 0)
          }),
        clear: () => set({ items: [], total: 0 }),
      })),
      { name: 'cart-storage' },
    ),
    { name: 'CartStore' },
  ),
)
```

- Access only the state slices a component needs using selectors to prevent unnecessary re-renders:

```tsx
// Good: only re-renders when total changes
const total = useCartStore(state => state.total)

// Good: stable selector with useShallow for objects
import { useShallow } from 'zustand/react/shallow'
const { items, addItem } = useCartStore(
  useShallow(state => ({ items: state.items, addItem: state.addItem }))
)
```

- Zustand stores work outside React components. Use `useCartStore.getState()` and `useCartStore.setState()` in plain functions, event handlers, or server-side code.
- Split large stores into multiple smaller stores by domain rather than creating one monolithic store.

## Global State: Jotai

```tsx
import { atom, useAtom, useAtomValue, useSetAtom } from 'jotai'
import { atomWithStorage } from 'jotai/utils'

// Primitive atoms
const countAtom = atom(0)
const themeAtom = atomWithStorage<'light' | 'dark'>('theme', 'light')

// Derived atom (read-only)
const doubleCountAtom = atom((get) => get(countAtom) * 2)

// Derived atom (read-write)
const countWithMinAtom = atom(
  (get) => get(countAtom),
  (get, set, newValue: number) => {
    set(countAtom, Math.max(0, newValue))
  },
)

// Async atom
const userAtom = atom(async () => {
  const response = await fetch('/api/user')
  return response.json()
})

// Usage
function Counter() {
  const [count, setCount] = useAtom(countAtom)
  const doubleCount = useAtomValue(doubleCountAtom)
  const setTheme = useSetAtom(themeAtom)
  // ...
}
```

- Atoms are bottom-up: start with primitive atoms and compose them into derived atoms.
- Jotai eliminates the need for React Context for most global state use cases.
- Use `Provider` only when you need state isolation (e.g., in tests or embedded widgets).

## Global State: Redux Toolkit

```tsx
import { createSlice, configureStore, createAsyncThunk } from '@reduxjs/toolkit'

// Slice
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
      .addCase(fetchUsers.fulfilled, (state, action) => {
        state.users = action.payload
        state.loading = false
      })
      .addCase(fetchUsers.rejected, (state, action) => {
        state.error = action.error.message ?? 'Failed to fetch'
        state.loading = false
      })
  },
})

// Async thunk
const fetchUsers = createAsyncThunk('user/fetchUsers', async () => {
  const response = await fetch('/api/users')
  return response.json()
})

// RTK Query
import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react'

const api = createApi({
  baseQuery: fetchBaseQuery({ baseUrl: '/api' }),
  tagTypes: ['User'],
  endpoints: (builder) => ({
    getUsers: builder.query<User[], void>({
      query: () => 'users',
      providesTags: ['User'],
    }),
    updateUser: builder.mutation<User, Partial<User> & { id: string }>({
      query: ({ id, ...patch }) => ({ url: `users/${id}`, method: 'PATCH', body: patch }),
      invalidatesTags: ['User'],
    }),
  }),
})
```

- Use `createEntityAdapter` for normalized collections (lists of items with IDs).
- Use `createSelector` from Reselect (included in RTK) for memoized derived state.
- Keep the store shape flat and normalized.

## URL State

```tsx
// nuqs: type-safe URL search params for React
import { useQueryState, parseAsInteger, parseAsStringEnum } from 'nuqs'

function ProductList() {
  const [page, setPage] = useQueryState('page', parseAsInteger.withDefault(1))
  const [sort, setSort] = useQueryState(
    'sort',
    parseAsStringEnum(['price', 'name', 'date']).withDefault('name')
  )
  const [search, setSearch] = useQueryState('q', { defaultValue: '' })

  // URL: /products?page=2&sort=price&q=laptop
}
```

- URL state is the source of truth for pagination, filters, search, and selected tabs.
- Benefits: bookmarkable, shareable, browser back/forward works, SSR-compatible.

## Form State

```tsx
// React Hook Form with Zod validation
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

const schema = z.object({
  email: z.string().email('Invalid email'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  role: z.enum(['admin', 'user', 'editor']),
})

type FormData = z.infer<typeof schema>

function LoginForm() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: { email: '', password: '', role: 'user' },
  })

  const onSubmit = async (data: FormData) => {
    await api.login(data)
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('email')} />
      {errors.email && <span role="alert">{errors.email.message}</span>}
      {/* ... */}
    </form>
  )
}
```

- Keep form state local. Do not store transient input values in global state.
- Use Zod schemas for validation that is shared between client and server.

## State Machines: XState

```tsx
import { createMachine, assign } from 'xstate'
import { useMachine } from '@xstate/react'

const fetchMachine = createMachine({
  id: 'fetch',
  initial: 'idle',
  context: { data: null as Data | null, error: null as string | null, retries: 0 },
  states: {
    idle: {
      on: { FETCH: 'loading' },
    },
    loading: {
      invoke: {
        src: 'fetchData',
        onDone: {
          target: 'success',
          actions: assign({ data: ({ event }) => event.output }),
        },
        onError: [
          {
            target: 'loading',
            guard: ({ context }) => context.retries < 3,
            actions: assign({ retries: ({ context }) => context.retries + 1 }),
          },
          {
            target: 'error',
            actions: assign({ error: ({ event }) => event.error.message }),
          },
        ],
      },
    },
    success: {
      on: { REFRESH: 'loading' },
    },
    error: {
      on: { RETRY: { target: 'loading', actions: assign({ retries: 0 }) } },
    },
  },
})

function DataComponent() {
  const [state, send] = useMachine(fetchMachine, {
    actors: { fetchData: fromPromise(() => api.getData()) },
  })

  if (state.matches('loading')) return <Spinner />
  if (state.matches('error')) return <Error message={state.context.error} onRetry={() => send({ type: 'RETRY' })} />
  if (state.matches('success')) return <DataView data={state.context.data} />
  return <button onClick={() => send({ type: 'FETCH' })}>Load Data</button>
}
```

- Use XState for complex UI state with well-defined states and transitions: multi-step forms, media players, connection status, drag-and-drop workflows.
- State machines make impossible states impossible. If "loading" and "error" cannot coexist, the machine enforces that constraint by design.
- Use the XState visualizer (stately.ai/viz) to diagram and validate state machines before implementation.

## Signal-Based State

- **Preact signals**: Fine-grained reactivity without virtual DOM diffing. Signals update only the DOM nodes that depend on them.

```tsx
import { signal, computed, effect } from '@preact/signals-react'

const count = signal(0)
const doubled = computed(() => count.value * 2)

effect(() => {
  console.log(`Count is ${count.value}`)
})

// Signals can be used directly in JSX without hooks
function Counter() {
  return <button onClick={() => count.value++}>{count}</button>
}
```

- **Angular signals**: See the Angular Expert skill for `signal()`, `computed()`, `effect()`, `input()`, `output()`.
- **SolidJS signals**: Similar API to Preact signals. `createSignal()`, `createMemo()`, `createEffect()`.
- Signal-based state is the future direction for most frameworks, providing fine-grained reactivity without the overhead of virtual DOM diffing or selector-based memoization.

## Vue State: Pinia

```ts
// See Vue Expert skill for full Pinia patterns
import { defineStore } from 'pinia'

export const useCounterStore = defineStore('counter', () => {
  const count = ref(0)
  const doubled = computed(() => count.value * 2)
  function increment() { count.value++ }
  return { count, doubled, increment }
})
```

- Use `storeToRefs()` for reactive destructuring. Use composables as state containers for component-scoped reactive logic.

## State Normalization

```tsx
// Entity adapter pattern (Redux Toolkit)
import { createEntityAdapter } from '@reduxjs/toolkit'

const usersAdapter = createEntityAdapter<User>({
  selectId: (user) => user.id,
  sortComparer: (a, b) => a.name.localeCompare(b.name),
})

const initialState = usersAdapter.getInitialState({ loading: false })

// Normalized shape: { ids: ['1', '2'], entities: { '1': {...}, '2': {...} } }

// Built-in selectors
const { selectAll, selectById, selectIds } = usersAdapter.getSelectors()
```

- Normalize state when entities reference each other (users, posts, comments). Flat structure prevents data duplication and simplifies updates.
- TanStack Query normalizes server cache automatically per query key.

## Performance Optimization

| Technique | Tool | Purpose |
|---|---|---|
| Selector memoization | `createSelector`, Zustand selectors | Prevent re-computation of derived data |
| Structural sharing | TanStack Query (built-in) | Preserve referential equality for unchanged parts |
| Subscription granularity | Zustand selectors, Jotai atoms | Re-render only components that use changed data |
| Lazy initialization | `useState(() => ...)` | Avoid expensive computations on every render |
| State colocation | Local state | Reduce global store size, isolate re-renders |

### Stale Closure Prevention

```tsx
// Problem: stale closure captures old value
useEffect(() => {
  const interval = setInterval(() => {
    setCount(count + 1) // always uses initial count
  }, 1000)
  return () => clearInterval(interval)
}, []) // missing dependency

// Solution: functional update
useEffect(() => {
  const interval = setInterval(() => {
    setCount(prev => prev + 1) // always uses latest
  }, 1000)
  return () => clearInterval(interval)
}, [])

// Solution: ref for latest value
const countRef = useRef(count)
countRef.current = count
```

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Solution |
|---|---|---|
| Prop drilling through 5+ levels | Verbose, fragile, hard to refactor | Zustand, Jotai, Context, or component composition |
| Duplicating server data in stores | Two sources of truth, stale data | Use TanStack Query / SWR as the single cache |
| Single global store for everything | Everything re-renders, hard to split | Domain-specific stores, colocation |
| Storing derived data | Stale derivations, extra syncing | Use selectors, computed, derived atoms |
| Form state in global store | Over-coupling, unnecessary complexity | React Hook Form, local state |
| Unnecessary global state | Performance overhead, complexity | Keep state local unless sharing is required |
| Not cleaning up subscriptions | Memory leaks | Use cleanup functions, takeUntilDestroyed, hooks |

## Migration Strategies

- **Redux to Zustand**: Replace one slice at a time. Both can coexist. Move selectors, then actions, then remove the Redux slice.
- **Context to Zustand/Jotai**: Extract context value into a store. Replace `useContext` calls with store hooks. Remove the Provider.
- **Class components to hooks**: Extract state logic into custom hooks first, then convert components.
- **Any library to TanStack Query**: Identify server state in your global stores. Replace with `useQuery`/`useMutation`. Remove the now-empty store slices.
- General principle: migrate incrementally, one feature at a time. Old and new state tools can coexist during migration.
