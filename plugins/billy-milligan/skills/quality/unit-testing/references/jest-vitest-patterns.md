# Jest/Vitest Patterns

## When to load
Load when writing unit tests with Jest or Vitest: setup, mocking, async, snapshots.

## Configuration

```typescript
// vitest.config.ts (preferred — 10x faster than Jest)
export default defineConfig({
  test: {
    globals: true,
    environment: 'node', // or 'jsdom' for browser
    coverage: { provider: 'v8', reporter: ['text', 'lcov'], thresholds: { lines: 80 } },
    include: ['src/**/*.test.ts'],
    setupFiles: ['./tests/setup.ts'],
  },
});
```

## Test Structure

```typescript
describe('OrderService', () => {
  let service: OrderService;
  let mockRepo: MockProxy<OrderRepository>;

  beforeEach(() => {
    mockRepo = mock<OrderRepository>();
    service = new OrderService(mockRepo);
  });

  it('creates order with correct total', async () => {
    // Arrange
    const items = [{ productId: '1', qty: 2, price: 1999 }];
    mockRepo.save.mockResolvedValue({ id: 'order-1', total: 3998 });

    // Act
    const order = await service.create(items);

    // Assert
    expect(order.total).toBe(3998);
    expect(mockRepo.save).toHaveBeenCalledWith(
      expect.objectContaining({ total: 3998 })
    );
  });

  it.each([
    { items: [], error: 'Order must have at least one item' },
    { items: [{ qty: -1 }], error: 'Quantity must be positive' },
  ])('rejects invalid input: $error', async ({ items, error }) => {
    await expect(service.create(items)).rejects.toThrow(error);
  });
});
```

## Async Testing

```typescript
// Promise resolution
it('resolves with user data', async () => {
  const user = await getUser('123');
  expect(user.name).toBe('Alice');
});

// Promise rejection
it('rejects for invalid ID', async () => {
  await expect(getUser('invalid')).rejects.toThrow('Not found');
});

// Timer mocking
it('debounces search', () => {
  vi.useFakeTimers();
  const handler = vi.fn();
  const debounced = debounce(handler, 300);

  debounced('query');
  debounced('query2');
  vi.advanceTimersByTime(300);

  expect(handler).toHaveBeenCalledTimes(1);
  expect(handler).toHaveBeenCalledWith('query2');
  vi.useRealTimers();
});
```

## Anti-patterns
- Testing implementation details → test behavior, not internal state
- `expect(fn).toHaveBeenCalled()` without checking args → weak assertion
- Tests that depend on order → use `beforeEach` to reset state
- Snapshot tests for logic → use snapshots only for serialized output (React trees, configs)

## Quick reference
```
Vitest: 10x faster than Jest, compatible API
Arrange-Act-Assert: every test follows this pattern
it.each: parametrized tests for input variations
vi.fn(): create mock function
vi.useFakeTimers(): control Date.now() and setTimeout
mockResolvedValue: mock async return value
Coverage: v8 provider, 80% line threshold
```
