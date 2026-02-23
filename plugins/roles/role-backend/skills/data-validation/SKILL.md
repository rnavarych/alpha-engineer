---
name: data-validation
description: |
  Implements data validation using Zod, Joi, class-validator, Pydantic, and JSON Schema.
  Covers request/response DTOs, input sanitization, type coercion, custom validators,
  validation middleware, and error formatting. Use when validating API inputs, defining
  data contracts, building form validators, or implementing DTO patterns.
allowed-tools: Read, Grep, Glob, Bash
---

# Data Validation

## When to use
- Choosing a validation library for a new project or stack
- Designing request/response DTOs and deciding what to strip or expose
- Implementing cross-field validators or custom format checks
- Wiring validation middleware into a request pipeline
- Composing reusable base schemas across endpoints
- Tuning validation performance on high-throughput routes

## Core principles
1. **Validate at every boundary** — controller, service, and database layer each catch different bugs
2. **Fail fast, fail completely** — collect all errors in one pass, never return partial error lists
3. **Strip the unknown** — deny unrecognized fields by default to prevent mass assignment
4. **Explicit coercion only** — document what converts and what rejects; silent coercion hides bugs
5. **Schemas are shared contracts** — reuse across frontend and backend via monorepo packages

## Reference Files

- `references/validation-fundamentals.md` — library selection table, four-layer validation model, request/response DTO rules, input sanitization checklist, and type coercion guidelines
- `references/validators-middleware-patterns.md` — custom validator implementations (email, phone, slug, currency, password), cross-field validation, middleware pipeline wiring, error response format, schema composition patterns, and performance tuning
