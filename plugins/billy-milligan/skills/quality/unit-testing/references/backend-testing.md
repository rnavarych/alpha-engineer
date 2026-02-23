# Backend Testing Patterns

## When to load
Load when testing APIs, services, repositories: Supertest, database testing, test isolation.

## API/Controller Testing

```typescript
import request from 'supertest';
import { app } from '../app';

describe('POST /api/orders', () => {
  it('creates order and returns 201', async () => {
    const res = await request(app)
      .post('/api/orders')
      .set('Authorization', `Bearer ${testToken}`)
      .send({ items: [{ productId: '1', quantity: 2 }] })
      .expect(201);

    expect(res.body).toMatchObject({
      id: expect.any(String),
      status: 'pending',
      total: expect.any(Number),
    });
  });

  it('returns 400 for empty items', async () => {
    const res = await request(app)
      .post('/api/orders')
      .set('Authorization', `Bearer ${testToken}`)
      .send({ items: [] })
      .expect(400);

    expect(res.body.error).toBe('Order must have at least one item');
  });

  it('returns 401 without auth', async () => {
    await request(app).post('/api/orders').send({ items: [] }).expect(401);
  });
});
```

## Service Layer Testing

```typescript
describe('OrderService', () => {
  let service: OrderService;
  let mockOrderRepo: MockProxy<OrderRepository>;
  let mockPaymentService: MockProxy<PaymentService>;

  beforeEach(() => {
    mockOrderRepo = mock<OrderRepository>();
    mockPaymentService = mock<PaymentService>();
    service = new OrderService(mockOrderRepo, mockPaymentService);
  });

  it('processes payment and saves order', async () => {
    mockPaymentService.charge.mockResolvedValue({ transactionId: 'tx-1' });
    mockOrderRepo.save.mockResolvedValue({ id: 'order-1', total: 4999 });

    const order = await service.create({ items: [{ price: 4999 }] });

    expect(mockPaymentService.charge).toHaveBeenCalledWith(4999);
    expect(mockOrderRepo.save).toHaveBeenCalledWith(
      expect.objectContaining({ total: 4999, transactionId: 'tx-1' })
    );
  });
});
```

## Database Testing with Testcontainers

```typescript
import { PostgreSqlContainer } from '@testcontainers/postgresql';

let container: StartedPostgreSqlContainer;
let db: Pool;

beforeAll(async () => {
  container = await new PostgreSqlContainer().start();
  db = new Pool({ connectionString: container.getConnectionUri() });
  await runMigrations(db);
}, 60_000); // Container startup can take time

afterAll(async () => {
  await db.end();
  await container.stop();
});

// Per-test isolation with transactions
beforeEach(async () => {
  await db.query('BEGIN');
});
afterEach(async () => {
  await db.query('ROLLBACK');
});
```

## Anti-patterns
- Testing against shared database → tests interfere with each other
- No transaction rollback → data accumulates across tests
- Mocking the database in integration tests → defeats the purpose
- Testing private methods directly → test through public API

## Quick reference
```
Controller tests: Supertest, test HTTP status + response body
Service tests: mock repositories + external services
Repository tests: real DB (Testcontainers) or per-test transactions
Isolation: BEGIN/ROLLBACK per test, or per-worker schemas
Auth: generate test JWT tokens, test 401/403 cases
Timeout: 60s for container startup in beforeAll
```
