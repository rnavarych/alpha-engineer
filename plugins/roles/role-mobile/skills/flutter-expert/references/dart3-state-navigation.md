# Dart 3, State Management & Navigation

## When to load
Load when using Dart 3.x language features (records, patterns, sealed classes, extension types, macros), choosing or implementing state management (Riverpod 2, BLoC/Cubit, Signals, GetX), or configuring navigation with GoRouter or auto_route.

## Widget Composition

- Prefer composition over inheritance — build complex widgets from small, focused widgets
- Extract widget subtrees into separate classes (not methods) for rebuild optimization
- Use `const` constructors wherever possible to enable widget caching
- Separate stateless presentation widgets from stateful container widgets
- Use `Key` appropriately: `ValueKey` for list items, `GlobalKey` sparingly
- Keep `build()` methods lean — move logic to separate classes or extensions
- `InheritedWidget` for efficient data propagation without rebuilding the full tree

## Dart 3.x Features

### Records
- Anonymous immutable value types: `(String name, int age)` or named `({String name, int age})`
- Pattern-based destructuring: `final (name, age) = record;`
- Record types in function return for multiple-value returns without custom classes

### Patterns
- Switch expressions with pattern matching: `switch (shape) { Circle(:var radius) => ..., ... }`
- Object patterns: `case Circle(radius: var r) when r > 0`
- List and map patterns for destructuring collections
- Guard clauses in patterns with `when` keyword
- `if-case` statements for inline pattern matching

### Sealed Classes
- `sealed class Shape {}` — compiler guarantees exhaustive switch coverage
- All subclasses must be in the same library as the sealed class
- Pair with pattern matching for type-safe, exhaustive state modeling
- Prefer native sealed classes over `freezed` for simple unions without JSON needs

### Class Modifiers
- `final` class: cannot be extended or implemented outside the library
- `base` class: can be extended but not implemented outside the library
- `interface` class: can be implemented but not extended outside the library
- `mixin` class: can be used as both a mixin and a class

### Extension Types (Dart 3.3+) — Zero-Cost Wrappers
Extension types are zero-cost abstractions at compile time — no runtime overhead vs. a raw type.
Use for domain type safety (prevent primitive obsession) and wrapping external/JS types.

```dart
// Zero-cost wrapper for primitive obsession prevention
extension type UserId(String _) implements String {}
extension type OrderId(int _) implements int {}
extension type Cents(int _) implements int {
  double get dollars => _ / 100.0;
}

// Compile-time error if you mix up IDs
void processOrder(UserId userId, OrderId orderId) { ... }

final uid = UserId('user_abc');
final oid = OrderId(42);
processOrder(uid, oid);       // OK
processOrder(oid, uid);       // COMPILE ERROR — types don't match

// Extension type with methods
extension type Temperature.celsius(double celsius) {
  double get fahrenheit => celsius * 9 / 5 + 32;
  Temperature.fromFahrenheit(double f) : this.celsius((f - 32) * 5 / 9);
}

// JS interop (dart:js_interop) — extension types replace package:js
import 'dart:js_interop';

extension type HTMLInputElement._(JSObject _) implements JSObject {
  external String get value;
  external set value(String v);
}
```

### Null-Aware Elements in Collections (Dart 3.4+)
```dart
// Null-aware spread — already existed
final combined = [...?nullableList, ...list];

// Null-aware elements in list/map/set literals
final tags = ['core', if (isPremium) 'premium', ?optionalTag];
//                                                ^ adds element only if non-null
```

### Macros (Approaching Stable in 2025-2026)
- Compile-time code generation without `build_runner` for annotated classes
- `@JsonCodable()` macro generates `fromJson`/`toJson` without manual boilerplate
- Available behind `--enable-experiment=macros` in Dart 3.x; watch dart.dev for stable GA

```dart
// Once stable — replaces json_annotation + json_serializable + build_runner
@JsonCodable()
class User {
  final String id;
  final String name;
  final String email;
}
// fromJson/toJson generated at compile time — no generated files in VCS
```

