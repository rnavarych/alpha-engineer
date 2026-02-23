# Server State: TanStack Query and SWR

## When to load
Load when fetching, caching, or mutating server data — queries, mutations, optimistic updates, infinite pagination, or prefetching with TanStack Query v5 or SWR.

## Queries

```tsx
function useUsers(filters: UserFilters) {
  return useQuery({
    queryKey: ['users', filters],
    queryFn: () => fetchUsers(filters),
    staleTime: 5 * 60 * 1000,           // fresh for 5 minutes
    gcTime: 30 * 60 * 1000,             // garbage collect after 30 min
    placeholderData: keepPreviousData,   // show stale data during refetch
    retry: 3,
    retryDelay: (attempt) => Math.min(1000 * 2 ** attempt, 30000),
  })
}
```

## Mutations with Optimistic Updates

```tsx
function useToggleTodo() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (todoId: string) => api.toggleTodo(todoId),
    onMutate: async (todoId) => {
      await queryClient.cancelQueries({ queryKey: ['todos'] })
      const previousTodos = queryClient.getQueryData<Todo[]>(['todos'])
      queryClient.setQueryData<Todo[]>(['todos'], (old) =>
        old?.map(todo => todo.id === todoId ? { ...todo, done: !todo.done } : todo)
      )
      return { previousTodos }
    },
    onError: (_err, _todoId, context) => {
      queryClient.setQueryData(['todos'], context?.previousTodos)
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['todos'] })
    },
  })
}
```

## Infinite Queries

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

## Prefetching

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
    >View User</Link>
  )
}
```

## SWR (Alternative)

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

- Never copy server data into a client state store. TanStack Query or SWR is the single source of truth for API data.
- TanStack Query normalizes server cache automatically per query key — no manual normalization needed.
