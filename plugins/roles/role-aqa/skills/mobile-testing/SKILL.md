---
name: mobile-testing
description: |
  Mobile test automation with Appium (cross-platform), Detox (React Native gray-box),
  XCUITest (iOS native), Espresso (Android native), device farms (BrowserStack,
  Sauce Labs, AWS Device Farm), screenshot testing, gesture testing, and deep link testing.
  Use when automating mobile app tests or setting up mobile test infrastructure.
allowed-tools: Read, Grep, Glob, Bash
---

# Mobile Testing

## When to use
- Choosing a mobile automation framework for a new project (Appium vs Detox vs native)
- Setting up a cloud device farm (BrowserStack, Sauce Labs, AWS Device Farm)
- Defining a device coverage matrix based on user analytics
- Writing gesture tests (swipe, pinch, long press, scroll) across screen sizes
- Testing deep links from cold start, warm start, and fresh install scenarios
- Setting up screenshot baseline testing for visual regression on mobile

## Core principles
1. **Gray-box beats black-box for React Native** — Detox synchronizes with app state; Appium polls; Detox wins on reliability
2. **Accessibility IDs over XPath** — XPath in Appium is the slowest locator strategy and breaks on layout changes
3. **Real devices for release validation, emulators for fast iteration** — emulators catch 80% of bugs at 10x speed
4. **Device matrix must reflect actual user analytics** — testing on devices nobody uses is wasted CI budget
5. **Deep links need cold start and warm start** — apps that only work warm are broken in half the entry scenarios

## Reference Files
- `references/frameworks-and-devices.md` — framework selection table, Appium capabilities setup, Detox gray-box pattern, XCUITest and Espresso notes, device farm comparison, device selection strategy
- `references/gestures-screenshots-deeplinks.md` — screenshot baseline testing, gesture scenarios (swipe/pinch/long press/scroll), deep link testing checklist covering cold start, warm start, universal links, and edge cases