### dart:js_interop (Replaces dart:html / package:js)
- Use `import 'dart:js_interop'` for all web interop in 2025+
- `dart:html` and `package:js` are deprecated — incompatible with WASM compilation
- Extension types model JS objects (see Extension Types section above)

```dart
import 'dart:js_interop';
import 'package:web/web.dart'; // typed web APIs via extension types

final el = document.querySelector('#app') as HTMLElement;
el.textContent = 'Hello from Dart';
```

## State Management

**Decision guide** (ordered by risk/complexity, not popularity):

| Approach | When to use | Risk |
|---|---|---|
| `setState` + composition | ≤3 screens, prototypes, UI-only state | None |
| BLoC / Cubit | Any team size, production apps, complex flows | Low |
| Riverpod 2 | Teams comfortable with framework weight | Medium |
| Signals | Local/component-level reactive state | Low |
| GetX | Don't | High |

### Vanilla — setState + Composition (Underrated)
Flutter's own recommendation for many cases. Combine with widget composition to limit rebuild scope. No extra packages, no learning curve.

```dart
// Extract stateful widget to scope rebuilds
class CounterButton extends StatefulWidget {
  const CounterButton({super.key});
  @override
  State<CounterButton> createState() => _CounterButtonState();
}

class _CounterButtonState extends State<CounterButton> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => setState(() => _count++),
      child: Text('Count: $_count'),
    );
  }
}

// InheritedWidget / InheritedNotifier for sharing state without packages
class CartModel extends ChangeNotifier { ... }

class CartScope extends InheritedNotifier<CartModel> {
  const CartScope({super.key, required super.notifier, required super.child});
  static CartModel of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CartScope>()!.notifier!;
}
```

### BLoC / Cubit — Recommended Standard (flutter_bloc 9.x)
De-facto standard. API has been stable for years. Minimal API surface: two classes (`Bloc`, `Cubit`) + a handful of widgets. Exhaustive, strict, well-documented — all edge cases have established patterns.

**Cubit** for state without event indirection; **Bloc** when event semantics add clarity.

```dart
// Sealed states — Dart 3 native, no freezed needed for simple unions
sealed class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState { final User user; AuthAuthenticated(this.user); }
class AuthUnauthenticated extends AuthState {}
class AuthFailure extends AuthState { final String message; AuthFailure(this.message); }

// Pattern matching in BlocBuilder — exhaustive by compiler
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) => switch (state) {
    AuthInitial()         => const SizedBox.shrink(),
    AuthLoading()         => const CircularProgressIndicator(),
    AuthAuthenticated(:final user) => HomeScreen(user: user),
    AuthUnauthenticated() => const LoginScreen(),
    AuthFailure(:final message)   => ErrorView(message: message),
  },
)
```

- `BlocProvider` for DI, `BlocBuilder` for UI, `BlocListener` for side effects
- `BlocSelector` for rebuilding only when a specific derived value changes
- `blocTest` from `bloc_test` for unit testing in isolation
- `HydratedBloc` for automatic state persistence across restarts

### Riverpod 2 — Viable But Heavier (Explicit Trade-offs)
Popular framework-level solution. Know what you're signing up for:

**Benefits:** Compile-time safe DI, `AsyncValue` for typed async states, no `BuildContext` dependency in providers, excellent testability.

**Trade-offs:**
- `ConsumerWidget` / `HookConsumerWidget` replace Flutter's base `StatelessWidget` — coupling your UI layer to a specific state framework
- Codegen (`@riverpod` + `build_runner`) is optional but practically expected for non-trivial apps — a state manager requiring codegen is an architectural smell worth acknowledging
- Full framework, not just a state manager — `ProviderScope`, dependency graph, caching policies, lifecycle, family/override system all have their own learning curve
- `RiverpodLint` via `custom_lint` adds analyzer load; on large projects this causes measurable IDE slowdown

