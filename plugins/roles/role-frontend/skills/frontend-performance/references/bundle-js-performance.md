# Bundle and JavaScript Performance

## When to load
Load when reducing JavaScript payload (code splitting, tree shaking, dynamic imports) or optimizing main-thread work (Web Workers, scheduler APIs, virtualization).

## Code Splitting

```tsx
// Route-based splitting (React)
const Dashboard = lazy(() => import('./pages/Dashboard'))
const Settings = lazy(() => import('./pages/Settings'))

// Component-based splitting
const HeavyEditor = lazy(() => import('./components/RichTextEditor'))

// Library-based — only import when needed
async function handleExport() {
  const { jsPDF } = await import('jspdf')
  const doc = new jsPDF()
}
```

### Dynamic Import Patterns

```tsx
// Prefetch on hover (load before user clicks)
<Link to="/dashboard" onMouseEnter={() => import('./pages/Dashboard')}>
  Dashboard
</Link>

// Load on interaction
function CommentSection() {
  const [Editor, setEditor] = useState<ComponentType | null>(null)
  return Editor ? <Editor /> : (
    <button onClick={async () => {
      const { RichEditor } = await import('./RichEditor')
      setEditor(() => RichEditor)
    }}>Write a comment</button>
  )
}
```

## Tree Shaking

- Use ES module syntax (`import`/`export`) exclusively. CommonJS (`require`) cannot be tree-shaken.
- Ensure `package.json` includes `"sideEffects": false` for libraries.
- Import only what you need: `import { debounce } from 'lodash-es'` instead of `import _ from 'lodash'`.
- Avoid barrel files (`index.ts` re-exports) for large libraries — they can prevent tree shaking.

## Main Thread Optimization

```typescript
// Web Worker for CPU-intensive tasks
// worker.ts
self.onmessage = (event: MessageEvent<{ items: Item[] }>) => {
  const result = expensiveComputation(event.data.items)
  self.postMessage(result)
}

// main.ts
const worker = new Worker(new URL('./worker.ts', import.meta.url), { type: 'module' })
worker.postMessage({ items: largeDataset })
worker.onmessage = (event) => updateUI(event.data)

// requestIdleCallback for non-critical work
function deferAnalytics(data: AnalyticsEvent) {
  if ('requestIdleCallback' in window) {
    requestIdleCallback(() => sendAnalytics(data), { timeout: 2000 })
  } else {
    setTimeout(() => sendAnalytics(data), 0)
  }
}

// scheduler.postTask for priority-based scheduling
async function handleUserClick() {
  await scheduler.postTask(() => updateClickFeedback(), { priority: 'user-blocking' })
  scheduler.postTask(() => trackClick(), { priority: 'background' })
}
```

## React Performance

```tsx
// React.memo: skip re-render when props haven't changed
const ExpensiveList = memo(function ExpensiveList({ items }: { items: Item[] }) {
  return items.map(item => <ExpensiveItem key={item.id} item={item} />)
})

// useMemo / useCallback
const filteredItems = useMemo(() => items.filter(i => i.name.includes(search)), [items, search])
const handleClick = useCallback((id: string) => setSelected(id), [])

// useTransition: mark state updates as non-urgent
function SearchResults() {
  const [isPending, startTransition] = useTransition()
  function handleChange(e: ChangeEvent<HTMLInputElement>) {
    setQuery(e.target.value)
    startTransition(() => setFilteredResults(filterLargeList(e.target.value)))
  }
  return <>{isPending && <Spinner />}<ResultsList results={filteredResults} /></>
}
```

- React Compiler (React 19+): automatically adds memoization at build time. Remove manual memo calls in compiler-enabled codebases.

## Virtualization

```tsx
import { useVirtualizer } from '@tanstack/react-virtual'

function VirtualList({ items }: { items: Item[] }) {
  const parentRef = useRef<HTMLDivElement>(null)
  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 50,
    overscan: 5,
  })
  return (
    <div ref={parentRef} style={{ height: '400px', overflow: 'auto' }}>
      <div style={{ height: `${virtualizer.getTotalSize()}px`, position: 'relative' }}>
        {virtualizer.getVirtualItems().map((row) => (
          <div key={row.key} style={{ position: 'absolute', top: 0, transform: `translateY(${row.start}px)`, height: `${row.size}px` }}>
            {items[row.index].name}
          </div>
        ))}
      </div>
    </div>
  )
}
```

## Performance Budget

```json
{
  "size-limit": [
    { "path": "dist/index.js", "limit": "80 KB", "gzip": true },
    { "path": "dist/vendor.js", "limit": "150 KB", "gzip": true },
    { "path": "dist/**/*.css", "limit": "30 KB", "gzip": true }
  ]
}
```

| Resource Type | Budget (gzipped) |
|---|---|
| Total JavaScript | < 200 KB |
| Single route bundle | < 80 KB |
| Total CSS | < 50 KB |
| Hero image | < 100 KB |
| Web fonts | < 100 KB |
| Total page weight | < 1 MB |
