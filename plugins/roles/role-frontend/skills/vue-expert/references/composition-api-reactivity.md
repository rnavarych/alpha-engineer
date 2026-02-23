# Composition API and Reactivity

## When to load
Load when writing Vue 3 components with `<script setup>`, working with ref/reactive/computed/watch, or building composable functions.

## script setup Basics

- Use `<script setup>` as the default for single-file components — less boilerplate, better TypeScript inference.
- **ref vs reactive**: Use `ref()` for primitives and single values. Use `reactive()` for objects where you want to avoid `.value`. Do not destructure reactive objects — it breaks reactivity. Use `toRefs()` if destructuring is needed.

```vue
<script setup lang="ts">
import { ref, reactive, toRefs } from 'vue'

const count = ref(0)
const name = ref<string>('Vue')

const state = reactive({ items: [] as string[], loading: false })
const { items, loading } = toRefs(state) // safe destructuring
</script>
```

## Computed and Watch

```ts
// computed: cached, recalculates only when dependencies change
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

// watch: specific source, access to old/new values
watch(searchQuery, (newVal, oldVal) => {
  if (newVal !== oldVal) fetchResults(newVal)
}, { debounce: 300 })

// watchEffect: auto-tracks all reactive dependencies
watchEffect((onCleanup) => {
  const controller = new AbortController()
  fetch(`/api/items?q=${query.value}`, { signal: controller.signal })
  onCleanup(() => controller.abort())
})
```

- Prefer `computed()` over watchers for synchronous derivations.
- Always clean up side effects in `onCleanup` callback inside `watchEffect`.

## Script Setup Macros

```vue
<script setup lang="ts">
// Type-based props (preferred)
const props = withDefaults(defineProps<{
  title: string
  count?: number
  items: string[]
}>(), { count: 0 })

// Typed emits
const emit = defineEmits<{
  update: [value: string]
  delete: [id: number]
  'update:modelValue': [value: boolean]
}>()

// defineModel: two-way binding (Vue 3.4+)
const modelValue = defineModel<string>()
const title = defineModel<string>('title')

// defineExpose: explicitly expose for template refs
function reset() { internalState.value = 0 }
defineExpose({ reset })

// defineSlots: type-safe slots (Vue 3.3+)
const slots = defineSlots<{
  default: (props: { item: Item; index: number }) => any
  header: () => any
}>()
</script>
```

## Composables

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

  watchEffect(() => execute())
  return { data, error, loading, execute }
}
```

- Prefix composables with `use`. Return reactive state and methods as a plain object.
- Composables can call other composables. Register cleanup in `onUnmounted`.

## Performance Primitives

```ts
// shallowRef / shallowReactive: top-level reactivity only
const largeList = shallowRef<Item[]>([])
largeList.value = [...largeList.value, newItem] // trigger by new reference

// v-memo: skip re-rendering list items when deps unchanged
// <div v-for="item in list" :key="item.id" v-memo="[item.id, item.updated]">

// defineAsyncComponent: lazy-load heavy components
const HeavyChart = defineAsyncComponent({
  loader: () => import('./HeavyChart.vue'),
  loadingComponent: LoadingSpinner,
  errorComponent: ErrorFallback,
  delay: 200,
  timeout: 10000,
})
```
