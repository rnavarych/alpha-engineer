---
name: backend-go
description: |
  Go backend patterns: HTTP handler structure, context propagation with timeout, goroutine
  lifecycle management, pgx connection pool, error wrapping (fmt.Errorf + %w), graceful
  shutdown, structured logging (slog), middleware pattern. Use when building Go services.
allowed-tools: Read, Grep, Glob
---

# Go Backend Patterns

## When to Use This Skill
- Building HTTP services with net/http or Gin/Echo/Chi/Fiber
- Managing goroutines safely without leaks
- Error handling and wrapping in Go
- PostgreSQL with pgx connection pool
- Graceful shutdown and context propagation

## Core Principles

1. **Context propagation** — pass `ctx context.Context` as first arg to every I/O function
2. **Error wrapping** — `fmt.Errorf("operation failed: %w", err)` preserves the chain
3. **No goroutine leaks** — every goroutine must have a way to exit
4. **Struct embedding for composition** — prefer composition over inheritance
5. **Return errors, don't panic** — panics are for programmer errors, not runtime conditions

---

## Patterns ✅

### HTTP Service Structure

```go
// cmd/server/main.go
package main

import (
    "context"
    "log/slog"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"
)

func main() {
    logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
        Level: slog.LevelInfo,
    }))
    slog.SetDefault(logger)

    db, err := initDB(context.Background())
    if err != nil {
        slog.Error("failed to connect to database", "error", err)
        os.Exit(1)
    }
    defer db.Close()

    srv := &OrderService{db: db, logger: logger}
    mux := http.NewServeMux()
    mux.HandleFunc("GET /orders", srv.ListOrders)
    mux.HandleFunc("POST /orders", srv.CreateOrder)
    mux.HandleFunc("GET /orders/{id}", srv.GetOrder)
    mux.HandleFunc("GET /health", healthHandler)

    server := &http.Server{
        Addr:         ":" + getEnv("PORT", "8080"),
        Handler:      withMiddleware(mux, requestLogger(logger), corsMiddleware),
        ReadTimeout:  5 * time.Second,
        WriteTimeout: 10 * time.Second,
        IdleTimeout:  120 * time.Second,
    }

    // Graceful shutdown
    go func() {
        if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            slog.Error("server error", "error", err)
            os.Exit(1)
        }
    }()
    slog.Info("server started", "addr", server.Addr)

    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()
    if err := server.Shutdown(ctx); err != nil {
        slog.Error("shutdown failed", "error", err)
    }
    slog.Info("server stopped")
}
```

### Context Propagation and Timeouts

```go
// Always pass context, always set timeouts for external I/O

type OrderService struct {
    db     *pgxpool.Pool
    logger *slog.Logger
}

func (s *OrderService) GetOrder(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()  // Use request context — cancelled if client disconnects
    id := r.PathValue("id")

    order, err := s.findOrderByID(ctx, id)
    if err != nil {
        if isNotFound(err) {
            writeJSON(w, http.StatusNotFound, map[string]string{"error": "order not found"})
            return
        }
        s.logger.ErrorContext(ctx, "failed to get order", "error", err, "orderId", id)
        writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "internal error"})
        return
    }

    writeJSON(w, http.StatusOK, order)
}

func (s *OrderService) findOrderByID(ctx context.Context, id string) (*Order, error) {
    // Context propagates to DB — query cancelled if request times out
    row := s.db.QueryRow(ctx, `SELECT id, user_id, status, total FROM orders WHERE id = $1`, id)

    var order Order
    if err := row.Scan(&order.ID, &order.UserID, &order.Status, &order.Total); err != nil {
        if errors.Is(err, pgx.ErrNoRows) {
            return nil, ErrNotFound
        }
        return nil, fmt.Errorf("findOrderByID: %w", err)  // Wrap with context
    }
    return &order, nil
}
```

### Error Wrapping

```go
// Go error handling conventions
var (
    ErrNotFound   = errors.New("not found")
    ErrUnauthorized = errors.New("unauthorized")
)

// Wrap errors with context — preserves the chain for logging
func (r *OrderRepository) Create(ctx context.Context, order *Order) error {
    _, err := r.db.Exec(ctx,
        `INSERT INTO orders (id, user_id, total, status) VALUES ($1, $2, $3, $4)`,
        order.ID, order.UserID, order.Total, order.Status,
    )
    if err != nil {
        // fmt.Errorf with %w wraps the error — errors.Is() can unwrap it
        return fmt.Errorf("OrderRepository.Create: %w", err)
    }
    return nil
}

// Check error type without string matching
func isNotFound(err error) bool {
    return errors.Is(err, ErrNotFound)
}

// Log full chain
func handleError(err error) {
    slog.Error("operation failed",
        "error", err,
        "chain", fmt.Sprintf("%+v", err),  // Full error chain
    )
}
```

