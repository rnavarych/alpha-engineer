---
name: api-implementation
description: Implements production-ready APIs across Node.js (Express, NestJS, Fastify, Hono, ElysiaJS, tRPC), Go (Gin, Echo, Fiber, Chi), Rust (Axum, Actix-web), Java (Spring Boot 3, Quarkus), .NET (ASP.NET Core 8), Ruby (Rails 7, Grape), Elixir (Phoenix), and PHP (Laravel, Symfony). Covers middleware pipelines, RFC 7807 error handling, rate limiting, OpenAPI 3.1 codegen, tRPC, GraphQL servers (Apollo, Mercurius, Yoga, gqlgen, async-graphql), and API versioning. Use when building API endpoints, adding middleware, implementing error handling, or generating API docs.
allowed-tools: Read, Grep, Glob, Bash
---

You are a backend API implementation specialist. You write production-ready API code, not prototypes.

## Framework Selection

### Node.js / TypeScript

| Framework | Runtime | Best For |
|-----------|---------|----------|
| Express + TypeScript | Node.js | Lightweight REST APIs, large middleware ecosystem |
| NestJS | Node.js | Enterprise APIs, dependency injection, modular architecture |
| Fastify | Node.js | High-performance Node.js with schema-based serialization |
| Hono | Any (CF Workers, Bun, Deno, Node.js) | Edge-first, multi-runtime APIs |
| ElysiaJS | Bun | Bun-native, end-to-end type safety with Eden Treaty |
| tRPC | Node.js (with adapters) | Full-stack type safety without code generation |

### Go

| Framework | Best For |
|-----------|----------|
| Gin | Batteries-included, large ecosystem, proven in production |
| Echo | Clean API, excellent middleware, good docs |
| Fiber | Express-like API, extreme performance via fasthttp |
| Chi | Idiomatic net/http compatibility, lightweight |
| stdlib net/http | Go 1.22+ pattern matching, zero dependencies |

### Rust

| Framework | Best For |
|-----------|----------|
| Axum | Tower ecosystem, ergonomic extractors, async Tokio |
| Actix-web | Mature, actor model, very fast benchmarks |
| Rocket | Developer-friendly, request guards, fairings |
| Warp | Filter composition, functional style |
| Poem | OpenAPI-first with poem-openapi crate |

### JVM (Java / Kotlin)

| Framework | Best For |
|-----------|----------|
| Spring Boot 3 | Enterprise, virtual threads, rich ecosystem |
| Quarkus | Native image, fast startup, Panache ORM |
| Micronaut | Compile-time DI, GraalVM friendly, reflection-free |
| Helidon MP | MicroProfile standard, OCI optimized |
| Ktor (Kotlin) | Coroutine-native, multiplatform, DSL routing |

### Python

| Framework | Best For |
|-----------|----------|
| FastAPI | Async, Pydantic v2, auto OpenAPI, high performance |
| Django REST Framework | Data-heavy, admin, full-stack Django apps |
| Litestar | Modern async alternative, OpenAPI-first, attrs/pydantic |
| Flask + flask-smorest | Lightweight, OpenAPI via marshmallow schemas |

### .NET

| Framework | Best For |
|-----------|----------|
| ASP.NET Core 8 Minimal APIs | Lightweight, high performance, AOT compatible |
| ASP.NET Core Controllers | Rich attribute routing, large team familiarity |
| Carter | Module-based organization on top of Minimal APIs |
| FastEndpoints | REPR pattern, vertical slice architecture |

### Ruby

| Framework | Best For |
|-----------|----------|
| Rails 7 API mode | Full-featured, ActiveRecord integration, mature |
| Grape | Mountable REST DSL, strong parameter declarations |
| Hanami | Functional, dry-rb ecosystem, bounded contexts |
| Sinatra | Minimal, quick prototyping |

### Elixir

| Framework | Best For |
|-----------|----------|
| Phoenix | Full-featured, LiveView, channels, excellent performance |
| Plug | Composable middleware pipeline, Phoenix foundation |
| Bandit | Pure Elixir HTTP server, Phoenix 1.7+ default |

### PHP

| Framework | Best For |
|-----------|----------|
| Laravel | Full-featured, Eloquent ORM, large ecosystem |
| Symfony | Enterprise, components as libraries, API Platform |
| Slim 4 | Microframework for small APIs, PSR-7/15 |
| API Platform | Hypermedia/REST/GraphQL from Doctrine entities |

