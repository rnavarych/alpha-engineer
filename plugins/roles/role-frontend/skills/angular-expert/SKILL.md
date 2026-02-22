---
name: angular-expert
description: |
  Angular expertise including modules vs standalone components, dependency injection,
  RxJS patterns, signals, Angular Material, change detection strategies (OnPush),
  lazy loading routes, and NgRx state management.
allowed-tools: Read, Grep, Glob, Bash
---

# Angular Expert

## Standalone Components

- **Standalone components** are the recommended approach for all new Angular projects (Angular 14+). Set `standalone: true` in the component decorator and import dependencies directly in the component.

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

- **Application bootstrap** without NgModule:

```typescript
// main.ts
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

- For existing module-based projects, migrate incrementally. Standalone components can be imported into NgModules and vice versa.
- Organize features by domain folders, not by type (components, services, pipes). Colocate the component, its template, styles, tests, and related services.

## Signals

- **signal()**: Create writable signals for reactive state. Signals are synchronous and fine-grained.

```typescript
@Component({ ... })
export class CounterComponent {
  count = signal(0)
  doubleCount = computed(() => this.count() * 2)

  increment() {
    this.count.update(c => c + 1)
    // or this.count.set(this.count() + 1)
  }
}
```

- **computed()**: Derive values from other signals. Computed signals are memoized and only recalculate when dependencies change.

```typescript
const firstName = signal('John')
const lastName = signal('Doe')
const fullName = computed(() => `${firstName()} ${lastName()}`)
```

- **effect()**: Run side effects when signals change. Effects run in the injection context and clean up automatically.

```typescript
effect(() => {
  console.log(`Count changed to: ${this.count()}`)
  // Automatically tracks this.count() as a dependency
})

// effect with cleanup
effect((onCleanup) => {
  const sub = someObservable$.subscribe()
  onCleanup(() => sub.unsubscribe())
})
```

- **Signal-based inputs, outputs, queries** (Angular 17.1+):

```typescript
@Component({ ... })
export class ProductComponent {
  // Signal inputs
  product = input.required<Product>()
  showDetails = input(false)                // optional with default

  // Signal outputs
  addToCart = output<Product>()

  // Model (two-way binding)
  quantity = model(1)

  // Signal queries
  chart = viewChild<ElementRef>('chart')
  items = viewChildren(ItemComponent)
  content = contentChild(PanelContent)
}
```

- **toSignal / toObservable**: Bridge between signals and RxJS.

```typescript
// Observable to signal
const users = toSignal(this.userService.getUsers(), { initialValue: [] })

// Signal to observable
const count$ = toObservable(this.count)
```

- Prefer signals for component-local state and template bindings. Continue using RxJS for async streams, HTTP requests, and complex event coordination.

## Dependency Injection

- Use `providedIn: 'root'` for singleton services that should be available application-wide. This enables tree-shaking of unused services.

```typescript
@Injectable({ providedIn: 'root' })
export class AuthService {
  private currentUser = signal<User | null>(null)
  isLoggedIn = computed(() => this.currentUser() !== null)
}
```

- Use component-level `providers` for services scoped to a component and its children.
- Use `InjectionToken<T>` for non-class dependencies.

```typescript
export const API_BASE_URL = new InjectionToken<string>('API_BASE_URL')
export const FEATURE_FLAGS = new InjectionToken<FeatureFlags>('FEATURE_FLAGS')

// Provide
providers: [
  { provide: API_BASE_URL, useValue: environment.apiUrl },
  { provide: FEATURE_FLAGS, useFactory: () => loadFlags() },
]

// Inject
export class ApiService {
  private baseUrl = inject(API_BASE_URL)
  private flags = inject(FEATURE_FLAGS)
}
```

- Prefer the `inject()` function (Angular 14+) over constructor parameters for cleaner syntax and better flexibility in inheritance.
- Use `@Optional()` and `@SkipSelf()` decorators when a dependency may not exist or when you need to resolve from a parent injector.

## RxJS Patterns

- Use the `async` pipe in templates to subscribe to observables. It handles subscription and unsubscription automatically.

```html
<ul>
  @for (user of users$ | async; track user.id) {
    <li>{{ user.name }}</li>
  }
