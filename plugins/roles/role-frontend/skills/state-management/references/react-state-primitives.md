# React State Primitives

## When to load
Load when working with useState, useReducer, useContext, useSyncExternalStore, or React 19 use() hook for local and shared UI state.

## State Category Decision

| Category | Examples | Recommended Tool |
|---|---|---|
| Local UI state | Modal open/close, toggle, hover | `useState`, `useReducer`, `ref()`, `signal()` |
| Shared UI state | Theme, sidebar collapsed, toasts | Zustand, Jotai, Context, Pinia |
| Server cache state | User profiles, product lists | TanStack Query, SWR, RTK Query |
| URL state | Pagination, filters, search, sort | `nuqs`, `searchParams`, router state |
| Form state | Input values, validation | React Hook Form, VeeValidate |

- **Keep it local** if state resets when the component unmounts and that is correct behavior.
- **Lift to global** if prop drilling goes through more than two intermediate components.
- **Use server state tools** for any data from an API — never copy server data into a client store.
- **Use the URL** for anything the user should be able to bookmark or share.

## useState and useReducer

```tsx
// Functional updates when new value depends on previous
const [count, setCount] = useState(0)
setCount(prev => prev + 1)

// Lazy initialization for expensive computations
const [data, setData] = useState(() => computeExpensiveDefault())

// useReducer for complex state transitions
type Action =
  | { type: 'add'; item: Item }
  | { type: 'remove'; id: string }
  | { type: 'toggle'; id: string }

function reducer(state: Item[], action: Action): Item[] {
  switch (action.type) {
    case 'add': return [...state, action.item]
    case 'remove': return state.filter(i => i.id !== action.id)
    case 'toggle': return state.map(i => i.id === action.id ? { ...i, done: !i.done } : i)
  }
}

const [items, dispatch] = useReducer(reducer, [])
```

- Use `useReducer` when multiple state values change together or next state depends on previous in non-trivial ways.

## useContext

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

- Use Context for **low-frequency** global state: theme, locale, auth status, feature flags.
- Never use Context for high-frequency updates — every change re-renders all consumers.
- Split contexts by concern. Avoid a single "AppContext" combining unrelated state.

## useSyncExternalStore and React 19 use()

```tsx
// Subscribe to external stores (browser APIs, third-party state)
function useOnlineStatus() {
  return useSyncExternalStore(
    (callback) => {
      window.addEventListener('online', callback)
      window.addEventListener('offline', callback)
      return () => { window.removeEventListener('online', callback); window.removeEventListener('offline', callback) }
    },
    () => navigator.onLine,
    () => true,  // server snapshot (SSR)
  )
}

// React 19 use() — reads promises and contexts inside render
function UserProfile({ userPromise }: { userPromise: Promise<User> }) {
  const user = use(userPromise) // suspends until resolved
  return <h1>{user.name}</h1>
}
```

## Stale Closure Prevention

```tsx
// Problem: stale closure captures old value
useEffect(() => {
  const interval = setInterval(() => setCount(count + 1), 1000)  // always uses initial count
  return () => clearInterval(interval)
}, []) // missing dependency

// Solution: functional update
useEffect(() => {
  const interval = setInterval(() => setCount(prev => prev + 1), 1000)
  return () => clearInterval(interval)
}, [])
```
