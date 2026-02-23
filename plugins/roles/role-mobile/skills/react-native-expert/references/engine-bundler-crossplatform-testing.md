# Hermes, Metro, Cross-Platform Targets & Testing

## When to load
Load when configuring the Hermes engine, tuning Metro bundler settings, targeting web/Windows/macOS/visionOS from a React Native codebase, or setting up unit/integration/E2E testing.

## Hermes Engine

- Hermes is the default JS engine for React Native 0.70+
- AOT compilation to bytecode at build time: faster startup (no JIT compilation cold start)
- Reduced memory footprint vs. JavaScriptCore — better on low-end devices
- Debug with Chrome DevTools via Hermes Inspector or Flipper
- Profile with `HermesInternal.getInstrumentedStats()` for heap statistics
- `hermes-profile-transformer` for converting Hermes CPU profiles to Chrome Timeline format
- Enable explicitly in `app.json`: `"jsEngine": "hermes"` (default in SDK 48+)

## Metro Bundler

- `metro.config.js` for customization: module resolver, transformer, serializer
- Custom resolver for monorepo setups: `resolver.nodeModulesPaths`
- `watchFolders` to include symlinked packages from workspace root
- `assetPlugins` for custom asset transformation (SVG → component, etc.)
- Source maps: `--source-map` flag for production builds
- Bundle splitting: `createModuleIdFactory` for dynamic imports
- `@react-native/metro-config` helper for base configuration

## react-native-screens

- Provides native screen components backed by OS navigation primitives
- `enableScreens()` call in app entry point to activate
- `NativeStackNavigator` from React Navigation uses `react-native-screens` under the hood
- `gestureEnabled`, `stackPresentation`, `stackAnimation` props for native-level control

## Cross-Platform Targets

### React Native for Web
- `react-native-web` package enables web deployment from RN codebase
- Expo Router renders to web natively (Metro + Expo Metro for web)
- Platform-specific code: `Platform.OS === 'web'` or `.web.tsx` file extensions
- Hover, focus, and keyboard navigation via web-specific props and ARIA

### React Native for Windows & macOS
- `react-native-windows` targets UWP (Universal Windows Platform)
- `react-native-macos` (by Microsoft) targets macOS AppKit
- `react-native-test-app` for multi-platform development without separate projects

### React Native for Vision Pro (visionOS)
- `react-native-visionos` enables spatial computing apps
- `ImmersiveSpace`, `WindowGroup`, `VolumeContent` for spatial UI primitives
- `useEvent('onPointerMove')` for spatial input handling

## Performance Checklist

- Enable Hermes and New Architecture (`newArchEnabled=true`)
- Use `React.memo`, `useMemo`, `useCallback` to reduce unnecessary re-renders
- Prefer `FlashList` over `FlatList` for any list with 50+ items
- Avoid inline styles and anonymous functions in render paths
- Use `InteractionManager.runAfterInteractions` for deferred heavy work after navigation
- Profile with Flipper React DevTools, Performance Monitor overlay
- Use `why-did-you-render` library to detect unnecessary re-renders in development
- Image optimization: use `expo-image` with `contentFit`, `transition`, and `blurhash`

## Testing

### Unit & Integration
- Jest with `@testing-library/react-native` for component testing
- `jest-expo` preset for Expo projects — handles module mocking
- Mock native modules: `jest.mock('react-native-mmkv', () => ({...}))`
- `renderHook` from `@testing-library/react-hooks` for hook testing
- Snapshot testing for component regression: `toMatchSnapshot()` or inline snapshots

### E2E Testing
- **Detox**: gray-box testing for React Native — controls device and JS thread simultaneously
  - `detox build` + `detox test` in CI
  - `element(by.id('login-button')).tap()` for interaction
  - `expect(element(by.text('Home'))).toBeVisible()` for assertions
- **Maestro**: YAML-based E2E testing with minimal setup overhead
  - `maestro test flow.yaml` — declarative test flows
  - Supports iOS and Android; runs on device or simulator

### Component Development
- Storybook for React Native: `@storybook/react-native` for component isolation
- `sb-rn-image-placeholder` for image mocking in stories
