---
name: mobile-flutter
description: |
  Flutter patterns: Riverpod state management, GoRouter with auth redirect, const widgets
  (O(1) rebuild), ListView.builder for long lists, select() for targeted rebuilds,
  AsyncValue for loading/error/data states, platform channels. Use when building Flutter apps.
allowed-tools: Read, Grep, Glob
---

# Flutter Patterns

## When to Use This Skill
- Setting up Flutter app architecture with Riverpod
- Navigation with GoRouter including auth guards
- Optimizing widget rebuilds
- Handling async state (loading, error, data)
- List performance with ListView.builder

## Core Principles

1. **const widgets everywhere** — const constructor = compile-time constant = O(1) rebuild check
2. **Riverpod for state** — testable, type-safe, no BuildContext dependency
3. **GoRouter for navigation** — declarative routing with redirect guards
4. **AsyncValue pattern** — typed loading/error/data states, never manual bool flags
5. **ListView.builder for lists** — lazy rendering, not Column with list.map()

---

## Patterns ✅

### App Structure with Riverpod

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';

void main() {
  runApp(
    ProviderScope(  // Riverpod root — wraps entire app
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'My App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
```

### GoRouter with Auth Guard

```dart
// router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isAuthenticated && !isAuthRoute) {
        return '/auth/login?redirect=${state.matchedLocation}';
      }
      if (isAuthenticated && isAuthRoute) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/orders',
        builder: (_, __) => const OrdersScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => OrderDetailScreen(id: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
    ],
  );
});
```

### Riverpod State Providers

```dart
// providers/auth_provider.dart
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<User?> build() async {
    // Load persisted session on startup
    return ref.watch(secureStorageProvider).getUser();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();  // Show loading state
    state = await AsyncValue.guard(() =>
      ref.read(authServiceProvider).login(email, password)
    );
    // AsyncValue.guard: if throws, state = AsyncError; else state = AsyncData
  }

  Future<void> logout() async {
    await ref.read(secureStorageProvider).clearUser();
    state = const AsyncData(null);
  }
}

// Usage in widgets
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return authState.when(
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
      data: (user) => user != null
          ? DashboardScreen(user: user)
          : const LoginScreen(),
    );
  }
}
```

### Targeted Rebuilds with select()

```dart
// Without select: entire widget rebuilds when ANY part of user changes
class UserNameWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);  // Rebuilds on any user change
    return Text(user.name);
  }
}

// With select: only rebuilds when name changes
class UserNameWidget extends ConsumerWidget {
  const UserNameWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(userProvider.select((user) => user.name));
    // Rebuilds ONLY when user.name changes, not user.email, user.avatar, etc.
    return Text(name);
  }
}
```

### const Widgets for Performance

```dart
// Without const: new widget instance every parent rebuild
// With const: same instance reused — O(1) rebuild check

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});  // Must have const constructor

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          const Padding(  // const — never rebuilt
            padding: EdgeInsets.all(16),
            child: Icon(Icons.shopping_cart),
          ),
          Text(product.name),  // Not const — product.name may change
          const SizedBox(height: 8),  // const — never rebuilt
          ElevatedButton(
            onPressed: () => addToCart(product),
            child: const Text('Add to Cart'),  // const Text
          ),
        ],
      ),
    );
  }
}

// Lint rule to enforce const: add to analysis_options.yaml
// prefer_const_constructors: true
// prefer_const_literals_to_create_immutables: true
```

### ListView.builder for Long Lists

```dart
// Wrong: Column + list.map() — renders ALL items at once
Widget buildListBad(List<Order> orders) {
  return SingleChildScrollView(
    child: Column(
      children: orders.map((order) => OrderCard(order: order)).toList(),
      // All 1000 items rendered immediately
    ),
  );
}

// Correct: ListView.builder — lazy rendering
Widget buildListGood(List<Order> orders) {
  return ListView.builder(
    itemCount: orders.length,
    itemExtent: 80,         // Fixed height — enables O(1) position calculation
    itemBuilder: (context, index) {
      return OrderCard(
        key: ValueKey(orders[index].id),  // Stable key for efficient diff
        order: orders[index],
      );
    },
    // Only visible + buffer items are built
  );
}

// For very large lists: use flutter_sliver_tools or custom_sliver
// For section lists: SliverList + SliverPersistentHeader
```

---

## Anti-Patterns ❌

### setState in Deep Widget Trees
**What it is**: Passing callback functions deep through widget tree to trigger parent setState.
**What breaks**: Rebuilds entire subtree. Callback prop drilling. Hard to debug.
**Fix**: Riverpod providers. Widgets read and write state directly without passing callbacks.

### Rebuilding Entire Widget for Small State Changes
**What it is**: Watching a large provider when only one field is needed.
**What breaks**: `ref.watch(largeUserProvider)` — any change to user (avatar, email, preferences) triggers rebuild of widgets that only show the user's name.
**Fix**: `ref.watch(largeUserProvider.select((u) => u.name))` — surgical rebuilds.

### Column + map() for Lists
**What it is**: `Column(children: items.map(buildItem).toList())`
**What breaks**: All N items built and laid out immediately. 1000 items = 1000 widgets in memory. Long build time, janky scrolling, high memory.
**Fix**: `ListView.builder` with `itemExtent` for fixed-height items.

### Missing const on Leaf Widgets
**What it is**: Decorative widgets without `const` constructor.
**What breaks**: Every parent rebuild creates new instances of static text, icons, paddings — wasted work.
**Fix**: Use `const` for all widgets that don't depend on runtime data. Enable `prefer_const_constructors` lint.

---

## Quick Reference

```
Riverpod: ProviderScope at root, ref.watch() for reactive, ref.read() for actions
AsyncValue.when: data/loading/error — never manual isLoading bool
GoRouter redirect: return null (allow), return path (redirect)
select(): ref.watch(provider.select((state) => state.field)) — targeted rebuilds
const: every static widget — Text, Icon, SizedBox, Padding with const data
ListView.builder: itemExtent for fixed height — O(1) scroll position
ValueKey: stable keys on list items for efficient diff
ConsumerWidget: use when reading providers; StatelessWidget if no providers
```
