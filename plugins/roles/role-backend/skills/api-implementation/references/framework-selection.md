# Framework Selection

## When to load
Load when choosing an API framework for a new project or evaluating whether to switch. Covers all major languages and runtimes with decision criteria.

## Node.js / TypeScript

| Framework | Runtime | Best For |
|-----------|---------|----------|
| Express + TypeScript | Node.js | Lightweight REST APIs, large middleware ecosystem |
| NestJS | Node.js | Enterprise APIs, dependency injection, modular architecture |
| Fastify | Node.js | High-performance Node.js with schema-based serialization |
| Hono | Any (CF Workers, Bun, Deno, Node.js) | Edge-first, multi-runtime APIs |
| ElysiaJS | Bun | Bun-native, end-to-end type safety with Eden Treaty |
| tRPC | Node.js (with adapters) | Full-stack type safety without code generation |

## Go

| Framework | Best For |
|-----------|----------|
| Gin | Batteries-included, large ecosystem, proven in production |
| Echo | Clean API, excellent middleware, good docs |
| Fiber | Express-like API, extreme performance via fasthttp |
| Chi | Idiomatic net/http compatibility, lightweight |
| stdlib net/http | Go 1.22+ pattern matching, zero dependencies |

## Rust

| Framework | Best For |
|-----------|----------|
| Axum | Tower ecosystem, ergonomic extractors, async Tokio |
| Actix-web | Mature, actor model, very fast benchmarks |
| Rocket | Developer-friendly, request guards, fairings |
| Warp | Filter composition, functional style |
| Poem | OpenAPI-first with poem-openapi crate |

## JVM (Java / Kotlin)

| Framework | Best For |
|-----------|----------|
| Spring Boot 3 | Enterprise, virtual threads, rich ecosystem |
| Quarkus | Native image, fast startup, Panache ORM |
| Micronaut | Compile-time DI, GraalVM friendly, reflection-free |
| Helidon MP | MicroProfile standard, OCI optimized |
| Ktor (Kotlin) | Coroutine-native, multiplatform, DSL routing |

## Python

| Framework | Best For |
|-----------|----------|
| FastAPI | Async, Pydantic v2, auto OpenAPI, high performance |
| Django REST Framework | Data-heavy, admin, full-stack Django apps |
| Litestar | Modern async alternative, OpenAPI-first, attrs/pydantic |
| Flask + flask-smorest | Lightweight, OpenAPI via marshmallow schemas |

## .NET

| Framework | Best For |
|-----------|----------|
| ASP.NET Core 8 Minimal APIs | Lightweight, high performance, AOT compatible |
| ASP.NET Core Controllers | Rich attribute routing, large team familiarity |
| Carter | Module-based organization on top of Minimal APIs |
| FastEndpoints | REPR pattern, vertical slice architecture |

## Ruby

| Framework | Best For |
|-----------|----------|
| Rails 7 API mode | Full-featured, ActiveRecord integration, mature |
| Grape | Mountable REST DSL, strong parameter declarations |
| Hanami | Functional, dry-rb ecosystem, bounded contexts |
| Sinatra | Minimal, quick prototyping |

## Elixir

| Framework | Best For |
|-----------|----------|
| Phoenix | Full-featured, LiveView, channels, excellent performance |
| Plug | Composable middleware pipeline, Phoenix foundation |
| Bandit | Pure Elixir HTTP server, Phoenix 1.7+ default |

## PHP

| Framework | Best For |
|-----------|----------|
| Laravel | Full-featured, Eloquent ORM, large ecosystem |
| Symfony | Enterprise, components as libraries, API Platform |
| Slim 4 | Microframework for small APIs, PSR-7/15 |
| API Platform | Hypermedia/REST/GraphQL from Doctrine entities |