</ul>
```

- **Higher-order mapping operators** — choosing the right one:

| Operator | Behavior | Use Case |
|---|---|---|
| `switchMap` | Cancels previous inner observable | Search/typeahead, route param changes |
| `mergeMap` | Runs all inner observables concurrently | Fire-and-forget operations, parallel requests |
| `concatMap` | Queues inner observables sequentially | Ordered writes, sequential API calls |
| `exhaustMap` | Ignores new emissions while one is active | Login/submit buttons, prevent double-submit |

```typescript
// Search with switchMap (cancels stale requests)
this.searchControl.valueChanges.pipe(
  debounceTime(300),
  distinctUntilChanged(),
  switchMap(query => this.searchService.search(query)),
)

// Submit with exhaustMap (ignore rapid clicks)
this.submit$.pipe(
  exhaustMap(() => this.orderService.placeOrder(this.form.value)),
)
```

- **Error handling in streams**:

```typescript
this.http.get<User[]>('/api/users').pipe(
  retry({ count: 3, delay: 1000 }),
  catchError(error => {
    this.errorService.handle(error)
    return of([]) // fallback value
  }),
)
```

- Manage component-level subscriptions with `takeUntilDestroyed()` (Angular 16+):

```typescript
export class DashboardComponent {
  private destroyRef = inject(DestroyRef)

  ngOnInit() {
    this.dataService.stream$
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe(data => this.processData(data))
  }
}
```

- Use `shareReplay({ bufferSize: 1, refCount: true })` for shared API responses to avoid duplicate HTTP calls.

## Change Detection

- Set `changeDetection: ChangeDetectionStrategy.OnPush` on all components. This restricts change detection to run only when inputs change by reference, events fire, or `markForCheck` is called.
- With OnPush, always use immutable data patterns. Return new object/array references instead of mutating existing ones.
- Use the `async` pipe or signals with OnPush. Both automatically trigger change detection when new values arrive.
- Avoid `ChangeDetectorRef.detectChanges()` except in rare cases. Prefer `markForCheck()` when manual triggering is necessary.

### Zoneless Angular (experimental)

- Angular 18+ supports experimental zoneless change detection, removing the `zone.js` dependency entirely.

```typescript
bootstrapApplication(AppComponent, {
  providers: [
    provideExperimentalZonelessChangeDetection(),
  ],
})
```

- In zoneless mode, change detection is triggered only by signals, async pipe, and explicit `markForCheck()`. This significantly improves performance.
- Signals are the primary reactivity primitive in zoneless Angular. Migrate from `zone.js`-dependent patterns to signals.

## Forms

### Reactive Forms

```typescript
@Component({ ... })
export class RegistrationComponent {
  private fb = inject(NonNullableFormBuilder)

  form = this.fb.group({
    name: ['', [Validators.required, Validators.minLength(2)]],
    email: ['', [Validators.required, Validators.email]],
    addresses: this.fb.array([this.createAddressGroup()]),
  })

  createAddressGroup() {
    return this.fb.group({
      street: ['', Validators.required],
      city: ['', Validators.required],
      zip: ['', [Validators.required, Validators.pattern(/^\d{5}$/)]],
    })
  }

  get addresses() {
    return this.form.controls.addresses
  }

  addAddress() {
    this.addresses.push(this.createAddressGroup())
  }
}
```

### Typed Forms (Angular 14+)

- Use `NonNullableFormBuilder` for strict typing where all controls have non-nullable defaults.
- Form types are inferred automatically. Access controls with `form.controls.name` (not `form.get('name')`).

### Custom Validators

```typescript
function matchFields(field1: string, field2: string): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    const value1 = control.get(field1)?.value
    const value2 = control.get(field2)?.value
    return value1 === value2 ? null : { fieldsMismatch: true }
  }
}

