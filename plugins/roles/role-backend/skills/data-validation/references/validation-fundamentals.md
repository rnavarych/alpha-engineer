# Validation Fundamentals

## When to load
Load when deciding on a validation library, designing the validation layer structure, or implementing request/response DTOs and sanitization rules.

## Library Selection

| Library | Language | Approach | Best For |
|---------|----------|----------|----------|
| Zod | TypeScript | Schema-first, type inference | TypeScript APIs, full-stack type safety |
| Joi | JavaScript/TS | Chainable API, mature ecosystem | Express/Hapi APIs, complex validations |
| class-validator | TypeScript | Decorator-based on classes | NestJS, class-based DTOs |
| Pydantic | Python | Model-based, type annotation driven | FastAPI, Python data models |
| JSON Schema | Language-agnostic | Declarative JSON specification | Cross-language contracts, OpenAPI |
| Bean Validation | Java/Kotlin | Annotation-based (JSR 380) | Spring Boot, Jakarta EE |

## Validation Layers

Validate data at every system boundary — never skip a layer assuming another will catch it:

1. **API Gateway / Edge**: Basic format, size limits, rate limiting
2. **Controller / Handler**: Full request schema validation (shape, types, constraints)
3. **Service / Business Logic**: Business rule validation (uniqueness, state transitions, authorization)
4. **Data Access / Repository**: Database constraints (NOT NULL, UNIQUE, CHECK, FK)

## Request/Response DTOs

### Request DTOs
- Define a strict schema for every API endpoint input
- Separate DTOs for create, update, and query operations (do not reuse)
- Mark required fields explicitly; optional fields have defaults or are nullable
- Strip unknown/extra fields from input (deny by default)
- Include field-level documentation for API spec generation

### Response DTOs
- Define explicit response shapes (do not return raw database entities)
- Exclude sensitive fields (password hashes, internal IDs, audit columns)
- Use consistent envelope: `{ data, meta, errors }` or flat resource
- Version response shapes alongside API versions
- Transform database entities to response DTOs in a dedicated mapping layer

## Input Sanitization

- **Trim whitespace** on string inputs (leading/trailing)
- **Normalize unicode** to NFC form for consistent comparisons
- **Escape HTML** in user-generated content before storage or rendering
- **Strip null bytes** and control characters from string inputs
- **Validate encoding**: reject invalid UTF-8 sequences
- Never trust client-side sanitization; always sanitize server-side

## Type Coercion

- Prefer strict validation (reject wrong types) over silent coercion
- When coercion is needed, be explicit about the rules:
  - `"123"` → `123` (string to number: only if purely numeric)
  - `"true"` / `"false"` → `boolean` (only exact string matches)
  - `"2024-01-15"` → `Date` (only valid ISO 8601 formats)
- Document coercion behavior in the API specification
- Never coerce in ways that could lose data or precision