## Framework-Specific Patterns

### Hono (Multi-Runtime)

```typescript
import { Hono } from 'hono'
import { zValidator } from '@hono/zod-validator'
import { jwt } from 'hono/jwt'
import { cors } from 'hono/cors'
import { logger } from 'hono/logger'
import { z } from 'zod'

type Env = {
  Variables: { userId: string }
  Bindings: { DB: D1Database; JWT_SECRET: string }
}

const app = new Hono<Env>()

app.use('*', logger())
app.use('/api/*', cors({ origin: ['https://app.example.com'] }))
app.use('/api/protected/*', jwt({ secret: (c) => c.env.JWT_SECRET }))

const createUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(2).max(100),
})

app.post(
  '/api/users',
  zValidator('json', createUserSchema),
  async (c) => {
    const data = c.req.valid('json')
    // Runs on CF Workers, Bun, Deno, Node.js identically
    return c.json({ id: crypto.randomUUID(), ...data }, 201)
  }
)

// Type-safe client: const client = hc<typeof app>('https://api.example.com')
export default app
```

### ElysiaJS (Bun-Native)

```typescript
import { Elysia, t } from 'elysia'
import { swagger } from '@elysiajs/swagger'
import { jwt } from '@elysiajs/jwt'
import { bearer } from '@elysiajs/bearer'

const app = new Elysia()
  .use(swagger())
  .use(jwt({ name: 'jwt', secret: process.env.JWT_SECRET! }))
  .use(bearer())
  .derive(async ({ bearer, jwt }) => {
    const payload = await jwt.verify(bearer)
    if (!payload) throw new Error('Unauthorized')
    return { userId: payload.sub as string }
  })
  .post(
    '/users',
    async ({ body, userId }) => ({ id: crypto.randomUUID(), ...body, createdBy: userId }),
    {
      body: t.Object({ email: t.String({ format: 'email' }), name: t.String({ minLength: 2 }) }),
      response: t.Object({ id: t.String(), email: t.String(), name: t.String(), createdBy: t.String() }),
    }
  )
  .listen(3000)

// Eden Treaty client: const api = treaty<typeof app>('localhost:3000')
export type App = typeof app
```

### Fastify (Node.js Performance)

```typescript
import Fastify from 'fastify'
import { TypeBoxTypeProvider } from '@fastify/type-provider-typebox'
import { Type } from '@sinclair/typebox'
import fastifyJwt from '@fastify/jwt'
import fastifyRateLimit from '@fastify/rate-limit'

const app = Fastify({ logger: { level: 'info' } })
  .withTypeProvider<TypeBoxTypeProvider>()

await app.register(fastifyJwt, { secret: process.env.JWT_SECRET! })
await app.register(fastifyRateLimit, { max: 100, timeWindow: '1 minute', redis })

app.addHook('onRequest', async (request, reply) => {
  if (request.routeOptions.config?.auth) {
    await request.jwtVerify()
  }
})

const CreateUserBody = Type.Object({
  email: Type.String({ format: 'email' }),
  name: Type.String({ minLength: 2, maxLength: 100 }),
})

app.post<{ Body: typeof CreateUserBody.static }>(
  '/users',
  {
    schema: { body: CreateUserBody },
    config: { auth: true },
  },
  async (request, reply) => {
    // JSON serialization is 2-3x faster due to TypeBox schema compilation
    return reply.code(201).send({ id: crypto.randomUUID(), ...request.body })
  }
)
```

### Go - Gin

```go
package main

import (
    "github.com/gin-gonic/gin"
    "github.com/gin-gonic/gin/binding"
    "github.com/go-playground/validator/v10"
)

type CreateUserRequest struct {
    Email string `json:"email" binding:"required,email"`
    Name  string `json:"name"  binding:"required,min=2,max=100"`
}

func main() {
    r := gin.New()
    r.Use(gin.Logger(), gin.Recovery(), RequestIDMiddleware())

    v1 := r.Group("/api/v1")
    v1.Use(AuthMiddleware())

    v1.POST("/users", func(c *gin.Context) {
        var req CreateUserRequest
        if err := c.ShouldBindJSON(&req); err != nil {
            c.JSON(400, gin.H{"type": "validation", "errors": formatValidationErrors(err)})
            return
        }
        user, err := userService.Create(c.Request.Context(), req)
        if err != nil {
            handleServiceError(c, err)
            return
        }
        c.JSON(201, user)
    })
    r.Run(":8080")
}
```

