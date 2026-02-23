# Rendering Performance & Memory Management

## When to load
Load when diagnosing frame drops, jank, or memory leaks — covers 60fps frame budget, platform-specific rendering pitfalls, leak detection patterns, and image memory handling.

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
