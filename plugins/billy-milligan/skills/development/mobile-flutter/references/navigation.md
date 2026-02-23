# Navigation

## GoRouter Setup

```dart
// router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,

    // Global auth redirect
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isAuthenticated && !isAuthRoute) {
        return '/auth/login?redirect=${Uri.encodeComponent(state.matchedLocation)}';
      }
      if (isAuthenticated && isAuthRoute) {
        final redirect = state.uri.queryParameters['redirect'];
        return redirect ?? '/';
      }
      return null; // No redirect
    },

    routes: [
      // Shell route — persistent bottom navigation
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (_, __) => const OrdersScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => OrderDetailScreen(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      // Auth routes — outside shell (no bottom nav)
      GoRoute(
        path: '/auth/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (_, __) => const RegisterScreen(),
      ),
    ],

    errorBuilder: (_, __) => const NotFoundScreen(),
  );
});
```

## Shell Route with Bottom Navigation

```dart
class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;
  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/orders')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/');
      case 1: context.go('/orders');
      case 2: context.go('/profile');
    }
  }
}
```

## Deep Linking

```yaml
# android/app/src/main/AndroidManifest.xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="https" android:host="myapp.com" />
  <data android:scheme="myapp" />
</intent-filter>
```

```swift
// ios/Runner/Info.plist
// Add URL scheme: myapp
// Add associated domains: applinks:myapp.com
```

```dart
// GoRouter handles deep links automatically
// https://myapp.com/orders/123 -> OrderDetailScreen(id: '123')
// myapp://orders/123 -> same

// Programmatic navigation
context.go('/orders/123');          // Replace current route
context.push('/orders/123');        // Push on stack
context.pop();                      // Go back

// With query parameters
context.go('/orders?status=pending&page=2');

// Named routes (type-safe)
context.goNamed('orderDetail', pathParameters: {'id': '123'});
```

## Auth Guards

```dart
// Route-level guard
GoRoute(
  path: '/admin',
  redirect: (context, state) {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) return '/auth/login';
    if (user.role != 'admin') return '/'; // Not authorized
    return null;
  },
  builder: (_, __) => const AdminScreen(),
),

// Per-route middleware pattern
GoRoute(
  path: '/settings',
  builder: (_, __) => const SettingsScreen(),
  redirect: (context, state) {
    if (!ref.read(authNotifierProvider).hasValue) {
      return '/auth/login?redirect=/settings';
    }
    return null;
  },
),
```

## Anti-Patterns
- Navigator.push/pop for complex routing — use GoRouter for declarative routing
- Nested Navigator without ShellRoute — state lost on tab switch
- Hardcoded route strings — use constants or named routes
- Missing redirect for auth — unauthenticated users see protected screens briefly

## Quick Reference
```
GoRouter: declarative, redirect guards, deep linking automatic
ShellRoute: persistent scaffold (bottom nav) across routes
context.go: replace route, context.push: add to stack
redirect: return null (allow), return path (redirect)
Deep linking: scheme + host in AndroidManifest + Info.plist
Path params: :id -> state.pathParameters['id']
Query params: state.uri.queryParameters['key']
Auth guard: redirect in GoRouter, check auth state
```