### Go - Chi (idiomatic net/http)

```go
import (
    "github.com/go-chi/chi/v5"
    "github.com/go-chi/chi/v5/middleware"
    "github.com/go-chi/jwtauth/v5"
)

func NewRouter(h *Handlers) http.Handler {
    r := chi.NewRouter()
    r.Use(middleware.RequestID, middleware.RealIP, middleware.Logger, middleware.Recoverer)
    r.Use(middleware.Timeout(30 * time.Second))

    r.Route("/api/v1", func(r chi.Router) {
        r.Use(jwtauth.Verifier(tokenAuth), jwtauth.Authenticator(tokenAuth))
        r.Post("/users", h.CreateUser)
        r.Get("/users/{id}", h.GetUser)
    })
    return r
}
```

### Rust - Axum

```rust
use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tower_http::{cors::CorsLayer, trace::TraceLayer};
use validator::Validate;

#[derive(Clone)]
struct AppState { db: Arc<DatabasePool> }

#[derive(Deserialize, Validate)]
struct CreateUserRequest {
    #[validate(email)]
    email: String,
    #[validate(length(min = 2, max = 100))]
    name: String,
}

#[derive(Serialize)]
struct UserResponse { id: String, email: String, name: String }

async fn create_user(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<CreateUserRequest>,
) -> Result<impl IntoResponse, AppError> {
    payload.validate().map_err(AppError::Validation)?;
    let user = state.db.create_user(&payload.email, &payload.name).await?;
    Ok((StatusCode::CREATED, Json(UserResponse::from(user))))
}

pub fn router(state: Arc<AppState>) -> Router {
    Router::new()
        .route("/api/v1/users", post(create_user))
        .route("/api/v1/users/:id", get(get_user))
        .layer(TraceLayer::new_for_http())
        .layer(CorsLayer::permissive()) // tighten in production
        .with_state(state)
}
```

### Spring Boot 3 - Virtual Threads + Minimal REST

```java
@RestController
@RequestMapping("/api/v1/users")
@Validated
public class UserController {

    private final UserService userService;

    // Virtual threads: spring.threads.virtual.enabled=true in application.properties
    // Each request handled by a virtual thread - no reactive boilerplate needed
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public UserResponse createUser(@RequestBody @Valid CreateUserRequest request) {
        return userService.create(request); // blocking I/O is safe on virtual threads
    }

    @GetMapping("/{id}")
    public ResponseEntity<UserResponse> getUser(@PathVariable UUID id) {
        return userService.findById(id)
            .map(ResponseEntity::ok)
            .orElseThrow(() -> new ResourceNotFoundException("User", id));
    }
}

// Spring Boot 3 Minimal API style with functional endpoints
@Configuration
public class UserRoutes {
    @Bean
    public RouterFunction<ServerResponse> userRouter(UserHandler handler) {
        return route()
            .POST("/api/v2/users", handler::create)
            .GET("/api/v2/users/{id}", handler::findById)
            .build();
    }
}
```

### ASP.NET Core 8 - Minimal APIs

```csharp
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddOutputCache();
builder.Services.AddRateLimiter(options => {
    options.AddSlidingWindowLimiter("api", opt => {
        opt.Window = TimeSpan.FromSeconds(60);
        opt.PermitLimit = 100;
        opt.QueueLimit = 10;
    });
});

var app = builder.Build();
app.UseRateLimiter();
app.UseOutputCache();

var users = app.MapGroup("/api/v1/users")
    .RequireAuthorization()
    .RequireRateLimiting("api");

users.MapPost("/", async (CreateUserRequest req, IValidator<CreateUserRequest> validator, IUserService svc) => {
    var result = await validator.ValidateAsync(req);
    if (!result.IsValid)
        return Results.ValidationProblem(result.ToDictionary());
    var user = await svc.CreateAsync(req);
    return Results.Created($"/api/v1/users/{user.Id}", user);
});

users.MapGet("/{id:guid}", async (Guid id, IUserService svc) =>
    await svc.GetByIdAsync(id) is {} user
        ? Results.Ok(user)
        : Results.NotFound());
```

### Phoenix (Elixir)

