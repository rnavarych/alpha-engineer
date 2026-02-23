# NgRx State Management, Testing, Performance, and Material

## When to load
Load when implementing NgRx feature state, component-store, or signal store; writing Angular component tests or marble tests; optimizing bundle size or hydration; or using Angular Material and CDK components.

## NgRx State Management

```typescript
// Feature state + action group + selectors
export const userFeature = createFeature({
  name: 'user',
  reducer: createReducer(
    initialState,
    on(UserActions.loadUsersSuccess, (state, { users }) => ({ ...state, users, loading: false })),
    on(UserActions.loadUsersFailure, (state, { error }) => ({ ...state, error, loading: false })),
  ),
})

export const UserActions = createActionGroup({ source: 'User', events: {
  'Load Users': emptyProps(),
  'Load Users Success': props<{ users: User[] }>(),
  'Load Users Failure': props<{ error: string }>(),
}})

const { selectUsers } = userFeature
const selectActiveUsers = createSelector(selectUsers, users => users.filter(u => u.isActive))

// Effects — side effects (API calls, navigation, localStorage)
@Injectable()
export class UserEffects {
  private actions$ = inject(Actions)
  private userService = inject(UserService)

  loadUsers$ = createEffect(() =>
    this.actions$.pipe(
      ofType(UserActions.loadUsers),
      exhaustMap(() => this.userService.getAll().pipe(
        map(users => UserActions.loadUsersSuccess({ users })),
        catchError(error => of(UserActions.loadUsersFailure({ error: error.message }))),
      )),
    ),
  )
}

// @ngrx/signals — signal store (Angular 17+)
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

- NgRx: complex shared state or time-travel debugging. `@ngrx/component-store`: component-scoped state. `@ngrx/signals`: signals-first approach (Angular 17+).

## Testing

```typescript
// Component testing with TestBed
describe('UserCardComponent', () => {
  let fixture: ComponentFixture<UserCardComponent>

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [UserCardComponent],
      providers: [{ provide: UserService, useValue: jasmine.createSpyObj('UserService', ['getUser']) }],
    }).compileComponents()
    fixture = TestBed.createComponent(UserCardComponent)
    fixture.componentRef.setInput('user', mockUser)
    fixture.detectChanges()
  })

  it('displays user name', () => expect(fixture.nativeElement.textContent).toContain('John Doe'))
})

// Component harnesses
it('toggles expansion', async () => {
  const panel = await loader.getHarness(MatExpansionPanelHarness)
  await panel.toggle()
  expect(await panel.isExpanded()).toBeTrue()
})
// Marble testing for RxJS
it('debounces search', () => {
  const scheduler = new TestScheduler((actual, expected) => expect(actual).toEqual(expected))
  scheduler.run(({ cold, expectObservable }) => {
    const input$ = cold('a-b-c---|', { a: 'a', b: 'ab', c: 'abc' })
    expectObservable(input$.pipe(debounceTime(2))).toBe('------c-|', { c: 'abc' })
  })
})
```

## Performance and Material

- **Tree shaking**: Standalone components with direct imports beat NgModules for dead code elimination.
- **Bundle analysis**: `source-map-explorer` or `webpack-bundle-analyzer` with `ng build --source-map`.
- **Defer blocks**: Lazy-load template sections on viewport, interaction, idle, or timer triggers.
- **Hydration**: Angular 17+ non-destructive hydration — `provideClientHydration()` in bootstrap.
- **OnPush + signals**: Eliminates unnecessary change detection cycles.
- **Angular Material**: Customize with `mat.define-theme()`. CDK: `Overlay`, `Portal`, `DragDrop`, `A11y`. Use `mat-label` in form fields, `aria-label` on icon buttons.

## Anti-Patterns

| Anti-Pattern | Solution |
|---|---|
| Manual subscribe in components | `async` pipe or `toSignal()` |
| Using `any` type | Strict types, generics, `unknown` |
| Fat components (500+ lines) | Extract services, composables, child components |
| Nested subscribes | RxJS higher-order operators (switchMap, etc.) |
| Not using OnPush | Always set OnPush, use signals/async pipe |
| Importing entire modules | Standalone components with direct imports |
| String-based inject | `InjectionToken<T>` |
