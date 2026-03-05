# Flutter Profiling

## DevTools Performance Tab

```bash
# Run in profile mode (release performance, debug tools enabled)
flutter run --profile

# Open DevTools
flutter pub global activate devtools
dart devtools

# Key metrics in Performance tab:
# - Build phase: <16ms for 60fps, <8ms for 120fps
# - Frame rendering: consistent green bars = smooth
# - Red bars = jank (dropped frames)

# Widget rebuild tracking
# DevTools > Performance > Track Widget Rebuilds
# Highlights widgets that rebuild on each frame — find unnecessary rebuilds
```

## Frame Budget

```
60fps target: 16ms per frame total
  - Build phase:  <8ms  — widget tree reconstruction
  - Layout phase: <4ms  — size and position calculation
  - Paint phase:  <4ms  — drawing to canvas

120fps target: 8ms per frame total
  - Common on iPad Pro, high-end Android
  - Impeller enables this more consistently than Skia

Where time goes:
  - Expensive build():    too many widgets rebuilt, complex layouts
  - Expensive paint():    custom painters, shadows, clip layers
  - Expensive layout():   intrinsic sizes, nested flex widgets
  - Main isolate work:    JSON parsing, image decoding, crypto

Diagnosis:
  - Profile mode + DevTools timeline — see exact frame breakdown
  - Look for "Build" bars > 8ms — that's your rebuild problem
  - Look for "Raster" bars > 8ms — that's your painting problem
```

## Memory Leak Detection

```dart
// Common memory leak: listener not removed
class OrderListPage extends StatefulWidget {
  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _controller.addListener(_onScroll); // MUST be removed
  }

  void _onScroll() { /* ... */ }

  @override
  void dispose() {
    _controller.removeListener(_onScroll); // REQUIRED
    _controller.dispose();                 // REQUIRED
    super.dispose();
  }
}

// DevTools Memory tab — detect leaks
// 1. Navigate to a page, take a snapshot
// 2. Navigate away, trigger GC
// 3. Take another snapshot
// 4. Compare: if page objects still exist -> memory leak
```

```dart
// RepaintBoundary — isolate expensive repaints
// Without: entire subtree repaints when animation runs
// With: only the boundary repaints

Widget build(BuildContext context) {
  return Stack(
    children: [
      // Heavy background — should NOT repaint on every frame
      RepaintBoundary(
        child: const BackgroundMap(),
      ),
      // Animated overlay — repaints every frame
      AnimatedMarker(position: userLocation),
    ],
  );
}
```

## Impeller Rendering Engine (Default Since Flutter 3.22+)

```
Impeller status in 2025-2026:
  - Default on iOS since Flutter 3.19 (Metal backend)
  - Default on Android since Flutter 3.22 (Vulkan backend)
  - Scribe: Impeller-based text rendering engine (Flutter 3.27+)
  - No SkSL shader pre-warming needed — ever

Key advantages over legacy Skia:
  - Pre-compiled shaders at build time — zero first-frame jank
  - Consistent 60/120fps — no mid-session compilation stutters
  - Metal (iOS) and Vulkan (Android) for modern GPU utilization
  - Better memory efficiency for complex scenes

Verify/control Impeller:
  flutter run                          # Impeller active by default
  flutter run --no-enable-impeller     # Disable for debugging only

Impeller debugging:
  flutter run --profile --enable-impeller
  # In DevTools > Performance: look for "Raster" thread spikes
  # Raster jank with Impeller: usually custom painters or save layers
```

## Shader Compilation Jank (Legacy / Skia Only)

```dart
// SkSL pre-warming — ONLY needed if targeting Flutter < 3.19 (iOS) or < 3.22 (Android)
// Modern Flutter + Impeller: skip this entirely

// Legacy SkSL warm-up:
// flutter run --profile --cache-sksl --purge-persistent-cache
// flutter build apk --bundle-sksl-path flutter_01.sksl.json

// With Impeller (current default): not needed — shaders are pre-compiled at build time
```

## Platform Channels — Performance Cost

```dart
// Platform channel calls are asynchronous but not free
// Each call crosses the Dart-native boundary: ~0.1-1ms overhead

// BAD: calling platform channel in build() or on every scroll event
Widget build(BuildContext context) {
  return FutureBuilder(
    future: platform.invokeMethod('getBatteryLevel'), // Called on every rebuild!
    builder: (context, snapshot) => Text('${snapshot.data}%'),
  );
}

// GOOD: cache platform channel results, refresh on demand
class BatteryProvider extends ChangeNotifier {
  int? _level;
  int? get level => _level;

  Future<void> refresh() async {
    _level = await platform.invokeMethod<int>('getBatteryLevel');
    notifyListeners();
  }
}

// EventChannel for continuous native -> Dart data (sensors, location)
// Use instead of polling via MethodChannel
final batteryStream = EventChannel('com.app/battery')
    .receiveBroadcastStream()
    .cast<int>();
```

## Anti-Patterns
- Running DevTools in debug mode — use `--profile` for real numbers
- Ignoring raster thread jank — custom painters and effects are expensive
- No `dispose()` for controllers and listeners — guaranteed memory leaks
- Animating inside a widget tree with no `RepaintBoundary` — entire screen repaints
- Using `MethodChannel` in a hot path (scroll, build) — bridge overhead adds up

## Quick Reference
```
Profile mode: flutter run --profile — real perf, debug tools available
Frame budget: 16ms (60fps), 8ms (120fps) — Build + Layout + Paint
Memory leaks: removeListener + dispose in dispose() — every time
RepaintBoundary: wrap expensive or animated subtrees
Impeller: default engine, no shader jank, pre-compiled at build time
Platform channels: cache results, use EventChannel for streams
DevTools Memory: snapshot before/after navigation — compare live objects
```

## When to load
Load when diagnosing frame drops with DevTools, tracking down memory leaks, wrapping subtrees with RepaintBoundary, understanding Impeller vs Skia tradeoffs, or optimizing platform channel usage.
