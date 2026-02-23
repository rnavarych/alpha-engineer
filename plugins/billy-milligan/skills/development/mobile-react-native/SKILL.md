---
name: mobile-react-native
description: React Native patterns — Expo, navigation, performance optimization, New Architecture
allowed-tools: Read, Grep, Glob, Bash
---

# Mobile React Native Skill

## Core Principles
- **Expo managed first**: Only eject when a native module is absolutely needed.
- **FlatList not ScrollView**: For lists > 50 items — ScrollView renders all at once.
- **Reanimated on UI thread**: Animations must not trigger the JS bridge.
- **MMKV for storage**: 10x faster than AsyncStorage for non-sensitive data.
- **Zustand for client state**: Redux is overkill for most mobile apps.

## References
- `references/expo-patterns.md` — Managed vs bare, EAS Build, OTA updates, config plugins
- `references/navigation-patterns.md` — Expo Router, deep linking, tab/stack/drawer, auth flows
- `references/performance.md` — FlatList optimization, MMKV, Hermes engine
- `references/new-architecture.md` — Fabric, TurboModules, JSI, migration guide