// Async validator
function uniqueEmail(userService: UserService): AsyncValidatorFn {
  return (control: AbstractControl) =>
    userService.checkEmail(control.value).pipe(
      map(exists => exists ? { emailTaken: true } : null),
      catchError(() => of(null)),
    )
}
```

## Routing

### Functional Guards and Resolvers (Angular 15+)

```typescript
// Functional guard
export const authGuard: CanActivateFn = (route, state) => {
  const auth = inject(AuthService)
  const router = inject(Router)
  return auth.isLoggedIn() ? true : router.createUrlTree(['/login'])
}

// Functional resolver
export const userResolver: ResolveFn<User> = (route) => {
  const userService = inject(UserService)
  return userService.getById(route.paramMap.get('id')!)
}

// Route configuration
const routes: Routes = [
  {
    path: 'users/:id',
    loadComponent: () => import('./user-detail.component'),
    canActivate: [authGuard],
    resolve: { user: userResolver },
  },
  {
    path: 'admin',
    loadChildren: () => import('./admin/admin.routes').then(m => m.ADMIN_ROUTES),
    canMatch: [adminGuard],
  },
]
```

### Lazy Loading

- Use `loadComponent` for standalone components and `loadChildren` for route groups.
- Use `@defer` blocks (Angular 17+) for lazily loading template sections within a component:

```html
@defer (on viewport) {
  <app-heavy-chart [data]="chartData" />
} @placeholder {
  <div class="chart-skeleton"></div>
} @loading (minimum 500ms) {
  <app-spinner />
} @error {
  <p>Failed to load chart</p>
}
```

### Preloading Strategies

```typescript
provideRouter(routes,
  withPreloading(PreloadAllModules),           // preload everything
  // or custom strategy:
  withPreloading(QuicklinkStrategy),           // preload visible links
)
```

## HTTP Client

### Functional Interceptors (Angular 15+)

```typescript
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const auth = inject(AuthService)
  const token = auth.getToken()

  if (token) {
    req = req.clone({
      setHeaders: { Authorization: `Bearer ${token}` },
    })
  }

  return next(req).pipe(
    catchError(error => {
      if (error.status === 401) auth.logout()
      return throwError(() => error)
    }),
  )
}

// Caching interceptor
export const cachingInterceptor: HttpInterceptorFn = (req, next) => {
  const cache = inject(HttpCacheService)
  if (req.method !== 'GET') return next(req)

  const cached = cache.get(req.urlWithParams)
  if (cached) return of(cached)

  return next(req).pipe(
    tap(response => cache.set(req.urlWithParams, response)),
  )
}

// Register
provideHttpClient(
  withInterceptors([authInterceptor, cachingInterceptor]),
)
```

## NgRx State Management

- Use NgRx for complex application state that is shared across many components or requires time-travel debugging.

```typescript
// Feature state
export const userFeature = createFeature({
  name: 'user',
  reducer: createReducer(
    initialState,
    on(UserActions.loadUsersSuccess, (state, { users }) => ({
      ...state, users, loading: false,
    })),
    on(UserActions.loadUsersFailure, (state, { error }) => ({
      ...state, error, loading: false,
    })),
  ),
})

// Action group
export const UserActions = createActionGroup({
  source: 'User',
  events: {
    'Load Users': emptyProps(),
    'Load Users Success': props<{ users: User[] }>(),
    'Load Users Failure': props<{ error: string }>(),
  },
})

// Selectors (auto-generated by createFeature)
const { selectUsers, selectLoading, selectError } = userFeature

// Custom composed selector
const selectActiveUsers = createSelector(
  selectUsers,
  users => users.filter(u => u.isActive),
)
```

- Use NgRx Effects for side effects (API calls, navigation, localStorage).

```typescript
@Injectable()
export class UserEffects {
  private actions$ = inject(Actions)
  private userService = inject(UserService)

