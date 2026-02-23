# GraphQL and tRPC

## When to load
Load when designing GraphQL schemas, implementing Federation, setting up subscriptions, or building type-safe tRPC APIs.

## tRPC

End-to-end typesafe APIs for TypeScript full-stack. No code generation, no schema files.

```typescript
export const userRouter = router({
  list: publicProcedure
    .input(z.object({ cursor: z.string().optional(), limit: z.number().min(1).max(100).default(20) }))
    .query(async ({ input, ctx }) => {
      const users = await ctx.db.user.findMany({ take: input.limit + 1, cursor: input.cursor ? { id: input.cursor } : undefined });
      return { users, nextCursor: users.length > input.limit ? users[input.limit].id : null };
    }),
  create: protectedProcedure
    .input(z.object({ email: z.string().email(), name: z.string().min(1) }))
    .mutation(async ({ input, ctx }) => ctx.db.user.create({ data: input })),
});

// Middleware + nested routers
const protectedProcedure = publicProcedure.use(async ({ ctx, next }) => {
  if (!ctx.session?.user) throw new TRPCError({ code: 'UNAUTHORIZED' });
  return next({ ctx: { ...ctx, user: ctx.session.user } });
});

// OpenAPI export (trpc-openapi)
getUser: publicProcedure
  .meta({ openapi: { method: 'GET', path: '/users/{id}', tags: ['users'] } })
  .input(z.object({ id: z.string() })).output(UserSchema)
  .query(({ input }) => db.user.findUnique({ where: { id: input.id } })),
```

- Subscriptions via WebSocket for real-time updates
- Use with TanStack Query adapter; SWR adapter available

## GraphQL Design Principles

- Use connections pattern (Relay spec) for all paginated lists
- Implement DataLoader for N+1 prevention (batch + deduplicate DB queries)
- Limit query depth (max 10) and complexity (weighted scoring)
- Use persisted queries in production (prevent arbitrary query execution)
- Input types for mutations; never reuse query types as mutation inputs

## DataLoader, Complexity, Persisted Queries

```javascript
// DataLoader (N+1 Prevention)
const userLoader = new DataLoader(async (userIds) => {
  const users = await db.user.findMany({ where: { id: { in: userIds } } });
  const map = new Map(users.map(u => [u.id, u]));
  return userIds.map(id => map.get(id) ?? new Error(`User ${id} not found`));
});
const Post = { author: (post) => userLoader.load(post.authorId) };

// Query Complexity Analysis
const server = new ApolloServer({
  validationRules: [
    depthLimit(10),
    createComplexityRule({ maximumComplexity: 1000, estimators: [fieldExtensionsEstimator(), simpleEstimator({ defaultComplexity: 1 })] }),
  ],
});
```

## GraphQL Federation (Apollo Federation 2)

```graphql
type Product @key(fields: "id") { id: ID!  name: String!  price: Float! }

# Reviews subgraph — extends Product without importing full type
extend type Product @key(fields: "id") { id: ID! @external  reviews: [Review!]! }

type User @key(fields: "id") @shareable { id: ID!  email: String! @shareable }
```

- **Apollo Router** (Rust): High-performance federation gateway, supergraph composition
- **Cosmo (WunderGraph)**: Open-source Apollo Federation alternative, GraphQL CDN
- **GraphQL Mesh**: Schema stitching + transform, multiple source types (REST, gRPC, SOAP, DB)

## GraphQL Subscriptions and Redis Fan-out

```graphql
subscription OnMessageAdded($channelId: ID!) {
  messageAdded(channelId: $channelId) { id  text  sender { id name }  createdAt }
}
```

```javascript
const pubsub = new RedisPubSub({
  publisher: new Redis({ host: process.env.REDIS_HOST }),
  subscriber: new Redis({ host: process.env.REDIS_HOST }),
});
const resolvers = {
  Subscription: {
    messageAdded: {
      subscribe: withFilter(
        () => pubsub.asyncIterator(['MESSAGE_ADDED']),
        (payload, variables) => payload.messageAdded.channelId === variables.channelId
      ),
    },
  },
};
```

- Transport: WebSocket (`graphql-ws` protocol — replace deprecated `subscriptions-transport-ws`)
- SSE: `graphql-sse` for subscriptions over HTTP (works through proxies)
- Use Redis Pub/Sub or Kafka for multi-instance subscription fan-out
