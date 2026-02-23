# HTTP Patterns

## net/http (Go 1.22+ with Method Routing)

```go
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
    logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelInfo}))
    slog.SetDefault(logger)

    db, err := initDB(context.Background())
    if err != nil {
        slog.Error("database init failed", "error", err)
        os.Exit(1)
    }
    defer db.Close()

    svc := &OrderService{db: db, logger: logger}

    mux := http.NewServeMux()
    mux.HandleFunc("GET /orders", svc.ListOrders)
    mux.HandleFunc("POST /orders", svc.CreateOrder)
    mux.HandleFunc("GET /orders/{id}", svc.GetOrder)
    mux.HandleFunc("GET /health", healthHandler)

    server := &http.Server{
        Addr:         ":" + envOr("PORT", "8080"),
        Handler:      chainMiddleware(mux, requestID, requestLogger(logger), cors),
        ReadTimeout:  5 * time.Second,
        WriteTimeout: 10 * time.Second,
        IdleTimeout:  120 * time.Second,
    }

    go func() {
        slog.Info("server started", "addr", server.Addr)
        if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            slog.Error("server error", "error", err)
            os.Exit(1)
        }
    }()

    // Graceful shutdown
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()
    if err := server.Shutdown(ctx); err != nil {
        slog.Error("shutdown error", "error", err)
    }
    slog.Info("server stopped")
}
```

## Chi Router

```go
import "github.com/go-chi/chi/v5"
import "github.com/go-chi/chi/v5/middleware"

r := chi.NewRouter()
r.Use(middleware.RequestID)
r.Use(middleware.RealIP)
r.Use(middleware.Logger)
r.Use(middleware.Recoverer)
r.Use(middleware.Timeout(30 * time.Second))

r.Route("/orders", func(r chi.Router) {
    r.Use(authMiddleware)            // Applied to all /orders routes
    r.Get("/", svc.ListOrders)
    r.Post("/", svc.CreateOrder)
    r.Route("/{id}", func(r chi.Router) {
        r.Get("/", svc.GetOrder)
        r.Put("/", svc.UpdateOrder)
        r.Delete("/", svc.DeleteOrder)
    })
})

// Access path param
func (s *OrderService) GetOrder(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")
    // ...
}
```

## Middleware Pattern

```go
type Middleware func(http.Handler) http.Handler

func chainMiddleware(handler http.Handler, middlewares ...Middleware) http.Handler {
    for i := len(middlewares) - 1; i >= 0; i-- {
        handler = middlewares[i](handler)
    }
    return handler
}

func requestLogger(logger *slog.Logger) Middleware {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            start := time.Now()
            wrapped := &responseWriter{ResponseWriter: w, statusCode: 200}

            next.ServeHTTP(wrapped, r)

            logger.Info("request",
                "method", r.Method,
                "path", r.URL.Path,
                "status", wrapped.statusCode,
                "duration_ms", time.Since(start).Milliseconds(),
            )
        })
    }
}

type responseWriter struct {
    http.ResponseWriter
    statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
    rw.statusCode = code
    rw.ResponseWriter.WriteHeader(code)
}
```

## JSON Response Helper

```go
func writeJSON(w http.ResponseWriter, status int, data any) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    if err := json.NewEncoder(w).Encode(data); err != nil {
        slog.Error("json encode error", "error", err)
    }
}

func writeError(w http.ResponseWriter, status int, code, message string) {
    writeJSON(w, status, map[string]any{
        "error": map[string]string{"code": code, "message": message},
    })
}
```

## Anti-Patterns
- Missing `ReadTimeout`/`WriteTimeout` — enables slowloris attacks
- No graceful shutdown — in-flight requests dropped on deploy
- Using `http.DefaultServeMux` in production — global state, no middleware
- Not reading `r.Body` before responding — connection reuse blocked

## Quick Reference
```
Go 1.22: mux.HandleFunc("GET /orders/{id}", handler)
ReadTimeout: 5s, WriteTimeout: 10s, IdleTimeout: 120s
Graceful shutdown: 30s timeout, SIGTERM/SIGINT
Chi: r.Route for groups, chi.URLParam for path params
Middleware: func(http.Handler) http.Handler pattern
JSON: json.NewEncoder(w).Encode() — streams, no buffer
```
