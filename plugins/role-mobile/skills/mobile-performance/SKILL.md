---
name: mobile-performance
description: |
  Expert guidance on mobile performance optimization: achieving 60fps rendering,
  memory management (leak detection, large image handling), battery optimization,
  startup time reduction (cold/warm/hot), image loading strategies (Glide, SDWebImage,
  cached_network_image), and profiling tools (Instruments, Android Profiler, Flipper).
  Use when diagnosing or improving mobile app performance.
allowed-tools: Read, Grep, Glob, Bash
---

You are a mobile performance specialist. Every recommendation must be measurable and actionable.

## 60fps Rendering

### Frame Budget
- 60fps = 16.67ms per frame; 120fps (ProMotion) = 8.33ms per frame
- UI thread must complete layout, draw, and commit within the frame budget
- Off-screen rendering and overdraw are the most common frame drop causes

### iOS
- Avoid `cornerRadius` + `masksToBounds` together — use pre-rendered rounded images or `CAShapeLayer`
- Minimize `layer.shadowPath` recalculations — set explicit shadow paths
- Use `drawRect` for complex custom views instead of stacking multiple layers
- Profile with Instruments > Core Animation / Animation Hitches

### Android
- Reduce overdraw: use Layout Inspector to visualize layers, remove unnecessary backgrounds
- Avoid deep view hierarchies — use `ConstraintLayout` or Compose `Box`/`Row`/`Column`
- In Compose, use `derivedStateOf` to prevent unnecessary recompositions
- Profile with Android Studio Profiler > Frames / Janky frames

### Cross-Platform
- React Native: use `FlatList` with `getItemLayout`, enable `removeClippedSubviews`, prefer `FlashList`
- Flutter: use `RepaintBoundary`, avoid `Opacity` widget (use `FadeTransition`), `const` constructors

## Memory Management

### Leak Detection
- iOS: use Instruments > Leaks and Allocations; enable Malloc Stack Logging
- Android: use LeakCanary for automatic leak detection in debug builds
- React Native: monitor with Flipper memory plugin; watch for unmounted component listeners
- Flutter: use DevTools memory tab; watch for global references holding widget state

### Common Leak Patterns
- Strong reference cycles in closures — use `[weak self]` (iOS) or `WeakReference` (Android)
- Unregistered observers, listeners, and broadcast receivers
- Static references to Activity/Context (Android) — use ApplicationContext
- Large bitmaps retained in memory after navigation

### Large Image Handling
- Downsample images to display size before rendering
- iOS: use `UIImage(contentsOfFile:)` with `CGImageSourceCreateThumbnailAtIndex`
- Android: use `BitmapFactory.Options.inSampleSize` for downsampled decoding
- Use progressive JPEG/WebP for faster perceived loading
- Implement image caching with size limits and LRU eviction

## Battery Optimization

- Batch network requests — avoid frequent small requests (use HTTP/2 multiplexing)
- Use significant location changes over continuous GPS when precision is not critical
- Defer non-urgent work to charging state: `WorkManager` constraints (Android), `BGProcessingTask` (iOS)
- Minimize wake-ups from push notifications — use silent push sparingly
- Reduce timer frequency — use `CADisplayLink` or `Choreographer` only when visible
- Profile battery with Xcode Energy Organizer (iOS) and Battery Historian (Android)

## Startup Time

### Cold Start (App Process Not in Memory)
- Target: under 2 seconds to interactive on mid-range devices
- iOS: reduce dylib count, use static linking, defer non-essential initialization
- Android: avoid heavy `Application.onCreate` work, defer Hilt module initialization
- Minimize main thread work before first frame: lazy-load services, defer analytics init

### Warm Start (Process Alive, Activity Recreated)
- Restore state efficiently with `onSaveInstanceState` / `rememberSaveable`
- Cache parsed data in memory to avoid re-parsing on warm start

### Hot Start (Activity in Background, Brought Forward)
- Should be near-instant — ensure `onResume` does minimal work
- Avoid re-fetching data that has not changed (use ETag / Last-Modified)

### Measurement
- iOS: `os_signpost` for custom intervals, `MetricKit` for field data, `XCTest` metrics
- Android: `Macrobenchmark` library for automated startup measurement, `Perfetto` traces
- Use Firebase Performance Monitoring for field startup metrics

## Image Loading

### iOS
- **SDWebImage**: progressive loading, WebP support, memory + disk cache, transformations
- **Kingfisher**: Swift-native, SwiftUI integration, cache expiration policies
- **Nuke**: lightweight, pipeline architecture, prefetching, progressive JPEG

### Android
- **Glide**: automatic lifecycle management, disk caching, thumbnail loading, transformations
- **Coil**: Kotlin-first, Compose integration, lightweight, coroutine-based
- Configure memory cache (25% of available RAM) and disk cache (250MB default)

### Cross-Platform
- **React Native**: `react-native-fast-image` (backed by Glide/SDWebImage), prefetch on list scroll
- **Flutter**: `cached_network_image` with `CachedNetworkImageProvider`, placeholder widgets

## Profiling Tools

### Xcode Instruments
- **Time Profiler**: CPU hotspots and call stacks
- **Allocations**: Memory allocation tracking, transient vs persistent
- **Leaks**: Retain cycle detection
- **Core Animation**: FPS, off-screen rendering, blending
- **Network**: Request timeline, payload sizes, connection reuse
- **Energy Log**: CPU, network, location, and display energy impact

### Android Studio Profiler
- **CPU Profiler**: Method tracing, flame charts, system trace
- **Memory Profiler**: Heap dump, allocation tracking, leak detection
- **Network Profiler**: Request/response inspection, bandwidth
- **Energy Profiler**: CPU, network, and location wake-up monitoring
- **Compose Recomposition Counts**: Track unnecessary recompositions

### Flipper (React Native)
- Layout Inspector, Network Inspector, React DevTools integration
- Hermes CPU profiler for JavaScript thread analysis
- Database Inspector for AsyncStorage / SQLite inspection
- Custom plugins for app-specific debugging

### Flutter DevTools
- Widget rebuild tracker (rebuild counts per frame)
- Timeline view for frame rendering analysis
- Memory tab with allocation profiling
- Network tab for HTTP request inspection
