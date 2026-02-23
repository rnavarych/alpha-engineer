# OpenAPI, tRPC, and GraphQL Servers

## When to load
Load when generating OpenAPI specs or client code, setting up tRPC procedures, or implementing a GraphQL server in any language.

## OpenAPI 3.1 — Spec Generation (Code-First)

| Tool | Framework |
|------|-----------|
| `@nestjs/swagger` | NestJS |
| `@fastify/swagger` + `@fastify/swagger-ui` | Fastify |
| `@elysiajs/swagger` | ElysiaJS |
| `hono/swagger-ui` + `zod-openapi` | Hono |
| FastAPI (automatic) | Python/FastAPI |
| `springdoc-openapi` | Spring Boot |
| `quarkus-smallrye-openapi` | Quarkus |
| Swashbuckle / NSwag | ASP.NET Core |
| `poem-openapi` | Rust/Poem |
| `swag` | Go/Gin |

## Client Code Generation

**openapi-generator** (multi-language):
```bash
openapi-generator generate -i openapi.yaml -g typescript-axios -o ./src/generated/api
openapi-generator generate -i openapi.yaml -g go -o ./pkg/client
openapi-generator generate -i openapi.yaml -g python -o ./client
```

**orval** (TypeScript, React Query / SWR / Axios):
```bash
npx orval --config orval.config.ts
# Generates typed hooks: useGetUsers(), useCreateUser()
# Config: { input: './openapi.yaml', output: { target: './src/api', client: 'react-query' } }
```

**hey-api** (`@hey-api/openapi-ts`):
```bash
npx @hey-api/openapi-ts -i openapi.yaml -o src/client -c @hey-api/client-fetch
# Generates services, models, types with tree-shakeable structure
```

TypeScript-first generation best practices:
- Generate into `src/generated/` and never edit generated files manually
- Add `src/generated/` to `.gitignore` if spec is the source of truth
- Regenerate in CI to detect drift between spec and implementation

## tRPC Server

```typescript
import { initTRPC, TRPCError } from '@trpc/server'
import { z } from 'zod'

interface Context { userId?: string }
const t = initTRPC.context<Context>().create()

const isAuthed = t.middleware(({ ctx, next }) => {
  if (!ctx.userId) throw new TRPCError({ code: 'UNAUTHORIZED' })
  return next({ ctx: { ...ctx, userId: ctx.userId } })
})

const protectedProcedure = t.procedure.use(isAuthed)

export const appRouter = t.router({
  users: t.router({
    getById: protectedProcedure
      .input(z.object({ id: z.string().uuid() }))
      .query(async ({ input }) => userService.findById(input.id)),
    create: protectedProcedure
      .input(z.object({ email: z.string().email(), name: z.string().min(2) }))
      .mutation(async ({ input, ctx }) =>
        userService.create({ ...input, createdBy: ctx.userId })),
  }),
})

export type AppRouter = typeof appRouter
// Mount on Express: app.use('/trpc', createExpressMiddleware({ router: appRouter, createContext }))
// Mount on Fastify: app.register(fastifyTRPCPlugin, { prefix: '/trpc', trpcOptions: { router: appRouter } })
```

## GraphQL Servers

### Apollo Server 4 (Node.js)

```typescript
import { ApolloServer } from '@apollo/server'

const typeDefs = `#graphql
  type User { id: ID!, email: String!, name: String! }
  type Query { user(id: ID!): User, users(limit: Int, cursor: String): UserConnection! }
  type Mutation { createUser(input: CreateUserInput!): User! }
  input CreateUserInput { email: String!, name: String! }
  type UserConnection { edges: [UserEdge!]!, pageInfo: PageInfo! }
  type UserEdge { node: User!, cursor: String! }
  type PageInfo { hasNextPage: Boolean!, endCursor: String }
`

const server = new ApolloServer({
  schema: makeExecutableSchema({ typeDefs, resolvers }),
  formatError: (formattedError) => {
    if (process.env.NODE_ENV === 'production') {
      return { message: formattedError.message, locations: formattedError.locations, path: formattedError.path }
    }
    return formattedError
  },
})
```

### Mercurius (Fastify GraphQL)

```typescript
app.register(mercurius, {
  schema, resolvers,
  graphiql: true,
  jit: 1, // JIT compile resolvers after 1st hit for performance
  subscription: true, // WebSocket subscriptions
})
```

### GraphQL Yoga (framework-agnostic)

```typescript
import { createSchema, createYoga } from 'graphql-yoga'
// Works on Bun, Deno, Cloudflare Workers, Node.js, Next.js
const yoga = createYoga({ schema, maskedErrors: process.env.NODE_ENV === 'production' })
export default yoga
```

### Python - Strawberry (FastAPI)

```python
import strawberry
from strawberry.fastapi import GraphQLRouter

@strawberry.type
class Query:
    @strawberry.field
    async def user(self, id: str, info: strawberry.types.Info) -> User:
        return await info.context["user_service"].get_by_id(id)

schema = strawberry.Schema(query=Query)
graphql_app = GraphQLRouter(schema, context_getter=get_context)
app.include_router(graphql_app, prefix="/graphql")
```

### Rust - async-graphql (Axum)

```rust
#[derive(SimpleObject)]
struct User { id: String, email: String, name: String }

struct QueryRoot;

#[Object]
impl QueryRoot {
    async fn user(&self, ctx: &Context<'_>, id: String) -> Result<User> {
        let db = ctx.data::<Arc<Database>>()?;
        db.get_user(&id).await.map_err(Into::into)
    }
}

async fn graphql_handler(schema: Extension<AppSchema>, req: GraphQLRequest) -> GraphQLResponse {
    schema.execute(req.into_inner()).await.into()
}
```

### Go - gqlgen

```go
func (r *queryResolver) User(ctx context.Context, id string) (*model.User, error) {
    return r.UserService.GetByID(ctx, id)
}

// main.go
srv := handler.NewDefaultServer(generated.NewExecutableSchema(generated.Config{Resolvers: &graph.Resolver{}}))
srv.AddTransport(transport.Websockets{KeepAlivePingInterval: 10 * time.Second})
http.Handle("/query", srv)
```
