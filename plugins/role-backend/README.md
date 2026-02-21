# role-backend

Senior Backend Developer plugin for Claude Code. Provides production-grade backend engineering skills covering API implementation, database design, microservices architecture, message queues, authentication, caching, background jobs, and data validation.

## Agent

- **senior-backend-developer** - Acts as a Senior Backend Developer with 8+ years of experience. Writes production-quality code following SOLID principles and clean architecture. Adapts to domain contexts (fintech, healthcare, IoT, e-commerce).

## Skills

| Skill | Description |
|-------|-------------|
| **api-implementation** | Express, NestJS, FastAPI, Django, Spring Boot, Go. Request validation, middleware, RFC 7807 errors, rate limiting, OpenAPI, versioning. |
| **database-implementation** | ORM patterns (Prisma, TypeORM, SQLAlchemy, GORM), migrations, connection pooling, read replicas, query optimization. |
| **microservices** | Service decomposition, REST/gRPC/event communication, saga pattern, circuit breaker, service mesh, API gateway, distributed tracing. |
| **message-queues** | RabbitMQ, Kafka, Redis Streams, SQS/SNS, Pub/Sub. Dead letter queues, idempotency, ordering, consumer groups, backpressure. |
| **auth-implementation** | JWT, sessions, OAuth2/OIDC, RBAC/ABAC, API keys, multi-tenancy auth, SSO, refresh token rotation. |
| **caching-strategies** | Redis patterns, Memcached, cache invalidation, TTL design, stampede prevention, CDN configuration. |
| **background-jobs** | Bull/BullMQ, Celery, Sidekiq, cron scheduling, retry strategies, dead letter handling, job monitoring. |
| **data-validation** | Zod, Joi, class-validator, Pydantic, JSON Schema, DTOs, sanitization, type coercion, custom validators. |

## Cross-Cutting Dependencies

This plugin references foundational skills from `alpha-core`:
- database-advisor, api-design, security-advisor, testing-patterns, architecture-patterns
