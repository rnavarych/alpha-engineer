# Networking, Local Storage & Testing

## When to load
Load when choosing networking libraries (Dio, Chopper, Ferry/Artemis), selecting a local database (Drift, ObjectBox, Isar, Hive, SharedPreferences), or setting up widget tests, golden tests, integration tests, or mock-based unit tests.

## Networking

### Dio
- Feature-rich HTTP client with interceptors, FormData, and request cancellation
- `Interceptor` for auth headers, logging, retry logic, and error normalization
- `QueuedInterceptorsWrapper` for sequential interceptor execution
- `CancelToken` for cancelling in-flight requests (e.g., on screen dispose)

### Chopper
- Retrofit-inspired type-safe HTTP client with code generation
- `@ChopperApi()` + `build_runner` generates HTTP method implementations
- Converter interface for request/response body transformation

### GraphQL (Ferry / Artemis)
- **Ferry**: normalized cache, Hive or BoxStorage for persistence, reactive streams
  - Generated request/response types from `.graphql` schema files
- **Artemis**: code generation from GraphQL schema → Dart classes + query wrappers
- `graphql_flutter`: `Query`, `Mutation`, `Subscription` widgets with `GraphQLClient`

## Local Storage

### Drift (formerly Moor)
- Type-safe SQLite ORM with code generation
- `@DriftDatabase(tables: [...])` annotation generates DAO and query APIs
- Reactive queries: `select(...).watch()` returns `Stream` for auto-updating UI
- Multi-platform: iOS, Android, Web (via `sql.js`), Desktop
- `DriftIsolate` for background database operations without blocking UI thread

### ObjectBox
- High-performance NoSQL object store with native bindings
- `@Entity()` and `@Id()` annotations on plain Dart classes
- Reactive queries: `box.query(...).watch(triggerImmediately: true)`
- Relations: `ToOne<T>`, `ToMany<T>` for object graph modeling
- Excellent read performance for large datasets vs. SQLite

### Isar
- Fast embedded database with full-text search and ACID transactions
- Schema defined with annotations: `@collection`, `@Index`, `@embedded`
- `isar.writeTxn(() => isar.items.put(item))` for transactional writes
- Isar Inspector (web UI) for debugging database state during development

### Hive
- Lightweight key-value store with binary serialization
- `@HiveType()` + `@HiveField()` annotations with `build_runner` for TypeAdapters
- `LazyBox<T>` for large datasets
- Encryption: `HiveAesCipher` for AES-256 at-rest encryption

### SharedPreferences
- Simple key-value persistence backed by `NSUserDefaults` / `SharedPreferences`
- For typed, observable preferences, wrap with Riverpod provider

## Testing

### Widget Testing
- `testWidgets('desc', (tester) async {...})` with `WidgetTester`
- `await tester.pumpWidget(MyWidget())` to render the widget tree
- `await tester.tap(find.byType(ElevatedButton))` → `await tester.pump()` for re-render
- `await tester.pumpAndSettle()` waits for all animations and async work to complete
- `find.byKey`, `find.byType`, `find.text`, `find.byWidget` for element location

### Golden Tests
- Pixel-perfect screenshot regression testing
- `await expectLater(find.byType(MyWidget), matchesGoldenFile('goldens/my_widget.png'))`
- Run `flutter test --update-goldens` to regenerate baseline images
- `golden_toolkit` for multi-device and multi-theme golden testing

### Integration Tests
- `integration_test` package for end-to-end testing on real devices / emulators
- `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart`
- Run on Firebase Test Lab: `gcloud firebase test android run`

### Patrol
- Enhanced integration testing with native interaction support
- `$('Text on screen').tap()`, `$.pump()` for high-level test API
- Native automation: toggle WiFi, grant permissions, interact with system dialogs

### Mocktail
- Null-safe mocking library without code generation
- `class MockUserRepo extends Mock implements UserRepository {}`
- `when(() => mock.getUser()).thenReturn(User(...))` for stubbing
- `verify(() => mock.getUser()).called(1)` for interaction verification

### bloc_test
- `blocTest<MyBloc, MyState>('description', build: () => MyBloc(), act: ..., expect: ...)`
- `act` closure sends events; `expect` is the list of expected emitted states
- Works with both `Bloc` and `Cubit`