```elixir
# router.ex
pipeline :api do
  plug :accepts, ["json"]
  plug :fetch_session
  plug MyAppWeb.Auth.Pipeline  # Guardian JWT pipeline
end

scope "/api/v1", MyAppWeb do
  pipe_through [:api, :authenticated]
  resources "/users", UserController, only: [:create, :show, :update, :delete]
  post "/users/:id/activate", UserController, :activate
end

# user_controller.ex
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  alias MyApp.Accounts

  action_fallback MyAppWeb.FallbackController

  def create(conn, params) do
    with {:ok, %{valid?: true} = changeset} <- Accounts.validate_create_params(params),
         {:ok, user} <- Accounts.create_user(changeset) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/v1/users/#{user}")
      |> render(:show, user: user)
    end
  end
end
```

## Request Validation

- Validate all incoming data at the controller/handler level before business logic
- Use schema-based validation (Zod/Valibot/ArkType for Node.js, Pydantic v2 for Python, Bean Validation for Java, FluentValidation for .NET, Ecto changesets for Elixir)
- Return 400 Bad Request with field-level error details for invalid input
- Validate path parameters, query parameters, headers, and request body separately
- Coerce types explicitly (string to number, string to date) rather than implicitly
- Strip unknown fields from input to prevent mass assignment vulnerabilities

## Middleware Pipeline

Standard middleware order for HTTP APIs:
1. **Request ID**: Generate or propagate correlation/request ID (W3C Trace-Context or custom header)
2. **Logging**: Log incoming request method, path, and timing with structured JSON
3. **CORS**: Configure allowed origins, methods, and headers
4. **Security headers**: Helmet (Node.js), SecurityHeaders (.NET), secure defaults
5. **Rate limiting**: Per-IP or per-user throttling backed by Redis
6. **Authentication**: Verify JWT/session/API key
7. **Authorization**: Check permissions for the requested resource
8. **Body parsing**: Parse JSON/multipart with size limits (default 1-10MB cap)
9. **Validation**: Validate request against schema
10. **Handler**: Execute business logic
11. **Error handler**: Catch and format errors consistently

## Error Handling (RFC 7807)

All API errors must follow the Problem Details format:
```json
{
  "type": "https://api.example.com/errors/insufficient-funds",
  "title": "Insufficient Funds",
  "status": 422,
  "detail": "Account balance is $10.00, but the transfer requires $25.00",
  "instance": "/transfers/abc-123",
  "correlationId": "req_01HX4K2M3N5P6Q7R8S9T"
}
```

Validation error extension:
```json
{
  "type": "https://api.example.com/errors/validation",
  "title": "Validation Error",
  "status": 400,
  "errors": [
    { "field": "email", "message": "Must be a valid email address", "code": "invalid_format" },
    { "field": "items[0].quantity", "message": "Must be a positive integer", "code": "too_small" }
  ]
}
```

- Map domain exceptions to specific HTTP status codes
- Never expose stack traces, internal paths, or database errors to clients
- Include a `correlationId` for support and debugging linkage to logs

## Rate Limiting

- Use sliding window or token bucket algorithms
- Store counters in Redis for distributed deployments
- Apply different limits by endpoint sensitivity and user tier
- Return `429 Too Many Requests` with `Retry-After` header
- Include rate limit headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`
- Libraries: `@fastify/rate-limit`, `express-rate-limit` + `rate-limit-redis`, `throttler` (NestJS), `slowapi` (Python/FastAPI), `rack-attack` (Rails)

## OpenAPI 3.1 and Code Generation

### Spec Generation (Code-First)

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
| `go-swagger` | Go/any |

### Client Code Generation

**openapi-generator** (multi-language)
```bash
openapi-generator generate -i openapi.yaml -g typescript-axios -o ./src/generated/api
openapi-generator generate -i openapi.yaml -g go -o ./pkg/client
openapi-generator generate -i openapi.yaml -g python -o ./client
```

**orval** (TypeScript, React Query / SWR / Axios)
```bash
npx orval --config orval.config.ts
# Generates typed hooks: useGetUsers(), useCreateUser()
# Config: { input: './openapi.yaml', output: { target: './src/api', client: 'react-query' } }
```

**hey-api** (`@hey-api/openapi-ts`)
```bash
npx @hey-api/openapi-ts -i openapi.yaml -o src/client -c @hey-api/client-fetch
# Generates services, models, types with tree-shakeable structure
```

**TypeScript-first generation best practices:**
- Generate into a `src/generated/` directory and never edit generated files manually
- Add `src/generated/` to `.gitignore` if spec is the source of truth
- Regenerate in CI to detect drift between spec and implementation
- Use `zod-to-openapi` or `typebox-to-openapi` for schema-first TypeScript workflows

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
      .query(async ({ input, ctx }) => {
        return userService.findById(input.id)
      }),
    create: protectedProcedure
      .input(z.object({ email: z.string().email(), name: z.string().min(2) }))
      .mutation(async ({ input, ctx }) => {
        return userService.create({ ...input, createdBy: ctx.userId })
      }),
  }),
})

export type AppRouter = typeof appRouter

// Mount on Express:
// app.use('/trpc', createExpressMiddleware({ router: appRouter, createContext }))
// Mount on Fastify:
// app.register(fastifyTRPCPlugin, { prefix: '/trpc', trpcOptions: { router: appRouter, createContext } })
```

