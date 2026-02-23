# Expo SDK, EAS & React Navigation

## When to load
Load when working with Expo managed/bare/prebuild workflows, EAS Build/Submit/Update pipelines, Expo Router v4 file-based routing, or React Navigation 7 configuration.

## Expo vs Bare Workflow

### Choose Expo (Managed) When
- Rapid prototyping or MVP development
- No custom native modules required beyond the Expo SDK ecosystem
- OTA updates are important (EAS Update / Expo Updates)
- Team has limited native iOS/Android experience
- Standard device APIs suffice (camera, location, notifications, sensors)

### Choose Bare Workflow When
- Custom native modules are required (Bluetooth, ARKit, proprietary SDKs)
- Fine-grained native build control is needed (custom build phases, Gradle tasks)
- Existing native codebase integration
- App requires specific native library versions not supported by Expo SDK

### Expo Prebuild (Recommended Hybrid)
- Use `expo prebuild` for config-based native project generation
- Manage native config via `app.json` / `app.config.ts` Config Plugins
- Eject only when absolutely necessary — prebuild regenerates cleanly
- Use Expo Modules API for custom native modules with Swift/Kotlin

## Expo SDK 52+

### Expo Router v4
- File-based routing convention — all routes live in the `app/` directory
- Layout files `_layout.tsx` define shared navigation shell (tabs, stacks, drawers)
- Dynamic routes with `[param].tsx`, optional catch-all `[[...rest]].tsx`
- API routes: `app/api/endpoint+api.ts` for lightweight server endpoints at build time
- Typed routes: fully typed `href` navigation with `expo-router/build/types` (enable in `app.json`)
- `<Link>` component for declarative navigation with `asChild` for custom pressables
- `useRouter()` hook for imperative navigation: `push`, `replace`, `back`, `navigate`
- `useLocalSearchParams()` and `useGlobalSearchParams()` for typed param access
- Nested layouts for complex app structures (auth flow, onboarding, modals)
- Error boundaries via `+error.tsx` files co-located with route segments
- Loading states with `+not-found.tsx` for 404 handling

### EAS Build
- `eas.json` profiles: `development` (Expo Dev Client), `preview` (internal distribution), `production` (store)
- `eas build --profile production --platform all` for simultaneous iOS + Android builds
- Build credentials managed automatically: `eas credentials` for manual inspection
- Custom build steps via `eas-build-pre-install` and `eas-build-post-install` hooks
- Environment variables: `.env` files, `eas.json` `env` block, and EAS Secrets for sensitive values
- Internal distribution: `eas build --profile preview` generates shareable install links

### EAS Submit
- `eas submit -p ios` — automated App Store Connect submission via App Store Connect API Key
- `eas submit -p android` — automated Google Play submission via Google Service Account JSON
- `eas submit --latest` to submit the most recent EAS build without re-specifying build ID

### EAS Update (OTA)
- `eas update --branch production --message "Fix login crash"` for JavaScript-only OTA updates
- Branch-based update strategy: `main` → production, `staging` → preview
- Rollback to previous update with `eas update:rollback`
- `fingerprint` runtime policy recommended — hashes native layer to ensure update compatibility

### Expo Modules API
- Swift (iOS) and Kotlin (Android) first-class API for writing native modules
- `expo-modules-core` provides `Module`, `Function`, `AsyncFunction`, `View` primitives
- Type-safe JS/TS interface generated from Swift/Kotlin declarations
- `sendEvent(name, body)` for native-to-JS event emission

### Key Expo Packages (SDK 52+)
- **expo-image**: performant image component with blurhash placeholders, transitions, priority loading
- **expo-camera**: camera view with barcode scanning, face detection, photo/video capture
- **expo-notifications**: local and push notifications with rich media, actions, and scheduling
- **expo-sqlite**: SQLite database with transactions and reactive queries (SDK 50+)
- **expo-secure-store**: encrypted key-value storage backed by Keychain/EncryptedSharedPreferences

## React Navigation 7

### Core Concepts
- `NavigationContainer` at app root wraps all navigators
- `useNavigation()` hook for imperative navigation from any nested component
- Type navigation params with TypeScript: `NativeStackScreenProps<RootParamList, 'ScreenName'>`
- `@react-navigation/native-stack` for native OS navigation — preferred for performance

### Navigators
- **NativeStack**: uses `UINavigationController` (iOS) / Fragment back stack (Android)
- **Tab**: `@react-navigation/bottom-tabs` with `tabBarIcon`, badge counts, `tabBarStyle`
- **Drawer**: `@react-navigation/drawer` — requires gesture-handler and reanimated
- **Material Top Tabs**: `@react-navigation/material-top-tabs`

### Advanced Patterns
- Deep linking with `linking` config and Universal Links (iOS) / App Links (Android)
- `useFocusEffect` for screen-lifecycle side effects — runs on focus, cleans up on blur
- `NavigationContainer.onStateChange` for analytics screen tracking
- Type-safe navigation with `createNativeStackNavigator<ParamList>()`
