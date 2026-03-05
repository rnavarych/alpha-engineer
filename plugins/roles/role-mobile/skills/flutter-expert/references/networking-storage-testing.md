# Networking, Local Storage & Testing

## When to load
Load when choosing networking libraries (Dio, retrofit, Ferry/Artemis), selecting a local database (Drift, ObjectBox, Isar, Hive CE, Realm, SharedPreferences), or setting up widget tests, golden tests, integration tests, or mock-based unit tests.

## Networking

### http (Baseline — Start Here)
- Dart's official HTTP package from the Dart team (`package:http`)
- Simple, zero-dependency, works everywhere (mobile, web, desktop, server)
- Sufficient for most apps: GET/POST/PUT/DELETE, custom headers, timeouts
- Use this by default; reach for Dio only when you need its specific features

```dart
import 'package:http/http.dart' as http;

final client = http.Client();

// GET with auth header
final response = await client.get(
  Uri.parse('https://api.example.com/orders'),
  headers: {'Authorization': 'Bearer $token'},
);
if (response.statusCode == 200) {
  final orders = (jsonDecode(response.body) as List)
      .map((e) => Order.fromJson(e))
      .toList();
}

// Always close the client when done (or use http.get() for one-shots)
client.close();
```

### Dio (When You Need More)
- Reach for Dio when `http` isn't enough: interceptors pipeline, request cancellation, FormData/multipart upload, retry logic, HTTP/2
- `Interceptor` for auth token injection, logging, retry, error normalization
- `CancelToken` for cancelling requests on screen dispose
- Not needed for simple REST clients — don't add the dependency speculatively

```dart
final dio = Dio(BaseOptions(
  baseUrl: 'https://api.example.com',
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 30),
))
  ..interceptors.add(AuthInterceptor(tokenStorage))
  ..interceptors.add(RetryInterceptor(dio: dio, retries: 3))
  ..interceptors.add(LogInterceptor(responseBody: kDebugMode));
```

### retrofit (Type-Safe Layer on Top of Dio)
- Annotation-based HTTP client — generates Dio call implementations via `build_runner`
- `@RestApi()`, `@GET`, `@POST`, `@Body()`, `@Path()`, `@Query()` annotations
- Justified only if already using Dio AND have many endpoints — adds codegen overhead

```dart
@RestApi(baseUrl: 'https://api.example.com')
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  @GET('/orders')
  Future<List<Order>> getOrders(@Query('userId') String userId);

  @POST('/orders')
  Future<Order> createOrder(@Body() CreateOrderDto dto);
}
```

### GraphQL (Ferry / graphql_flutter)
- **Ferry**: normalized cache, reactive streams, Hive or BoxStorage for persistence
  - Generated request/response types from `.graphql` schema files
- **graphql_flutter**: `Query`, `Mutation`, `Subscription` widgets with `GraphQLClient`
- `graphql_codegen` for generating Dart classes from GraphQL schema

## Local Storage

**Storage decision guide:**

| Need | Solution |
|---|---|
| Primitives, settings, flags | `shared_preferences` |
| Credentials, tokens, session | `flutter_secure_storage` |
| Relational data, SQL queries, migrations | Drift |
| Models without relational structure (advanced) | ObjectBox or Isar (see risks below) |
| Offline-first with cloud sync | Realm + Atlas Device Sync |

### SharedPreferences — Baseline for Primitives
- Simple key-value persistence backed by `NSUserDefaults` / `SharedPreferences`
- Correct use: strings, ints, bools, doubles, string lists — app settings, flags, preferences
- **Do not** serialize models to JSON strings and store here — that's a Drift use case
- `shared_preferences_async` for fully async API (no synchronous reads on Android)

### flutter_secure_storage — For Sensitive Data
- AES encryption on Android (Keystore), Keychain on iOS
- Use for: auth tokens, session cookies, credentials, API keys
- Replace `shared_preferences` for anything that shouldn't be readable if device is compromised

### Drift — Recommended for Structured/Relational Data
- Type-safe SQLite ORM with code generation
- `@DriftDatabase(tables: [...])` annotation generates DAO and query APIs
- Reactive queries: `select(...).watch()` returns `Stream` for auto-updating UI
- Multi-platform: iOS, Android, Web (via `sql.js`), Desktop
- `DriftIsolate` for background database operations without blocking UI thread
- When to use: you have models, need SQL queries, need migrations, need stability

