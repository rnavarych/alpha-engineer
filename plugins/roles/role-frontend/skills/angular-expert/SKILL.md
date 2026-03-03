---
name: role-frontend:angular-expert
description: |
  Angular expertise including modules vs standalone components, dependency injection,
  RxJS patterns, signals, Angular Material, change detection strategies (OnPush),
  lazy loading routes, and NgRx state management.
allowed-tools: Read, Grep, Glob, Bash
---

# Angular Expert

## When to use
- Building or reviewing Angular 14+ applications with standalone components
- Implementing reactive state with signals, computed, or effect
- Choosing between RxJS patterns (switchMap vs exhaustMap vs mergeMap vs concatMap)
- Setting up dependency injection with inject(), InjectionToken, or scoped providers
- Configuring routing with functional guards, resolvers, lazy loadComponent/loadChildren
- Implementing NgRx feature state, effects, signal store, or component-store
- Writing Angular component tests, harness tests, or marble tests for RxJS
- Optimizing change detection with OnPush, zoneless, or defer blocks

## Core principles
1. **Standalone first** — set `standalone: true` on every new component; NgModules are legacy
2. **Signals over zone.js** — signal/computed/effect for component state; RxJS for async streams only
3. **inject() over constructor** — cleaner syntax, works in standalone functions, better for inheritance
4. **OnPush everywhere** — combined with signals eliminates unnecessary change detection cycles
5. **Functional guards and interceptors** — class-based guards and interceptors are deprecated patterns

## Reference Files

- `references/standalone-signals-di.md` — standalone component setup, bootstrapApplication, signal/computed/effect, input/output/model/viewChild, toSignal/toObservable, inject() and InjectionToken, OnPush and zoneless change detection
- `references/rxjs-forms-routing-http.md` — higher-order mapping operators, error handling, takeUntilDestroyed, async pipe, reactive forms with NonNullableFormBuilder, custom validators, functional guards/resolvers, @defer blocks, functional HTTP interceptors
- `references/ngrx-testing-performance.md` — NgRx createFeature/createActionGroup/createSelector, effects with exhaustMap, @ngrx/signals signalStore, component testing with TestBed, component harnesses, marble testing, bundle analysis, SSR hydration, Angular Material and CDK, anti-patterns table
