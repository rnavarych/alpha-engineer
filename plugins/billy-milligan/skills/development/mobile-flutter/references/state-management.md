# State Management

## Riverpod (Recommended)

```dart
// providers/order_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simple state provider
final counterProvider = StateProvider<int>((ref) => 0);

// Async data provider — fetches and caches
@riverpod
Future<List<Order>> orders(OrdersRef ref, {required String userId}) async {
  final api = ref.watch(apiClientProvider);
  return api.getOrders(userId);
}

// Notifier — complex state with methods
@riverpod
class CartNotifier extends _$CartNotifier {
  @override
  List<CartItem> build() => [];

  void addItem(CartItem item) {
    final existing = state.indexWhere((i) => i.productId == item.productId);
    if (existing >= 0) {
      state = [
        ...state.sublist(0, existing),
        state[existing].copyWith(quantity: state[existing].quantity + 1),
        ...state.sublist(existing + 1),
      ];
    } else {
      state = [...state, item];
    }
  }

  void removeItem(String productId) {
    state = state.where((i) => i.productId != productId).toList();
  }

  double get total => state.fold(0, (sum, i) => sum + i.price * i.quantity);
}
```

```dart
// Usage in widgets
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider(userId: 'user_123'));

    return ordersAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
      data: (orders) => ListView.builder(
        itemCount: orders.length,
        itemBuilder: (_, index) => OrderCard(order: orders[index]),
      ),
    );
    // AsyncValue.when: exhaustive handling — no forgotten loading states
  }
}
```

## Targeted Rebuilds with select()

```dart
// Without select: rebuilds on ANY user change
class UserAvatar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);  // Rebuilds on every field change
    return CircleAvatar(backgroundImage: NetworkImage(user.avatarUrl));
  }
}

// With select: rebuilds ONLY when avatarUrl changes
class UserAvatar extends ConsumerWidget {
  const UserAvatar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarUrl = ref.watch(
      userProvider.select((user) => user.avatarUrl),
    );
    return CircleAvatar(backgroundImage: NetworkImage(avatarUrl));
  }
}
// User name changes? This widget does NOT rebuild.
```

## BLoC Pattern

```dart
// order_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

// Events
sealed class OrderEvent {}
class LoadOrders extends OrderEvent { final String userId; LoadOrders(this.userId); }
class CancelOrder extends OrderEvent { final String orderId; CancelOrder(this.orderId); }

// States
sealed class OrderState {}
class OrderInitial extends OrderState {}
class OrderLoading extends OrderState {}
class OrderLoaded extends OrderState { final List<Order> orders; OrderLoaded(this.orders); }
class OrderError extends OrderState { final String message; OrderError(this.message); }

// Bloc
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository _repo;

  OrderBloc(this._repo) : super(OrderInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<CancelOrder>(_onCancelOrder);
  }

  Future<void> _onLoadOrders(LoadOrders event, Emitter<OrderState> emit) async {
    emit(OrderLoading());
    try {
      final orders = await _repo.getOrders(event.userId);
      emit(OrderLoaded(orders));
    } catch (e) {
      emit(OrderError(e.toString()));
    }
  }

  Future<void> _onCancelOrder(CancelOrder event, Emitter<OrderState> emit) async {
    await _repo.cancelOrder(event.orderId);
    // Reload after cancel
    if (state is OrderLoaded) {
      add(LoadOrders((state as OrderLoaded).orders.first.userId));
    }
  }
}
```

## Comparison

```
                 Riverpod        BLoC              Provider
Complexity       Medium          High              Low
Testability      Excellent       Excellent         Good
Boilerplate      Low (codegen)   High (events)     Low
Async handling   AsyncValue      Stream            Manual
Learning curve   Medium          Steep             Low
When to use      Most apps       Large teams,      Simple apps,
                                 strict patterns   quick prototypes
```

## Anti-Patterns
- `setState` in deep widget trees — prop drilling, rebuilds entire subtree
- Watching entire provider when only one field needed — use `select()`
- Manual `isLoading`/`hasError` booleans — use `AsyncValue.when()`
- Mixing state management approaches — pick one per project

## Quick Reference
```
Riverpod: ProviderScope at root, ref.watch (reactive), ref.read (actions)
AsyncValue.when: data/loading/error — exhaustive, no manual flags
select(): ref.watch(provider.select((s) => s.field)) — surgical rebuilds
BLoC: events in, states out, sealed classes for exhaustive matching
ConsumerWidget: use when reading providers
StateProvider: simple reactive value
Notifier: complex state with methods (Riverpod 2.0)
```
