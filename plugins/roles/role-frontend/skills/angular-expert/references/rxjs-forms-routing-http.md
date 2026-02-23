# RxJS Patterns, Forms, Routing, and HTTP

## When to load
Load when working with RxJS operators (switchMap/exhaustMap/mergeMap), reactive forms with typed builders, functional guards/resolvers, HTTP interceptors, or @defer lazy loading.

## RxJS Higher-Order Operators

| Operator | Behavior | Use Case |
|---|---|---|
| `switchMap` | Cancels previous inner observable | Search/typeahead, route param changes |
| `mergeMap` | Runs all inner observables concurrently | Fire-and-forget, parallel requests |
| `concatMap` | Queues inner observables sequentially | Ordered writes, sequential API calls |
| `exhaustMap` | Ignores new emissions while one is active | Login/submit buttons, prevent double-submit |

```typescript
// Search with switchMap — cancels stale requests
this.searchControl.valueChanges.pipe(
  debounceTime(300),
  distinctUntilChanged(),
  switchMap(query => this.searchService.search(query)),
)

// Submit with exhaustMap — ignores rapid clicks
this.submit$.pipe(exhaustMap(() => this.orderService.placeOrder(this.form.value)))

// Error handling with retry
this.http.get<User[]>('/api/users').pipe(
  retry({ count: 3, delay: 1000 }),
  catchError(error => { this.errorService.handle(error); return of([]) }),
)

// Unsubscribe with takeUntilDestroyed (Angular 16+)
export class DashboardComponent {
  private destroyRef = inject(DestroyRef)
  ngOnInit() {
    this.dataService.stream$
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe(data => this.processData(data))
  }
}
```

- Use `async` pipe in templates — handles subscription/unsubscription automatically.
- Use `shareReplay({ bufferSize: 1, refCount: true })` to avoid duplicate HTTP calls for shared responses.

## Reactive Forms

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
      zip: ['', [Validators.required, Validators.pattern(/^\d{5}$/)]],
    })
  }
}

function matchFields(f1: string, f2: string): ValidatorFn {
  return (c: AbstractControl): ValidationErrors | null =>
    c.get(f1)?.value === c.get(f2)?.value ? null : { fieldsMismatch: true }
}
```

- Use `NonNullableFormBuilder` for strict typing. Access controls with `form.controls.name`, not `form.get('name')`.

## Routing and Guards

```typescript
// Functional guard (Angular 15+)
export const authGuard: CanActivateFn = (route, state) => {
  const auth = inject(AuthService)
  return auth.isLoggedIn() ? true : inject(Router).createUrlTree(['/login'])
}

// Functional resolver
export const userResolver: ResolveFn<User> = (route) =>
  inject(UserService).getById(route.paramMap.get('id')!)

const routes: Routes = [
  { path: 'users/:id', loadComponent: () => import('./user-detail.component'),
    canActivate: [authGuard], resolve: { user: userResolver } },
  { path: 'admin', loadChildren: () => import('./admin/admin.routes').then(m => m.ADMIN_ROUTES),
    canMatch: [adminGuard] },
]
```

### @defer Blocks (Angular 17+)

```html
@defer (on viewport) {
  <app-heavy-chart [data]="chartData" />
} @placeholder { <div class="chart-skeleton"></div>
} @loading (minimum 500ms) { <app-spinner />
} @error { <p>Failed to load chart</p> }
```

## HTTP Interceptors (Angular 15+)

```typescript
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const token = inject(AuthService).getToken()
  if (token) req = req.clone({ setHeaders: { Authorization: `Bearer ${token}` } })
  return next(req).pipe(
    catchError(error => {
      if (error.status === 401) inject(AuthService).logout()
      return throwError(() => error)
    }),
  )
}
provideHttpClient(withInterceptors([authInterceptor, cachingInterceptor]))
```
