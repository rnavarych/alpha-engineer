# Standalone Components, Signals, and Dependency Injection

## When to load
Load when building Angular standalone components, working with signals (signal/computed/effect/input/output/model), or configuring the dependency injection system.

## Standalone Components

```typescript
@Component({
  standalone: true,
  selector: 'app-user-card',
  imports: [CommonModule, RouterLink, MatButtonModule],
  template: `
    <mat-card>
      <h2>{{ user().name }}</h2>
      <a [routerLink]="['/users', user().id]">View Profile</a>
    </mat-card>
  `,
})
export class UserCardComponent {
  user = input.required<User>()
}
```

```typescript
// main.ts — bootstrap without NgModule
bootstrapApplication(AppComponent, {
  providers: [
    provideRouter(routes, withPreloading(PreloadAllModules)),
    provideHttpClient(withInterceptors([authInterceptor])),
    provideAnimationsAsync(),
    provideStore(),
    provideState(userFeature),
    provideEffects(UserEffects),
  ],
})
```

- Standalone is the recommended approach for all new Angular projects (Angular 14+).
- Organize features by domain folders, not by type. Colocate component, template, styles, tests, and services.
- Migrate incrementally — standalone components can be imported into NgModules and vice versa.

## Signals

```typescript
@Component({ ... })
export class CounterComponent {
  count = signal(0)
  doubleCount = computed(() => this.count() * 2)

  increment() { this.count.update(c => c + 1) }
}

// effect with cleanup
effect((onCleanup) => {
  const sub = someObservable$.subscribe()
  onCleanup(() => sub.unsubscribe())
})

// Signal-based inputs/outputs/queries (Angular 17.1+)
@Component({ ... })
export class ProductComponent {
  product = input.required<Product>()
  showDetails = input(false)
  addToCart = output<Product>()
  quantity = model(1)
  chart = viewChild<ElementRef>('chart')
  items = viewChildren(ItemComponent)
}

// Bridge between signals and RxJS
const users = toSignal(this.userService.getUsers(), { initialValue: [] })
const count$ = toObservable(this.count)
```

- Prefer signals for component-local state and template bindings.
- Continue using RxJS for async streams, HTTP, and complex event coordination.

## Dependency Injection

```typescript
// Singleton service — tree-shakeable
@Injectable({ providedIn: 'root' })
export class AuthService {
  private currentUser = signal<User | null>(null)
  isLoggedIn = computed(() => this.currentUser() !== null)
}

// InjectionToken for non-class dependencies
export const API_BASE_URL = new InjectionToken<string>('API_BASE_URL')

providers: [
  { provide: API_BASE_URL, useValue: environment.apiUrl },
  { provide: FEATURE_FLAGS, useFactory: () => loadFlags() },
]

export class ApiService {
  private baseUrl = inject(API_BASE_URL)  // inject() preferred over constructor params
}
```

- Use `inject()` function (Angular 14+) over constructor parameters — cleaner, better for inheritance.
- Use `@Optional()` and `@SkipSelf()` when a dependency may not exist or resolve from a parent injector.
- Component-level `providers` for services scoped to a component subtree.

## Change Detection

```typescript
// OnPush on every component — restricts detection to input changes, events, markForCheck
@Component({ changeDetection: ChangeDetectionStrategy.OnPush })

// Zoneless (Angular 18+, experimental)
bootstrapApplication(AppComponent, {
  providers: [provideExperimentalZonelessChangeDetection()],
})
```

- With OnPush, always use immutable data patterns — return new references instead of mutating.
- Use `async` pipe or signals with OnPush — both trigger change detection automatically.
- In zoneless mode signals are the primary reactivity primitive. Migrate from zone.js-dependent patterns.