### ObjectBox — High-Performance NoSQL (Advanced Use Only)
- High-performance NoSQL object store with native bindings
- `@Entity()` + `@Id()` annotations on plain Dart classes
- Reactive queries: `box.query(...).watch(triggerImmediately: true)`
- Vector search support for AI/ML similarity queries
- Justified for: large datasets where SQLite read performance is a bottleneck

### Isar and Hive — Know the Risks

> **Both Isar and the original Hive share the same author and the same architectural concerns.**

**Risks to evaluate before adopting:**
- **In-memory flushing**: both load boxes/collections into RAM before persisting — corruption possible on force-kill or OOM (documented production incidents exist)
- **No isolate support**: cannot safely read/write from background isolates — blocks offloading DB work from the main thread
- **Abandonment risk**: original Hive is unmaintained; Isar's release cadence has slowed significantly

**If you choose them anyway:**
- `hive_ce` (community edition) is the maintained Hive fork — use it over `hive`
- Isar 4.x is still in active use in many projects; keep an eye on maintenance status
- Limit to non-critical, easily-regenerable data (caches, local drafts)
- Never use as the sole storage for data the user cannot recover

### Realm Flutter — For Cloud Sync Scenarios
- MongoDB Realm SDK: offline-first with Atlas Device Sync
- `@RealmModel()` annotation + `build_runner` for schema generation
- Live objects: `RealmResults` auto-updates on change
- Justified specifically when you need real-time multi-device sync out of the box

## Testing

### Widget Testing
- `testWidgets('desc', (tester) async {...})` with `WidgetTester`
- `await tester.pumpWidget(MyWidget())` to render the widget tree
- `await tester.tap(find.byType(ElevatedButton))` → `await tester.pump()` for re-render
- `await tester.pumpAndSettle()` waits for all animations and async work to complete
- `find.byKey`, `find.byType`, `find.text`, `find.byWidget` for element location
- Override providers in tests via `ProviderScope.overrides` (Riverpod)

### Golden Tests (Screenshot Regression)
- Pixel-perfect screenshot regression testing
- `await expectLater(find.byType(MyWidget), matchesGoldenFile('goldens/my_widget.png'))`
- Run `flutter test --update-goldens` to regenerate baseline images

#### alchemist (Recommended)
- Successor to `golden_toolkit` — cleaner API, better CI support
- Multi-variant golden tests: test light/dark theme, multiple screen sizes in one file
- `goldenTest('name', fileName: 'widget', builder: () => GoldenTestGroup(...))`
- Separate CI mode (`isCI: true`) for stable pixel comparison on CI

```dart
goldenTest(
  'OrderCard renders correctly',
  fileName: 'order_card',
  builder: () => GoldenTestGroup(
    columns: 2,
    children: [
      GoldenTestScenario(
        name: 'light theme',
        child: const OrderCard(order: mockOrder),
      ),
      GoldenTestScenario(
        name: 'dark theme',
        child: Theme(
          data: ThemeData.dark(),
          child: const OrderCard(order: mockOrder),
        ),
      ),
    ],
  ),
);
```

### Integration Tests
- `integration_test` package for end-to-end testing on real devices / emulators
- Run on Firebase Test Lab: `gcloud firebase test android run`
- `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` in test entry point

### Patrol 3.x (Recommended for E2E with Native Interactions)
- Major rewrite in 3.x: Patrol Test Runner replaces `flutter drive`
- `patrol test` CLI runs tests on device — no need for `flutter drive` boilerplate
- Native automation: toggle WiFi, grant permissions, interact with system dialogs/notifications
- `$('Text on screen').tap()`, `$.native.grantPermissionWhenInUse()` for high-level API
- Parallel test execution on multiple devices via Patrol Test Runner

```dart
patrolTest(
  'completes purchase flow',
  ($) async {
    await $.pumpWidgetAndSettle(const App());

    // Native: grant camera permission without test failing
    await $.native.grantPermissionWhenInUse();

    await $('Product').tap();
    await $('Add to Cart').tap();
    await $('Checkout').tap();

    expect($('Order Confirmed'), findsOneWidget);
  },
);
```

### Mocktail
- Null-safe mocking library without code generation
- `class MockUserRepo extends Mock implements UserRepository {}`
- `when(() => mock.getUser()).thenReturn(User(...))` for stubbing
- `when(() => mock.getUser()).thenAnswer((_) async => User(...))` for async
- `verify(() => mock.getUser()).called(1)` for interaction verification

### bloc_test
- `blocTest<MyBloc, MyState>('description', build: () => MyBloc(), act: ..., expect: ...)`
- `act` closure sends events; `expect` is the list of expected emitted states
- Works with both `Bloc` and `Cubit`
- `setUp` / `tearDown` for shared test dependencies
