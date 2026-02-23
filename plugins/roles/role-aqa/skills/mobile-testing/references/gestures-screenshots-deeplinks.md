# Mobile Gesture Testing, Screenshot Testing, and Deep Link Testing

## When to load
When writing gesture tests (swipe, pinch, long press, scroll); when setting up screenshot baseline comparison for mobile; when testing deep links from cold and warm start.

## Screenshot Testing
- Capture screenshots at key app states and compare against baselines.
- Set pixel-diff thresholds to account for rendering differences across OS versions.
- Store baselines in version control. Review diffs as part of the PR review process.
- Mask dynamic content (user avatars, timestamps, live prices) before comparison.

## Gesture Testing

- **Swipe**: Carousel navigation, list item dismissal (e.g., swipe-to-delete).
- **Pinch/Zoom**: Map interactions, image gallery zoom.
- **Long press**: Context menus, drag-to-reorder initiation.
- **Scroll**: Infinite scroll pagination, pull-to-refresh.
- Verify gesture behavior on both small and large screen sizes.
- Verify behavior in both portrait and landscape orientations.
- Test with both left-handed and right-handed interaction patterns where layout adapts.

## Deep Link Testing
```javascript
await device.openURL({ url: 'myapp://products/123' });
await expect(element(by.id('product-detail'))).toBeVisible();
```

### Scenarios to cover
- **Cold start**: App not running. Deep link launches app and navigates to correct screen.
- **Warm start**: App backgrounded. Deep link resumes app and navigates correctly.
- **Universal links (iOS)** and **App Links (Android)**: Verify HTTP fallback behavior.
- **Invalid deep link**: App handles gracefully — no crash, sensible fallback screen.
- **After update**: Deep link routes still work after app version changes.
- **Fresh install**: Deep link from install referral routes to correct onboarding or content screen.
