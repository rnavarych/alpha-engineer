# Flutter Performance

## Widget Rebuild Optimization

```dart
// 1. const constructors — O(1) rebuild check
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});  // const constructor

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 16),        // const — never rebuilt
        Icon(Icons.shopping_cart),    // const — never rebuilt
        Text('My Store'),            // const — never rebuilt
      ],
    );
  }
}

// Parent rebuild does NOT rebuild const AppHeader
// Flutter checks: same instance? Skip entirely.

// 2. Extract widgets to avoid rebuilding siblings
// BAD: entire row rebuilds when counter changes
Widget build(BuildContext context) {
  return Row(
    children: [
      const ExpensiveWidget(),     // Rebuilt unnecessarily!
      Text('Count: $counter'),     // This is what changed
    ],
  );
}

// GOOD: only CounterText rebuilds
Widget build(BuildContext context) {
  return const Row(
    children: [
      ExpensiveWidget(),           // const — never rebuilt
      CounterText(),               // Separate widget, own build
    ],
  );
}
```

## ListView.builder — Lazy Rendering

```dart
// BAD: Column + map — renders ALL items at once
Widget buildBad(List<Order> orders) {
  return SingleChildScrollView(
    child: Column(
      children: orders.map((o) => OrderCard(order: o)).toList(),
      // 1000 items = 1000 widgets in memory
    ),
  );
}

// GOOD: ListView.builder — only visible items rendered
Widget buildGood(List<Order> orders) {
  return ListView.builder(
    itemCount: orders.length,
    itemExtent: 80,               // Fixed height — O(1) scroll position
    itemBuilder: (context, index) {
      return OrderCard(
        key: ValueKey(orders[index].id),  // Stable key for diff
        order: orders[index],
      );
    },
  );
}

// For sections: use CustomScrollView + SliverList
Widget buildSections(Map<String, List<Order>> sections) {
  return CustomScrollView(
    slivers: [
      for (final entry in sections.entries) ...[
        SliverPersistentHeader(
          delegate: SectionHeader(title: entry.key),
          pinned: true,
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => OrderCard(order: entry.value[index]),
            childCount: entry.value.length,
          ),
        ),
      ],
    ],
  );
}
```

## Isolates — Background Computation

```dart
import 'dart:isolate';

// Heavy computation — runs in separate isolate (thread)
Future<List<Order>> parseOrdersInBackground(String jsonData) async {
  return await Isolate.run(() {
    // This runs in a separate isolate — doesn't block UI
    final data = jsonDecode(jsonData) as List;
    return data.map((e) => Order.fromJson(e)).toList();
  });
}

// compute() helper for simpler cases
final result = await compute(expensiveFunction, inputData);

// Long-running isolate with ports
Future<void> startBackgroundWorker() async {
  final receivePort = ReceivePort();
  await Isolate.spawn(_workerEntryPoint, receivePort.sendPort);

  final sendPort = await receivePort.first as SendPort;

  // Send work to isolate
  final responsePort = ReceivePort();
  sendPort.send([data, responsePort.sendPort]);
  final result = await responsePort.first;
}

void _workerEntryPoint(SendPort sendPort) {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  receivePort.listen((message) {
    final data = message[0];
    final replyPort = message[1] as SendPort;
    final result = processData(data); // Heavy work
    replyPort.send(result);
  });
}
```

## Anti-Patterns
- Column + map() for lists > 20 items — renders everything immediately
- Missing `const` on static widgets — unnecessary rebuilds
- Heavy computation on main isolate — freezes UI
- Not using `itemExtent` for fixed-height lists — slower scroll
- `setState` rebuilding entire screen — extract stateful widget

## Quick Reference
```
const: every static widget — Text, Icon, SizedBox, Padding
ListView.builder: itemExtent for fixed height, ValueKey for stable keys
Isolates: Isolate.run() for heavy computation (JSON parsing, crypto)
select(): watch only needed fields — prevents unnecessary rebuilds
RepaintBoundary: wrap expensive subtrees to isolate repaints
```

## When to load
Load when optimizing widget rebuild frequency, implementing lazy list rendering, or offloading heavy computation to isolates.
