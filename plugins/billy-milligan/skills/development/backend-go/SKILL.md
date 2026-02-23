---
name: backend-go
description: Go backend patterns — HTTP services, concurrency, database access, project structure
allowed-tools: Read, Grep, Glob, Bash
---

# Backend Go Skill

## Core Principles
- **Context propagation**: Pass `ctx context.Context` as first arg to every I/O function.
- **Error wrapping**: `fmt.Errorf("operation: %w", err)` preserves the chain for `errors.Is`.
- **No goroutine leaks**: Every goroutine must have a way to exit (context, channel close).
- **Composition over inheritance**: Struct embedding, interfaces for polymorphism.
- **Return errors, don't panic**: Panics are for programmer errors, not runtime conditions.

## References
- `references/http-patterns.md` — net/http, Chi/Gin/Echo, middleware, graceful shutdown
- `references/concurrency-patterns.md` — Goroutines, channels, errgroup, worker pools, fan-out/fan-in
- `references/database-patterns.md` — database/sql, sqlx, pgx, connection pooling, migrations
- `references/project-structure.md` — Flat vs layered, internal/, cmd/, pkg/

## Scripts
- `scripts/detect-go-stack.sh` — Reads go.mod to identify framework, ORM, dependencies
