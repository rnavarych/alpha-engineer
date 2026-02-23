# GraphQL Patterns

## When to load
Load when designing GraphQL APIs, handling N+1, or choosing between GraphQL and REST.

## Patterns ✅

### Schema design
```graphql
type Query {
  order(id: ID!): Order
  orders(first: Int = 20, after: String, filter: OrderFilter): OrderConnection!
}

type OrderConnection {
  edges: [OrderEdge!]!
  pageInfo: PageInfo!
}

type OrderEdge {
  cursor: String!
  node: Order!
}

input OrderFilter {
  status: OrderStatus
  createdAfter: DateTime
}

type Mutation {
  createOrder(input: CreateOrderInput!): CreateOrderPayload!
}

type CreateOrderPayload {
  order: Order
  errors: [UserError!]!
}

type UserError {
  field: [String!]
  message: String!
}
```
Rules: Relay connection spec for pagination, input types for mutations, payload types with errors.

### N+1 prevention with DataLoader
```typescript
// Without DataLoader: orders.map(o => db.users.findById(o.userId)) → N queries
// With DataLoader: batch all user IDs into single query

import DataLoader from 'dataloader';

const userLoader = new DataLoader<string, User>(async (ids) => {
  const users = await db.users.findMany({ where: { id: { in: [...ids] } } });
  const userMap = new Map(users.map(u => [u.id, u]));
  return ids.map(id => userMap.get(id) ?? new Error(`User ${id} not found`));
});

// Resolver: resolve User field on Order
const resolvers = {
  Order: {
    user: (order) => userLoader.load(order.userId), // Batched automatically
  },
};
```

### Persisted queries
Store queries server-side, client sends only hash. Reduces payload size, prevents arbitrary queries.
```
POST /graphql { "extensions": { "persistedQuery": { "sha256Hash": "abc123" } } }
```

## Anti-patterns ❌
- No query depth/complexity limits → clients can craft exponentially expensive queries
- Exposing entire DB schema → over-fetching, security risk
- N+1 without DataLoader → 100 orders = 101 queries

## Decision criteria
| Factor | REST | GraphQL |
|--------|------|---------|
| Multiple clients with different data needs | REST + BFF | GraphQL ✓ |
| Simple CRUD API | REST ✓ | Overkill |
| Real-time subscriptions | SSE/WebSocket | GraphQL subscriptions ✓ |
| Caching | HTTP caching ✓ | Requires normalized cache |
| File uploads | REST ✓ | Complex multipart spec |