```dart
part 'order_provider.g.dart';

@riverpod
Future<List<Order>> orders(OrdersRef ref, {required String userId}) async {
  final api = ref.watch(apiClientProvider);
  return api.getOrders(userId);
}

@riverpod
class CartNotifier extends _$CartNotifier {
  @override
  List<CartItem> build() => [];
  void add(CartItem item) => state = [...state, item];
}
```

### Signals (For Local/Component-Level Reactivity)
Fine-grained reactivity without provider scoping — zero extra coupling to widget hierarchy.
Best for component-local state or teams who want React-style fine-grained updates.

```dart
final count = signal(0);
final doubled = computed(() => count.value * 2);

Watch((context) => Text('${doubled.value}')); // Only this rebuilds

final cleanup = effect(() => print('Count: ${count.value}'));
// cleanup(); // dispose
```

### GetX — Avoid
Replaces `MaterialApp` (!) to take over navigation, breaking Flutter's own page transitions. Documentation contains inaccuracies. State, DI, navigation, and utilities all tangled together. Extremely difficult to remove from an existing codebase.

## Navigation

Both **GoRouter** and **auto_route** are mature, actively maintained, and use Flutter's Navigator 2.0 API — there is no clear winner. Choose based on team preference and project complexity.

| | GoRouter | auto_route |
|---|---|---|
| Maintainer | Google (flutter.dev) | Community |
| Route definitions | Code (manual or `@TypedGoRoute`) | Code generation (`@RoutePage`) |
| Codegen | Optional (via `@TypedGoRoute`) | Required |
| UI coupling | None | Adds `@RoutePage` annotation to screens |
| Nested nav | `StatefulShellRoute` | `AutoRouter` + `AutoTabsRouter` |
| Auth guards | `redirect` callback | `AutoRouteGuard` |

### GoRouter 14+ (Official)
- `GoRoute` + `ShellRoute` for route tree definition
- `StatefulShellRoute.indexedStack` for preserving state across bottom nav tabs
- Type-safe routes via `@TypedGoRoute` + `build_runner` (optional but recommended)
- `redirect` callback for auth guards; `refreshListenable` triggers re-evaluation on auth change
- `context.go()` (replace), `context.push()` (stack), `context.pop()`

```dart
@TypedGoRoute<HomeRoute>(path: '/', routes: [
  TypedGoRoute<OrderDetailRoute>(path: 'orders/:id'),
])
class HomeRoute extends GoRouteData {
  Widget build(BuildContext context, GoRouterState state) => const HomeScreen();
}

class OrderDetailRoute extends GoRouteData {
  final String id;
  const OrderDetailRoute({required this.id});
  Widget build(BuildContext context, GoRouterState state) => OrderDetailScreen(id: id);
}

// Type-safe navigation
const HomeRoute().go(context);
OrderDetailRoute(id: '123').push(context);
```

### GoRouter — StatefulShellRoute (Bottom Nav with State Preservation)

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) =>
      ScaffoldWithNavBar(navigationShell: navigationShell),
  branches: [
    StatefulShellBranch(routes: [GoRoute(path: '/', builder: ...)]),
    StatefulShellBranch(routes: [GoRoute(path: '/orders', builder: ...)]),
    StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: ...)]),
  ],
)
```

### auto_route (Code-Generated, Less Manual Config)
- `@RoutePage()` annotation on screen widgets; `build_runner` generates route classes
- Fully type-safe: `context.router.push(OrderDetailRoute(id: '123'))`
- `AutoRouteGuard` for auth flows; `AutoTabsRouter` for persistent tab state
- Reduces manual route registration — preferred when route tree is large or deeply nested
- Trade-off: adds `@RoutePage` to every screen widget (UI layer coupled to routing package)

```dart
@RoutePage()
class OrderDetailScreen extends StatelessWidget {
  final String id;
  const OrderDetailScreen({@PathParam('id') required this.id, super.key});
  ...
}

// Navigation
context.router.push(OrderDetailRoute(id: '123'));
context.router.pop();
```

**Avoid**: Beamer, Routemaster, and other third-party routers — smaller community, more niche, not worth the lock-in.
