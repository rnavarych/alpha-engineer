# Go Project Structure

## Flat Structure (Small Services)

```
myservice/
  main.go              # Entry point, server setup, DI wiring
  handler.go           # HTTP handlers
  service.go           # Business logic
  repository.go        # Database access
  model.go             # Domain types
  middleware.go         # HTTP middleware
  config.go            # Environment configuration
  main_test.go         # Tests
  go.mod
  go.sum
```

Best for: microservices with < 10 files. No need for packages.

## Layered Structure (Medium Services)

```
myservice/
  cmd/
    server/
      main.go          # Entry point — wires everything together
  internal/
    handler/
      order.go         # HTTP handlers for orders
      user.go          # HTTP handlers for users
      middleware.go    # HTTP middleware
    service/
      order.go         # Business logic
      order_test.go
    repository/
      order.go         # Database access
      order_test.go
    model/
      order.go         # Domain types, enums
      errors.go        # Domain errors
    config/
      config.go        # Environment configuration with validation
  migrations/
    000001_init.up.sql
    000001_init.down.sql
  go.mod
  go.sum
  Dockerfile
  Makefile
```

Best for: services with 10-50 files. Clear separation of concerns.

## Key Directories

```
cmd/         # Application entry points
  server/    # HTTP server
  worker/    # Background worker
  cli/       # CLI tool

internal/    # Private packages — cannot be imported by other modules
  handler/   # HTTP handlers (transport layer)
  service/   # Business logic (application layer)
  repository/ # Data access (infrastructure layer)
  model/     # Domain types (domain layer)

pkg/         # Public packages — can be imported by other modules
             # Use sparingly — most code should be internal/

migrations/  # Database migrations
scripts/     # Build and deploy scripts
docs/        # Documentation
```

## Dependency Flow

```
main.go
  → config (env vars)
  → repository (database)
  → service (business logic, depends on repository)
  → handler (HTTP, depends on service)
  → server (wires handler + middleware)

Rule: dependencies flow inward
  handler → service → repository → database
  Never: repository → handler
  Never: service → handler
```

## Interfaces at Consumer Side

```go
// Define interface WHERE IT IS USED, not where it is implemented

// internal/service/order.go
type OrderRepository interface {
    FindByID(ctx context.Context, id string) (*model.Order, error)
    Create(ctx context.Context, order *model.Order) error
    ListByUser(ctx context.Context, userID string) ([]model.Order, error)
}

type OrderService struct {
    repo   OrderRepository  // Interface — testable with mocks
    logger *slog.Logger
}

func NewOrderService(repo OrderRepository, logger *slog.Logger) *OrderService {
    return &OrderService{repo: repo, logger: logger}
}

// internal/repository/order.go — implements the interface
type PostgresOrderRepo struct {
    db *pgxpool.Pool
}

func (r *PostgresOrderRepo) FindByID(ctx context.Context, id string) (*model.Order, error) {
    // Implementation
}
```

## Makefile

```makefile
.PHONY: build test lint run migrate

build:
	go build -o bin/server ./cmd/server

test:
	go test -race -cover ./...

lint:
	golangci-lint run ./...

run:
	go run ./cmd/server

migrate-up:
	migrate -database "$(DATABASE_URL)" -path migrations up

migrate-down:
	migrate -database "$(DATABASE_URL)" -path migrations down 1

docker:
	docker build -t myservice .
```

## Anti-Patterns
- Putting everything in `pkg/` — most code should be `internal/`
- Circular imports — restructure, extract shared types to `model/`
- God package — one package with 50 files; split by domain
- Interface on producer side — Go convention is consumer-defined interfaces
- Deep nesting — `internal/domain/order/repository/postgres/` is too deep

## Quick Reference
```
Small service (<10 files): flat structure, single package
Medium service (10-50 files): cmd/ + internal/ + migrations/
internal/: private, cannot be imported externally
cmd/: entry points only — DI wiring, no business logic
Interfaces: define at consumer, implement at producer
Dependency flow: handler -> service -> repository -> database
Testing: interfaces enable mock injection
Makefile: build, test, lint, run, migrate
```
