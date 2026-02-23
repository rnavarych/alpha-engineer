---
name: react-native-expert
description: Expert guidance on React Native development including New Architecture (Fabric, TurboModules, JSI, Codegen, Bridgeless), Expo SDK 52+ (Expo Router v4, EAS Build/Submit/Update, Expo Modules API), Reanimated 3, Gesture Handler v2, FlashList, MMKV, WatermelonDB, React Native Skia, NativeWind v4, Tamagui, Gluestack UI, Unistyles, Hermes engine, React Navigation 7, React Native for Web/macOS/Windows/Vision Pro, Firebase, Notifee, RevenueCat, Shorebird, and OTA updates. Use when building or optimizing React Native apps.
allowed-tools: Read, Grep, Glob, Bash
---

# React Native Expert

## When to use
- Building or optimizing a React Native or Expo application
- Migrating to New Architecture (JSI, Fabric, TurboModules, Bridgeless)
- Setting up EAS Build, EAS Submit, or OTA update pipelines
- Implementing animations, gestures, or high-performance lists
- Choosing storage, UI framework, or push notification library
- Targeting web, Windows, macOS, or visionOS from a React Native codebase
- Debugging Hermes, Metro bundler, or cross-platform rendering issues

## Core principles
1. **Expo Prebuild is the default** — eject only when prebuild cannot regenerate cleanly
2. **New Architecture first** — TurboModules + Fabric for all new native work
3. **Worklets, not bridge calls** — Reanimated 3 for all animations; never Animated API for complex work
4. **FlashList over FlatList** — any list with 50+ items deserves the Shopify treatment
5. **MMKV, not AsyncStorage** — synchronous, encrypted, 10x faster

## Reference Files

- `references/expo-navigation.md` — Expo managed/bare/prebuild workflows, EAS Build/Submit/Update, Expo Router v4 file-based routing, Expo Modules API, key SDK 52+ packages, React Navigation 7 navigators and advanced patterns
- `references/new-arch-animations.md` — JSI, Fabric, TurboModules, Codegen, Bridgeless mode, New Architecture migration checklist, Reanimated 3 worklets and APIs, Gesture Handler v2 composable gestures, FlashList and FlatList optimization
- `references/storage-ui-media-notifications.md` — MMKV, WatermelonDB, AsyncStorage guidance, NativeWind v4, Tamagui, Gluestack UI v2, Unistyles, React Native Paper, React Native Skia, SVG, Lottie, Notifee, RNFB messaging, RevenueCat, Shorebird
- `references/engine-bundler-crossplatform-testing.md` — Hermes engine configuration and profiling, Metro bundler customization, react-native-screens, React Native for Web/Windows/macOS/visionOS, performance checklist, Jest + RNTL unit tests, Detox and Maestro E2E testing, Storybook
