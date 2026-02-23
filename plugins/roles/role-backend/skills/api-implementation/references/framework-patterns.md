# Framework-Specific Patterns

## When to load
Load when implementing a specific framework. Contains production-ready code examples for Hono, ElysiaJS, Fastify, Go Gin/Chi, Rust Axum, Spring Boot 3, ASP.NET Core 8, and Phoenix.

## Hono (Multi-Runtime)

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

app.post('/api/users', zValidator('json', createUserSchema), async (c) => {
  const data = c.req.valid('json')
  // Runs on CF Workers, Bun, Deno, Node.js identically
  return c.json({ id: crypto.randomUUID(), ...data }, 201)
})

// Type-safe client: const client = hc<typeof app>('https://api.example.com')
export default app
```

## ElysiaJS (Bun-Native)

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

## Fastify (Node.js Performance)

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
  { schema: { body: CreateUserBody }, config: { auth: true } },
  async (request, reply) => {
    // JSON serialization is 2-3x faster due to TypeBox schema compilation
    return reply.code(201).send({ id: crypto.randomUUID(), ...request.body })
  }
)
```

## Go - Gin

```go
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

## Go - Chi (idiomatic net/http)

```go
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

## Rust - Axum

```rust
#[derive(Clone)]
struct AppState { db: Arc<DatabasePool> }

#[derive(Deserialize, Validate)]
struct CreateUserRequest {
    #[validate(email)]
    email: String,
    #[validate(length(min = 2, max = 100))]
    name: String,
}

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

## Spring Boot 3 (Virtual Threads)

```java
@RestController
@RequestMapping("/api/v1/users")
@Validated
public class UserController {
    // spring.threads.virtual.enabled=true — no reactive boilerplate needed
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public UserResponse createUser(@RequestBody @Valid CreateUserRequest request) {
        return userService.create(request); // blocking I/O safe on virtual threads
    }

    @GetMapping("/{id}")
    public ResponseEntity<UserResponse> getUser(@PathVariable UUID id) {
        return userService.findById(id)
            .map(ResponseEntity::ok)
            .orElseThrow(() -> new ResourceNotFoundException("User", id));
    }
}
```

## ASP.NET Core 8 Minimal APIs

```csharp
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddOutputCache();
builder.Services.AddRateLimiter(options =>
    options.AddSlidingWindowLimiter("api", opt => {
        opt.Window = TimeSpan.FromSeconds(60);
        opt.PermitLimit = 100;
        opt.QueueLimit = 10;
    }));

var app = builder.Build();
app.UseRateLimiter();
app.UseOutputCache();

var users = app.MapGroup("/api/v1/users")
    .RequireAuthorization()
    .RequireRateLimiting("api");

users.MapPost("/", async (CreateUserRequest req, IValidator<CreateUserRequest> validator, IUserService svc) => {
    var result = await validator.ValidateAsync(req);
    if (!result.IsValid) return Results.ValidationProblem(result.ToDictionary());
    var user = await svc.CreateAsync(req);
    return Results.Created($"/api/v1/users/{user.Id}", user);
});
```

## Phoenix (Elixir)

```elixir
# router.ex
pipeline :api do
  plug :accepts, ["json"]
  plug :fetch_session
  plug MyAppWeb.Auth.Pipeline
end

scope "/api/v1", MyAppWeb do
  pipe_through [:api, :authenticated]
  resources "/users", UserController, only: [:create, :show, :update, :delete]
end

# user_controller.ex
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
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