## GraphQL Servers

### Apollo Server 4 (Node.js)

```typescript
import { ApolloServer } from '@apollo/server'
import { startStandaloneServer } from '@apollo/server/standalone'
import { makeExecutableSchema } from '@graphql-tools/schema'

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
  plugins: [ApolloServerPluginLandingPageLocalDefault()],
  formatError: (formattedError) => {
    // Strip internal error details in production
    if (process.env.NODE_ENV === 'production') {
      return { message: formattedError.message, locations: formattedError.locations, path: formattedError.path }
    }
    return formattedError
  },
})
```

### Mercurius (Fastify GraphQL)

```typescript
import Fastify from 'fastify'
import mercurius from 'mercurius'

const app = Fastify()
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
// Use as fetch handler: export default yoga
```

### Python - Strawberry (FastAPI integration)

```python
import strawberry
from strawberry.fastapi import GraphQLRouter

@strawberry.type
class User:
    id: str
    email: str
    name: str

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
use async_graphql::{Context, Object, Schema, SimpleObject, EmptyMutation, EmptySubscription};
use async_graphql_axum::{GraphQLRequest, GraphQLResponse};

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

type AppSchema = Schema<QueryRoot, EmptyMutation, EmptySubscription>;

async fn graphql_handler(schema: Extension<AppSchema>, req: GraphQLRequest) -> GraphQLResponse {
    schema.execute(req.into_inner()).await.into()
}
```

### Go - gqlgen

```go
// schema.graphqls defines the schema
// gqlgen generate creates resolver stubs
// graph/resolver.go implements the resolvers

func (r *queryResolver) User(ctx context.Context, id string) (*model.User, error) {
    return r.UserService.GetByID(ctx, id)
}

// main.go
srv := handler.NewDefaultServer(generated.NewExecutableSchema(generated.Config{Resolvers: &graph.Resolver{...}}))
srv.AddTransport(transport.Websockets{KeepAlivePingInterval: 10 * time.Second})
http.Handle("/query", srv)
```

## API Versioning

- **URL path versioning** (preferred): `/api/v1/users`, `/api/v2/users`
- Maintain backward compatibility within a major version
- Deprecate old versions with `Sunset` and `Deprecation` headers and migration guides
- Use content negotiation as an alternative: `Accept: application/vnd.api.v2+json`
- Never remove fields from responses without a major version bump
- Additive changes (new optional fields) are backward compatible and do not require a new version
- For GraphQL: use `@deprecated(reason: "...")` directive; avoid versioned schemas

## CORS Configuration

- Explicitly list allowed origins (never use `*` in production with credentials)
- Restrict allowed methods to those actually used
- Set `Access-Control-Max-Age` to cache preflight responses (86400 seconds)
- Allow only required custom headers
- Enable `credentials: true` only when cookies/auth headers are needed
- Validate `Origin` header server-side for sensitive operations even with CORS configured

## Streaming Responses

### Server-Sent Events (SSE)

```typescript
// Hono SSE
import { streamSSE } from 'hono/streaming'
app.get('/api/events', (c) => {
  return streamSSE(c, async (stream) => {
    while (true) {
      const event = await eventBus.next()
      await stream.writeSSE({ data: JSON.stringify(event), event: event.type, id: event.id })
    }
  })
})
```

### Chunked JSON Streaming

```typescript
// FastAPI streaming response for AI completions
from fastapi.responses import StreamingResponse
async def generate():
    async for chunk in llm.stream(prompt):
        yield f"data: {json.dumps({'content': chunk})}\n\n"
return StreamingResponse(generate(), media_type="text/event-stream")
```
