---
name: api-implementation
description: Implements production-ready APIs across Node.js (Express, NestJS, Fastify, Hono, ElysiaJS, tRPC), Go (Gin, Echo, Fiber, Chi), Rust (Axum, Actix-web), Java (Spring Boot 3, Quarkus), .NET (ASP.NET Core 8), Ruby (Rails 7, Grape), Elixir (Phoenix), and PHP (Laravel, Symfony). Covers middleware pipelines, RFC 7807 error handling, rate limiting, OpenAPI 3.1 codegen, tRPC, GraphQL servers (Apollo, Mercurius, Yoga, gqlgen, async-graphql), and API versioning. Use when building API endpoints, adding middleware, implementing error handling, or generating API docs.
allowed-tools: Read, Grep, Glob, Bash
---

# API Implementation

## When to use
- Building new API endpoints in any language or framework
- Adding or reordering middleware (auth, CORS, rate limiting, logging)
- Implementing error handling with RFC 7807 Problem Details
- Setting up tRPC, GraphQL, or OpenAPI spec generation
- Choosing a framework for a new backend service
- Implementing streaming responses (SSE, chunked JSON)
- Versioning an existing API

## Core principles
1. **Validate at the boundary** — reject invalid input at the handler before any business logic runs
2. **Middleware order is contract** — request ID → CORS → rate limit → auth → validation → handler
3. **RFC 7807 everywhere** — all errors return Problem Details with `type`, `title`, `status`, `correlationId`
4. **Never expose internals** — no stack traces, no DB errors, no internal paths in responses
5. **Schema-first serialization** — use TypeBox/Zod/Pydantic for both validation and faster serialization

## Reference Files

- `references/framework-selection.md` — comparison tables for all frameworks across Node.js, Go, Rust, JVM, Python, .NET, Ruby, Elixir, PHP; pick the right tool before writing any code
- `references/framework-patterns.md` — production-ready code examples for Hono, ElysiaJS, Fastify, Gin, Chi, Axum, Spring Boot 3, ASP.NET Core 8, and Phoenix; copy and adapt for the target stack
- `references/middleware-error-handling.md` — middleware pipeline order, RFC 7807 error format, request validation rules, rate limiting config, CORS best practices
- `references/openapi-trpc-graphql.md` — OpenAPI 3.1 codegen tools per framework, orval/hey-api client generation, tRPC router setup, and GraphQL server implementations in Node.js, Python, Rust, and Go
- `references/versioning-streaming.md` — API versioning strategy (URL path, content negotiation, deprecation headers), SSE streaming patterns, chunked JSON/NDJSON for AI completions and bulk exports