### pgx Connection Pool

```go
// db.go — single pool for the entire process
import (
    "github.com/jackc/pgx/v5/pgxpool"
    "github.com/jackc/pgx/v5/tracelog"
)

func initDB(ctx context.Context) (*pgxpool.Pool, error) {
    config, err := pgxpool.ParseConfig(os.Getenv("DATABASE_URL"))
    if err != nil {
        return nil, fmt.Errorf("parse db config: %w", err)
    }

    config.MaxConns = 20                           // Max connections in pool
    config.MinConns = 2                            // Keep minimum alive
    config.MaxConnLifetime = time.Hour             // Recycle connections
    config.MaxConnIdleTime = 30 * time.Minute      // Close idle connections
    config.HealthCheckPeriod = time.Minute         // Verify connections periodically
    config.ConnConfig.ConnectTimeout = 5 * time.Second

    pool, err := pgxpool.NewWithConfig(ctx, config)
    if err != nil {
        return nil, fmt.Errorf("create pool: %w", err)
    }

    // Verify connectivity at startup
    if err := pool.Ping(ctx); err != nil {
        return nil, fmt.Errorf("ping database: %w", err)
    }

    return pool, nil
}
```

### Goroutine Lifecycle Management

```go
// Never start a goroutine without a way to stop it

// Wrong — goroutine leaks if nobody reads from channel
go func() {
    for {
        result := <-workChan  // Blocks forever if workChan is never closed
        process(result)
    }
}()

// Correct — context cancellation stops the goroutine
func startWorker(ctx context.Context, workChan <-chan Work) {
    go func() {
        for {
            select {
            case <-ctx.Done():
                return  // Stop when context cancelled
            case work, ok := <-workChan:
                if !ok {
                    return  // Stop when channel closed
                }
                process(work)
            }
        }
    }()
}

// WaitGroup for graceful shutdown
type BackgroundWorker struct {
    wg  sync.WaitGroup
    ctx context.Context
    cancel context.CancelFunc
}

func (bw *BackgroundWorker) Start(fn func(ctx context.Context)) {
    bw.wg.Add(1)
    go func() {
        defer bw.wg.Done()
        fn(bw.ctx)
    }()
}

func (bw *BackgroundWorker) Stop() {
    bw.cancel()         // Signal goroutines to stop
    bw.wg.Wait()        // Wait for all to complete
}
```

---

## Anti-Patterns ❌

### Ignoring Errors
```go
// Wrong — silent failure
result, _ := db.Query(ctx, "SELECT ...")
// If query fails, result is nil, next operation panics

// Correct — handle every error
result, err := db.Query(ctx, "SELECT ...")
if err != nil {
    return fmt.Errorf("query failed: %w", err)
}
defer result.Close()
```

### Not Passing Context to I/O
```go
// Wrong — I/O cannot be cancelled, timeouts don't work
func getUser(id string) (*User, error) {
    row := db.QueryRow("SELECT * FROM users WHERE id = $1", id)
    // ...
}

// Correct — context enables cancellation and timeout propagation
func getUser(ctx context.Context, id string) (*User, error) {
    row := db.QueryRow(ctx, "SELECT * FROM users WHERE id = $1", id)
    // ...
}
```

### Global Variables for Dependencies
```go
// Wrong — hard to test, hidden dependencies
var globalDB *pgxpool.Pool

func GetOrder(id string) (*Order, error) {
    return queryOrderFromGlobal(globalDB, id)
}

// Correct — dependency injection via struct
type OrderService struct {
    db *pgxpool.Pool
}

func (s *OrderService) GetOrder(ctx context.Context, id string) (*Order, error) {
    return queryOrder(ctx, s.db, id)
}
```

### Panic for Expected Errors
```go
// Wrong — panics for runtime conditions
func divide(a, b float64) float64 {
    if b == 0 {
        panic("division by zero")  // Should be an error, not a panic
    }
    return a / b
}

// Correct
func divide(a, b float64) (float64, error) {
    if b == 0 {
        return 0, errors.New("division by zero")
    }
    return a / b, nil
}
// Panic is for programmer errors (nil pointer, impossible state)
```

---

## Quick Reference

```
Context: first argument to every I/O function, always
Error wrapping: fmt.Errorf("context: %w", err) — preserves unwrap chain
errors.Is: compares through the chain — use for sentinel errors
Pool max connections: 20 (tune to CPU × 2)
pool ping at startup: always verify connectivity before serving traffic
Goroutine stop: context cancellation + select + channel close
WaitGroup: track goroutines for graceful shutdown
ReadTimeout: 5s, WriteTimeout: 10s, IdleTimeout: 120s
```
