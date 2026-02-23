# Startup Time, Image Loading & Profiling Tools

## When to load
Load when optimizing app startup time (cold/warm/hot), selecting image loading libraries, or choosing the right profiling tool to diagnose a performance bottleneck.

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
