---
name: api-design
description: |
  API design patterns: REST naming/pagination/errors, GraphQL schema design, gRPC streaming,
  versioning strategies, idempotency keys, rate limiting. Use when designing APIs.
allowed-tools: Read, Grep, Glob
---

# API Design Patterns

## When to use
- Designing REST, GraphQL, or gRPC APIs
- Choosing pagination, versioning, or error format strategies
- Implementing idempotency, rate limiting, or API gateways

## Core principles
1. **Consistent resource naming** — plural nouns, kebab-case, no verbs in URLs
2. **Cursor pagination by default** — offset fails at scale
3. **Idempotency keys for mutations** — clients safely retry without duplicate side effects
4. **Version from day one** — breaking changes without versioning = broken clients
5. **Error responses are part of the API** — structured, consistent, with request ID

## References available
- `references/rest-best-practices.md` — naming, pagination, error format, idempotency, rate limiting
- `references/graphql-patterns.md` — schema design, N+1 with DataLoader, fragments, subscriptions
- `references/grpc-patterns.md` — protobuf design, streaming, deadlines, load balancing
- `references/api-versioning-strategies.md` — URL vs header vs content negotiation trade-offs

## Assets available
- `assets/openapi-template.yaml` — starter OpenAPI 3.1 spec with best-practice patterns
