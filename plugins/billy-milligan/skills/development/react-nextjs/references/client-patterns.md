# Client Patterns

## State Management: Zustand

```tsx
// stores/cart-store.ts — lightweight, no boilerplate
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface CartStore {
  items: CartItem[];
  addItem: (item: CartItem) => void;
  removeItem: (id: string) => void;
  total: () => number;
}

export const useCart = create<CartStore>()(
  persist(
    (set, get) => ({
      items: [],
      addItem: (item) =>
        set((state) => {
          const existing = state.items.find((i) => i.id === item.id);
          if (existing) {
            return {
              items: state.items.map((i) =>
                i.id === item.id ? { ...i, quantity: i.quantity + 1 } : i
              ),
            };
          }
          return { items: [...state.items, { ...item, quantity: 1 }] };
        }),
      removeItem: (id) =>
        set((state) => ({ items: state.items.filter((i) => i.id !== id) })),
      total: () => get().items.reduce((sum, i) => sum + i.price * i.quantity, 0),
    }),
    { name: 'cart-storage' }
  )
);
```

## State Management: Jotai (Atomic)

```tsx
import { atom, useAtom } from 'jotai';
import { atomWithStorage } from 'jotai/utils';

// Atoms — smallest unit of state
const searchQueryAtom = atom('');
const filtersAtom = atomWithStorage('filters', { status: 'all', sort: 'date' });

// Derived atoms — computed automatically
const filteredOrdersAtom = atom(async (get) => {
  const query = get(searchQueryAtom);
  const filters = get(filtersAtom);
  const res = await fetch(`/api/orders?q=${query}&status=${filters.status}`);
  return res.json();
});
```

## Forms: react-hook-form + Zod

```tsx
'use client';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const schema = z.object({
  email: z.string().email('Invalid email'),
  name: z.string().min(2, 'Name too short').max(100),
  role: z.enum(['admin', 'user', 'editor']),
});

type FormData = z.infer<typeof schema>;

export function UserForm({ onSubmit }: { onSubmit: (data: FormData) => Promise<void> }) {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormData>({ resolver: zodResolver(schema) });

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('email')} placeholder="Email" />
      {errors.email && <span>{errors.email.message}</span>}

      <input {...register('name')} placeholder="Name" />
      {errors.name && <span>{errors.name.message}</span>}

      <select {...register('role')}>
        <option value="user">User</option>
        <option value="editor">Editor</option>
        <option value="admin">Admin</option>
      </select>

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Saving...' : 'Save'}
      </button>
    </form>
  );
}
```

## Optimistic UI with useOptimistic

```tsx
'use client';
import { useOptimistic, useTransition } from 'react';

export function LikeButton({ postId, initialLikes }: { postId: string; initialLikes: number }) {
  const [isPending, startTransition] = useTransition();
  const [optimisticLikes, setOptimisticLikes] = useOptimistic(initialLikes);

  async function handleLike() {
    startTransition(async () => {
      setOptimisticLikes((prev) => prev + 1); // Instant UI update
      await likePost(postId);                 // Server Action — may take 200ms
    });
  }

  return (
    <button onClick={handleLike} disabled={isPending}>
      {optimisticLikes} likes
    </button>
  );
}
```

## URL State for Filters

```tsx
'use client';
import { useRouter, useSearchParams, usePathname } from 'next/navigation';

export function Filters() {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  function updateFilter(key: string, value: string) {
    const params = new URLSearchParams(searchParams.toString());
    value ? params.set(key, value) : params.delete(key);
    params.set('page', '1');
    router.push(`${pathname}?${params.toString()}`);
  }

  return (
    <select
      value={searchParams.get('status') ?? ''}
      onChange={(e) => updateFilter('status', e.target.value)}
    >
      <option value="">All</option>
      <option value="pending">Pending</option>
      <option value="completed">Completed</option>
    </select>
  );
}
// Prefer URL state over useState — survives refresh, shareable, bookmarkable
```

## Quick Reference
```
Zustand: simple global state, persist middleware for localStorage
Jotai: atomic state, derived atoms for computed values
react-hook-form + Zod: schema-first validation, no re-renders on typing
useOptimistic: instant UI update, reconcile after server response
URL state: useSearchParams for filters/pagination — not useState
```
