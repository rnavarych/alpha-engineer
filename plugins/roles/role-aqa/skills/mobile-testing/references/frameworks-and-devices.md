# Mobile Testing Frameworks and Device Strategy

## When to load
When choosing between Appium, Detox, XCUITest, or Espresso; when setting up a device farm (BrowserStack, Sauce Labs, AWS Device Farm); when defining a device coverage matrix.

## Framework Selection

| Framework | Platform | Type | Best For |
|-----------|----------|------|----------|
| **Appium** | iOS + Android | Black-box | Cross-platform, any language |
| **Detox** | iOS + Android | Gray-box | React Native, fast and deterministic |
| **XCUITest** | iOS only | White-box | Native iOS, tight Xcode integration |
| **Espresso** | Android only | White-box | Native Android, synchronization built-in |

## Appium
```javascript
const capabilities = {
  platformName: 'Android',
  'appium:deviceName': 'Pixel 6',
  'appium:app': '/path/to/app.apk',
  'appium:automationName': 'UiAutomator2',
};
```
- Use accessibility IDs for element location. Avoid XPath — slow and brittle.
- Use explicit waits with `driver.waitUntil()`. Pin Appium and driver versions in CI.

## Detox (React Native)
```javascript
it('should login with valid credentials', async () => {
  await element(by.id('email-input')).typeText('user@test.com');
  await element(by.id('password-input')).typeText('password123');
  await element(by.id('login-button')).tap();
  await expect(element(by.id('welcome-screen'))).toBeVisible();
});
```
- Gray-box: synchronizes with app state (animations, network, timers). No artificial waits needed.
- Use `device.reloadReactNative()` between tests for a clean state.

## Native Frameworks
- **XCUITest (iOS)**: Swift tests in Xcode. Use `addUIInterruptionMonitor` for system alerts. Simulators for speed, real devices for final validation.
- **Espresso (Android)**: Auto-syncs with main thread. Use `IdlingResource` for async operations. Test Recorder for scaffolding initial tests.

## Device Farms

| Farm | Strengths |
|------|-----------|
| **BrowserStack** | Cloud real devices, parallel across device/OS combos, video + network logs |
| **Sauce Labs** | Real devices + emulators, Sauce Connect for firewall testing, unified web/mobile reporting |
| **AWS Device Farm** | Physical AWS-hosted devices, CodePipeline integration, pay-per-minute pricing |

## Device Selection Strategy
- Test on top 5-10 devices by market share in your user analytics.
- Always include: latest OS, OS minus one, most popular device model, smallest screen, largest screen.
- Update device matrix quarterly based on analytics and OS release cadence.
