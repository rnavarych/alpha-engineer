# Modular Monolith

## When to load
Load when designing module boundaries within a monolith, or structuring a modular monolith from scratch.

## Patterns ✅

### Module structure
```
src/
  modules/
    orders/
      domain/       # Entities, value objects, domain events
      application/  # Use cases, commands, queries
      infrastructure/ # DB repos, external adapters
      api/          # HTTP handlers — thin layer
    inventory/
      domain/
      application/
      infrastructure/
      api/
  shared/
    events/         # Domain event bus (in-process)
    kernel/         # Shared value objects (Money, Email)
```

### Inter-module communication
Only via public API interfaces or domain events. Direct imports across modules = architectural violation.

```typescript
// ❌ Wrong: direct import across modules
import { OrderRepository } from '../orders/infrastructure/OrderRepository';

// ✅ Right: depend on interface in shared kernel
import { IOrderQuery } from '../shared/kernel/IOrderQuery';
```

### When to extract a module to a service
Extract when: module needs independent scaling, different deployment cadence, different tech stack, or regulatory isolation. Not before.

## Anti-patterns ❌

### Module coupling via shared database tables
Modules query each other's tables directly. When you need to extract a service later, you discover 47 cross-module JOINs that all need to be replaced with API calls.

### No module boundaries enforced
Modules exist in directory structure but nothing prevents cross-imports. Within 3 months, every module imports from every other module.
Fix: Use ESLint `no-restricted-imports` or ArchUnit to enforce boundaries.

## Quick reference
```
Module communication: public interfaces + domain events only
Shared kernel: minimal (Money, Email, shared types)
Enforce: eslint-plugin-boundaries or ArchUnit
Extract when: independent scaling OR different deploy cadence needed
```
