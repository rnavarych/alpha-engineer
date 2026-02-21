---
name: angular-expert
description: |
  Angular expertise including modules vs standalone components, dependency injection,
  RxJS patterns, signals, Angular Material, change detection strategies (OnPush),
  lazy loading routes, and NgRx state management.
allowed-tools: Read, Grep, Glob, Bash
---

# Angular Expert

## Modules vs Standalone Components

- **Standalone components** are the recommended approach for new Angular projects (Angular 14+). Set `standalone: true` in the component decorator and import dependencies directly in the component.
- Use `importProvidersFrom()` in the application bootstrap for providing module-based dependencies (e.g., `HttpClientModule`, `BrowserAnimationsModule`) in a standalone app.
- For existing module-based projects, migrate incrementally. Standalone components can be imported into NgModules and vice versa.
- Organize features by domain folders, not by type (components, services, pipes). Colocate the component, its template, styles, tests, and related services.

## Dependency Injection

- Use `providedIn: 'root'` for singleton services that should be available application-wide. This enables tree-shaking of unused services.
- Use component-level `providers` for services scoped to a component and its children (e.g., form state, component-specific data service).
- Use `InjectionToken<T>` for non-class dependencies (configuration objects, feature flags, API URLs).
- Prefer constructor injection with `inject()` function (Angular 14+) over constructor parameters for cleaner syntax and better flexibility in inheritance.
- Use `@Optional()` and `@SkipSelf()` decorators when a dependency may not exist or when you need to resolve from a parent injector.

## RxJS Patterns

- Use the `async` pipe in templates to subscribe to observables. It handles subscription and unsubscription automatically, preventing memory leaks.
- Prefer declarative streams over imperative subscribe calls. Compose observables with `combineLatest`, `switchMap`, `mergeMap`, and `concatMap`.
- **switchMap**: Use for search/typeahead (cancels previous requests). **mergeMap**: Use for fire-and-forget operations. **concatMap**: Use for ordered sequential operations. **exhaustMap**: Use for login/submit buttons (ignores new requests while one is pending).
- Manage component-level subscriptions with `takeUntilDestroyed()` (Angular 16+) or a `destroy$` subject pattern.
- Use `shareReplay({ bufferSize: 1, refCount: true })` for shared API responses to avoid duplicate HTTP calls.

## Signals

- **Signals** (Angular 16+) provide fine-grained reactivity without RxJS for synchronous state. Use `signal()` for writable state, `computed()` for derived state.
- Use `effect()` for side effects that react to signal changes. Effects run in the injection context and clean up automatically.
- Convert between signals and observables: `toSignal()` to read observables as signals, `toObservable()` to use signals in RxJS streams.
- Signals integrate with `OnPush` change detection. Components using signals only re-render when their signal dependencies change.
- Prefer signals for component-local state and template bindings. Continue using RxJS for async streams, HTTP requests, and complex event coordination.

## Angular Material

- Use Angular Material components as the foundation for enterprise UI. Customize with a theme using `@angular/material` theming API.
- Define a custom theme with `mat.define-theme()` using design tokens for primary, secondary, and error palettes.
- Use the CDK (Component Dev Kit) for building custom components: `Overlay`, `Portal`, `DragDrop`, `A11y` (FocusTrap, LiveAnnouncer).
- Ensure all Material components have accessible labels. Use `mat-label` in form fields and `aria-label` on icon buttons.

## Change Detection (OnPush)

- Set `changeDetection: ChangeDetectionStrategy.OnPush` on all components. This restricts change detection to run only when inputs change by reference, events fire, or `markForCheck` is called.
- With OnPush, always use immutable data patterns. Return new object/array references instead of mutating existing ones.
- Use the `async` pipe or signals with OnPush. Both automatically trigger change detection when new values arrive.
- Avoid `ChangeDetectorRef.detectChanges()` except in rare cases (imperative third-party integrations). Prefer `markForCheck()` when manual triggering is necessary.

## Lazy Loading Routes

- Lazy-load feature routes with `loadComponent` (standalone) or `loadChildren` (modules): `{ path: 'admin', loadComponent: () => import('./admin/admin.component') }`.
- Group related routes into feature bundles. Each lazy-loaded route produces a separate JavaScript chunk.
- Use route resolvers (`ResolveFn`) to prefetch data before route activation. Use `CanActivateFn` guards for access control.
- Implement preloading strategies: `PreloadAllModules` for fast subsequent navigation, or custom strategies that preload based on user behavior.
- Use `@defer` blocks (Angular 17+) for lazily loading template sections within a component based on viewport visibility, interaction, or idle time.

## NgRx State Management

- Use NgRx for complex application state that is shared across many components or requires time-travel debugging.
- Structure state with feature stores: `createFeature({ name, reducer })`. Register with `provideStore()` and `provideState()`.
- Use `createActionGroup` for defining related actions. Use `createReducer` with `on()` handlers. Keep reducers pure.
- Use `createSelector` for derived state. Selectors are memoized. Compose selectors from simpler selectors.
- Use NgRx Effects for side effects (API calls, navigation, localStorage). Effects listen to actions and dispatch new actions.
- Use `@ngrx/component-store` for component-scoped state that does not need global visibility. It is lighter than the full NgRx store.
- Use `@ngrx/signals` (signal store) for a signals-first approach to state management in Angular 17+.
