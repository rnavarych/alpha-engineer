# Storage, UI Frameworks, Media & Notifications

## When to load
Load when choosing storage solutions (MMKV, WatermelonDB), selecting a UI framework or styling approach (NativeWind, Tamagui, Gluestack, Unistyles, Paper), implementing graphics (Skia, SVG, Lottie), or integrating push notifications and monetization.

## Storage Solutions

### React Native MMKV
- Key-value storage 10x faster than AsyncStorage (native C++ implementation)
- Synchronous API: `storage.set('key', value)`, `storage.getString('key')`
- Instance-based with custom IDs: `new MMKV({ id: 'user-storage' })`
- Encryption: `new MMKV({ id: 'secure', encryptionKey: '...' })`
- Integration with Zustand: `createJSONStorage(() => zustandMMKVStorage)`

### WatermelonDB
- SQLite-backed database optimized for large datasets (10K-100K+ records)
- Observable queries via RxJS: components automatically re-render on data change
- Built-in sync protocol: `synchronize({ pullChanges, pushChanges })`
- Relations: `hasMany`, `belongsTo` with lazy-loaded association objects
- Batch operations for high-throughput writes: `database.write(() => [...])`

### Async Storage
- `@react-native-async-storage/async-storage` for simple key-value persistence
- Always use `MMKV` for new projects — AsyncStorage is JSON-serialized, single-threaded, slower

## UI Frameworks & Styling

### NativeWind v4
- Tailwind CSS utility classes compiled to StyleSheet.create at build time
- `className` prop on any React Native component
- Dark mode with `dark:` prefix, platform modifiers with `ios:` / `android:` / `web:`
- `cssInterop` for applying NativeWind styles to third-party components

### Tamagui
- Cross-platform UI kit with compile-time optimization to native StyleSheet
- Design tokens: `$color`, `$space`, `$size`, `$radius`, `$font`, `$zIndex`
- `Sheet`, `Dialog`, `Popover`, `Toast`, `Select`, `Switch` cross-platform components
- `styled()` API for extending any component with design tokens

### Gluestack UI v2
- Accessible component library built on top of NativeWind
- Cross-platform: same components for React Native and React web
- Full accessibility: ARIA roles, keyboard navigation, screen reader support

### Unistyles
- `createStyleSheet(theme => ({...}))` — theme-aware styles without re-renders
- Runtime theme switching without component remount
- v3 rewrites styles in C++ for zero-overhead application

### React Native Paper
- Material Design 3 component library with full MD3 theming
- `PaperProvider` with `MD3LightTheme` or custom `configureFonts` + `MD3DarkTheme`

## Graphics & Media

### React Native Skia
- Hardware-accelerated 2D graphics via Google Skia rendering engine
- `<Canvas>` component as the root for all Skia drawing
- Shaders, blend modes, gradients, color filters, and image filters
- Animations via `useSharedValue` from Reanimated — worklet-compatible
- Perfect for charts, data visualization, drawing apps, and game-like UI

### react-native-svg
- SVG rendering via native SVG support (`RNSVGView`)
- `Svg`, `G`, `Path`, `Circle`, `Rect`, `Line`, `ClipPath` primitives
- Animate SVG elements with Reanimated's `useAnimatedProps`
- `svgr` CLI for converting SVG files to React Native components

### Lottie
- After Effects animations exported as JSON via the Bodymovin plugin
- Programmatic control: `lottieRef.current.play(startFrame, endFrame)`
- Dynamic color segments for theming animation colors at runtime

## Push Notifications & Messaging

### Notifee
- Local notification scheduling with full platform customization
- Android channels with `createChannel` — required for Android 8+
- iOS custom sounds, critical alerts, communication notifications (iOS 15+)
- `onForegroundEvent` / `onBackgroundEvent` for notification interaction handling

### React Native Firebase (RNFB)
- `@react-native-firebase/messaging` for FCM-based push on Android + iOS (APNs bridge)
- `getToken()` for FCM registration token; `onTokenRefresh` handler for token rotation
- `onMessage` for foreground messages, `setBackgroundMessageHandler` for background
- Data-only messages for silent background processing without visible notification

## Monetization & OTA

### RevenueCat
- `Purchases.configure({ apiKey })` — single SDK for App Store + Google Play
- `Purchases.getOfferings()` for server-configured product packages
- `Purchases.purchasePackage(package)` handles purchase + receipt validation
- Entitlements system: server-side access control that survives app updates

### Shorebird (React Native)
- Code push for React Native — patches JS + native code
- `shorebird patch android` / `shorebird patch ios` for over-the-air patches
- Patches can include native code changes (unlike EAS Update which is JS-only)
