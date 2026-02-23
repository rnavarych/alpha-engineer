# Expo Patterns

## Managed vs Bare Workflow

```
Managed Workflow (recommended):
  - No Xcode/Android Studio needed for most development
  - EAS Build handles native compilation in the cloud
  - OTA updates via EAS Update — push JS changes without app store review
  - Config plugins for native modifications without ejecting
  - Use when: 95% of apps — unless you need custom native modules

Bare Workflow:
  - Full access to ios/ and android/ directories
  - Custom native modules in Objective-C/Swift/Java/Kotlin
  - Use when: custom native SDK integration, Bluetooth LE, custom video codecs
  - Can still use most Expo packages via expo-modules
```

## Project Setup

```bash
# Create new Expo project with tabs template
npx create-expo-app@latest myapp --template tabs

# Project structure
app/
  (tabs)/
    _layout.tsx          # Tab navigator
    index.tsx            # Home tab
    explore.tsx          # Explore tab
  _layout.tsx            # Root layout (fonts, theme, auth)
  +not-found.tsx         # 404 screen
  modal.tsx              # Modal screen
components/
  ui/
    ThemedText.tsx
    ThemedView.tsx
constants/
  Colors.ts
assets/
  fonts/
  images/
app.json                 # Expo configuration
```

## EAS Build

```bash
# Install EAS CLI
npm install -g eas-cli

# Configure builds
eas build:configure

# Build for iOS (production)
eas build --platform ios --profile production

# Build for Android (preview — APK for testing)
eas build --platform android --profile preview

# Submit to app stores
eas submit --platform ios
eas submit --platform android
```

```json
// eas.json — build profiles
{
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal"
    },
    "preview": {
      "android": { "buildType": "apk" },
      "ios": { "simulator": true }
    },
    "production": {
      "autoIncrement": true
    }
  }
}
```

## OTA Updates

```bash
# Push JS-only updates without app store review
eas update --branch production --message "Fix order display bug"

# Channel-based rollout
eas update --branch staging --message "New feature: order tracking"

# Roll back to previous update
eas update:rollback --branch production
```

```typescript
// app.json — configure updates
{
  "expo": {
    "updates": {
      "url": "https://u.expo.dev/your-project-id",
      "fallbackToCacheTimeout": 5000,
      "checkAutomatically": "ON_LOAD"
    },
    "runtimeVersion": {
      "policy": "appVersion"  // New native code = new runtime version
    }
  }
}
```

## Config Plugins

```typescript
// plugins/withCustomSplashScreen.ts — modify native config without ejecting
import { ConfigPlugin, withAndroidManifest } from 'expo/config-plugins';

const withCustomPermission: ConfigPlugin = (config) => {
  return withAndroidManifest(config, (config) => {
    const manifest = config.modResults.manifest;
    // Add custom Android permission
    manifest['uses-permission'] = manifest['uses-permission'] || [];
    manifest['uses-permission'].push({
      $: { 'android:name': 'android.permission.VIBRATE' },
    });
    return config;
  });
};

export default withCustomPermission;
```

```json
// app.json — apply config plugin
{
  "expo": {
    "plugins": [
      ["expo-camera", { "cameraPermission": "Allow camera for scanning" }],
      "./plugins/withCustomPermission"
    ]
  }
}
```

## Anti-Patterns
- Ejecting for a simple native config — use config plugins instead
- Building locally without EAS — inconsistent environments
- OTA update with native code changes — crash on users' devices
- Not setting `runtimeVersion` — OTA update targets wrong native version

## Quick Reference
```
Managed workflow: default, covers 95% of use cases
EAS Build: cloud builds, no local Xcode/AS needed
EAS Update: OTA for JS-only changes (no app store review)
Config plugins: modify native config without ejecting
Profiles: development (dev client), preview (testing), production (store)
Runtime version: new native code = new runtime version (OTA safety)
Expo Router: file-based routing (like Next.js App Router)
```