  loadUsers$ = createEffect(() =>
    this.actions$.pipe(
      ofType(UserActions.loadUsers),
      exhaustMap(() =>
        this.userService.getAll().pipe(
          map(users => UserActions.loadUsersSuccess({ users })),
          catchError(error => of(UserActions.loadUsersFailure({ error: error.message }))),
        ),
      ),
    ),
  )
}
```

- Use `@ngrx/component-store` for component-scoped state that does not need global visibility.
- Use `@ngrx/signals` (signal store) for a signals-first approach in Angular 17+:

```typescript
export const UserStore = signalStore(
  withState<UserState>({ users: [], loading: false }),
  withComputed(({ users }) => ({
    activeUsers: computed(() => users().filter(u => u.isActive)),
    userCount: computed(() => users().length),
  })),
  withMethods((store, userService = inject(UserService)) => ({
    async loadUsers() {
      patchState(store, { loading: true })
      const users = await firstValueFrom(userService.getAll())
      patchState(store, { users, loading: false })
    },
  })),
)
```

## Testing

### Component Testing with TestBed

```typescript
describe('UserCardComponent', () => {
  let fixture: ComponentFixture<UserCardComponent>

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [UserCardComponent],
      providers: [
        { provide: UserService, useValue: jasmine.createSpyObj('UserService', ['getUser']) },
      ],
    }).compileComponents()

    fixture = TestBed.createComponent(UserCardComponent)
    fixture.componentRef.setInput('user', mockUser)
    fixture.detectChanges()
  })

  it('displays user name', () => {
    expect(fixture.nativeElement.textContent).toContain('John Doe')
  })
})
```

### Component Harnesses

```typescript
it('should toggle expansion', async () => {
  const panel = await loader.getHarness(MatExpansionPanelHarness)
  expect(await panel.isExpanded()).toBeFalse()
  await panel.toggle()
  expect(await panel.isExpanded()).toBeTrue()
})
```

### Marble Testing for RxJS

```typescript
it('should debounce search', () => {
  const scheduler = new TestScheduler((actual, expected) => {
    expect(actual).toEqual(expected)
  })

  scheduler.run(({ cold, expectObservable }) => {
    const input$ = cold('a-b-c---|', { a: 'a', b: 'ab', c: 'abc' })
    const result$ = input$.pipe(debounceTime(2))
    expectObservable(result$).toBe('------c-|', { c: 'abc' })
  })
})
```

## Performance

- **Tree shaking**: Standalone components with direct imports enable better tree shaking than NgModules.
- **Bundle analysis**: Use `source-map-explorer` or `webpack-bundle-analyzer` with `ng build --source-map`.
- **Defer blocks**: Lazy-load template sections based on viewport, interaction, idle, or timer triggers.
- **Hydration (SSR)**: Angular 17+ provides non-destructive hydration. Use `provideClientHydration()` in the bootstrap.
- **OnPush everywhere**: Combined with signals, OnPush eliminates unnecessary change detection cycles.

## Angular Material and CDK

- Use Angular Material components as the foundation for enterprise UI. Customize with `mat.define-theme()` using design tokens.
- Use the CDK (Component Dev Kit) for building custom components: `Overlay`, `Portal`, `DragDrop`, `A11y` (FocusTrap, LiveAnnouncer).
- Ensure all Material components have accessible labels. Use `mat-label` in form fields and `aria-label` on icon buttons.

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Solution |
|---|---|---|
| Manual subscribe in components | Memory leaks, verbose cleanup | Use `async` pipe or `toSignal()` |
| Using `any` type | Loses type safety benefits | Use strict types, generics, `unknown` |
| Fat components (500+ lines) | Hard to test and maintain | Extract services, composables, child components |
| Nested subscribes | Callback hell, race conditions | Use RxJS operators (switchMap, etc.) |
| Not using OnPush | Excessive change detection | Always set OnPush, use signals/async pipe |
| Importing entire modules | Large bundles | Use standalone components with direct imports |
| String-based inject | No type safety, no tree-shaking | Use `InjectionToken<T>` |
