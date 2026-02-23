# React Testing Patterns

## When to load
Load when testing React components: Testing Library, user-event, render patterns, hooks.

## Core Pattern

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

test('submits order form', async () => {
  const onSubmit = vi.fn();
  const user = userEvent.setup();

  render(<OrderForm onSubmit={onSubmit} />);

  await user.type(screen.getByLabelText('Product'), 'Widget');
  await user.type(screen.getByLabelText('Quantity'), '5');
  await user.click(screen.getByRole('button', { name: 'Submit' }));

  expect(onSubmit).toHaveBeenCalledWith(
    expect.objectContaining({ product: 'Widget', quantity: 5 })
  );
});
```

## Query Priority

```
1. getByRole('button', { name: 'Submit' })   — accessible
2. getByLabelText('Email')                     — form inputs
3. getByPlaceholderText('Search...')            — when no label
4. getByText('Welcome back')                   — visible content
5. getByTestId('order-total')                  — last resort

screen.getByX: throws if not found (use for assertions)
screen.queryByX: returns null if not found (use for absence)
screen.findByX: async, waits for element (use for loading)
```

## Testing Async Components

```typescript
test('loads and displays user data', async () => {
  // MSW handles API mocking at network level
  render(<UserProfile userId="123" />);

  // Loading state
  expect(screen.getByText('Loading...')).toBeInTheDocument();

  // Loaded state
  expect(await screen.findByText('Alice')).toBeInTheDocument();
  expect(screen.queryByText('Loading...')).not.toBeInTheDocument();
});
```

## Testing Custom Hooks

```typescript
import { renderHook, act } from '@testing-library/react';

test('useCounter increments', () => {
  const { result } = renderHook(() => useCounter(0));

  expect(result.current.count).toBe(0);

  act(() => result.current.increment());
  expect(result.current.count).toBe(1);
});
```

## Wrapper for Providers

```typescript
function renderWithProviders(ui: React.ReactElement, options = {}) {
  return render(ui, {
    wrapper: ({ children }) => (
      <QueryClientProvider client={new QueryClient()}>
        <ThemeProvider>{children}</ThemeProvider>
      </QueryClientProvider>
    ),
    ...options,
  });
}
```

## Anti-patterns
- Testing implementation details (state values, component internals)
- `container.querySelector('.class-name')` → use accessible queries
- `fireEvent` instead of `userEvent` → userEvent simulates real user behavior
- Snapshot tests for interactive components → test behavior, not markup

## Quick reference
```
userEvent.setup(): always use over fireEvent
getByRole: primary query for everything
findByX: async — waits for element to appear
queryByX: check absence (returns null)
renderHook: test custom hooks in isolation
act(): wrap state updates in hook tests
Wrapper: provide context/providers via render options
```
