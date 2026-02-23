# New Architecture, Animations & High-Performance Lists

## When to load
Load when migrating to or debugging the React Native New Architecture (JSI, Fabric, TurboModules, Codegen, Bridgeless), implementing animations with Reanimated 3 and Gesture Handler v2, or optimizing list rendering with FlashList.

## New Architecture (React Native 0.73+)

### JSI (JavaScript Interface)
- Direct synchronous communication between JavaScript and C++ host objects
- Eliminates JSON serialization overhead of the old bridge
- Enables synchronous calls to native modules from JavaScript
- Powers TurboModules (lazy native modules) and Fabric (new renderer)

### Fabric Renderer
- Synchronous layout calculation on the UI thread — eliminates bridge round-trips for layout
- Concurrent rendering support for React 18 features (transitions, Suspense)
- Shadow tree shared between JS and native with copy-on-write semantics
- Enable via `newArchEnabled: true` in `gradle.properties` and `Podfile`

### TurboModules
- Lazy initialization — native modules only loaded when first accessed (improves startup)
- Type-safe native bindings generated from TypeScript spec via Codegen
- Synchronous execution option for time-critical operations
- `TurboModuleRegistry.getEnforcing<Spec>('ModuleName')` for typed module access

### Codegen
- Generates C++, Objective-C, and Kotlin/Java bindings from TypeScript specs
- Spec files: `NativeModuleName.ts` with `TurboModuleRegistry` call or Fabric component spec
- Run with `yarn react-native codegen` or automatically during build

### Bridgeless Mode
- Removes legacy bridge entirely — all communication via JSI
- Available in React Native 0.73+ as opt-in: `RCTSetNewArchEnabled(true)` in `AppDelegate`
- Not all third-party libraries support bridgeless yet — audit before enabling

### Migration Checklist
1. Enable Hermes engine
2. Set `newArchEnabled=true` in both platform build files
3. Migrate custom native modules to TurboModules (TypeScript spec + Codegen)
4. Migrate custom native views to Fabric components
5. Audit third-party libraries for New Architecture compatibility
6. Enable `bridgelessEnabled` once all modules are compatible
7. Run E2E test suite to catch behavioral regressions

## Animation & Gestures

### Reanimated 3
- All animation logic runs on the UI thread via worklets — zero JS thread involvement
- `useSharedValue(initialValue)` for animated values shared between JS and UI thread
- `useAnimatedStyle(() => ({...}))` for reactive style derivation from shared values
- `withTiming(toValue, config)` — linear/eased animation to a target value
- `withSpring(toValue, config)` — physics-based spring animation
- `withDecay(config)` — velocity-based deceleration animation
- `withSequence(...animations)`, `withDelay(ms, animation)` for choreographed sequences
- `withRepeat(animation, count, reverse)` for looping animations
- `useAnimatedScrollHandler` for performant scroll-driven animations
- `runOnJS(fn)(args)` to call JavaScript functions from the UI thread worklet (use sparingly)
- Layout animations: `entering={FadeIn}`, `exiting={FadeOut}`, `layout={LinearTransition}`
- `useAnimatedKeyboard()` for keyboard-aware layouts without `KeyboardAvoidingView`
- `useDerivedValue` for computed shared values derived from other shared values

### Gesture Handler v2
- `GestureDetector` with composable gesture objects replaces `PanGestureHandler` etc.
- `Gesture.Pan()`, `Gesture.Tap()`, `Gesture.Pinch()`, `Gesture.Rotation()`, `Gesture.Fling()`
- `Gesture.Simultaneous(g1, g2)` for concurrent gestures (pinch + rotate)
- `Gesture.Exclusive(g1, g2)` for mutually exclusive gesture recognition
- `Gesture.Race(g1, g2)` for first-to-activate gesture wins
- State machine: `onBegin`, `onUpdate`, `onEnd`, `onFinalize`, `onFail`, `onCancel`

## High-Performance Lists

### FlashList (by Shopify)
- Drop-in replacement for `FlatList` with 5-10x performance improvement
- Recycles cell components instead of creating/destroying — reduces JS bridge calls
- `estimatedItemSize` required for virtualization optimization
- `getItemType` for heterogeneous list items (multiple cell types without blank frames)
- `overrideItemLayout` for precise item size hints on non-uniform lists
- `drawDistance` controls how far ahead to pre-render (default: 500px)

### Best Practices for Any List
- `getItemLayout` (FlatList) or `estimatedItemSize` (FlashList) for scroll-to-index
- `removeClippedSubviews={true}` on Android for off-screen item unmounting
- `maxToRenderPerBatch` and `windowSize` tuning for scroll smoothness
- `initialNumToRender` to control first-paint count (match visible item count)
- Avoid complex render functions — extract to `React.memo` wrapped components
- Use `keyExtractor` returning stable unique IDs, never array indices
