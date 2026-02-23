# Visual Regression Testing

## When to load
Load when setting up screenshot comparison, visual diffs, or pixel-level UI verification.

## Playwright Visual Comparison

```typescript
// Basic screenshot comparison
test('homepage matches snapshot', async ({ page }) => {
  await page.goto('/');
  await expect(page).toHaveScreenshot('homepage.png', {
    maxDiffPixelRatio: 0.01,  // Allow 1% pixel difference
  });
});

// Element-level screenshot
test('order card renders correctly', async ({ page }) => {
  await page.goto('/orders');
  const card = page.getByTestId('order-card').first();
  await expect(card).toHaveScreenshot('order-card.png', {
    threshold: 0.2,  // Per-pixel color difference threshold
  });
});

// Full page screenshot
test('full page layout', async ({ page }) => {
  await page.goto('/dashboard');
  await expect(page).toHaveScreenshot('dashboard-full.png', {
    fullPage: true,
    mask: [page.getByTestId('timestamp')],  // Mask dynamic content
  });
});
```

## Handling Dynamic Content

```typescript
// Mask elements that change between runs
await expect(page).toHaveScreenshot('page.png', {
  mask: [
    page.getByTestId('current-time'),
    page.getByTestId('avatar'),
    page.locator('.ad-banner'),
  ],
});

// Freeze animations
await page.emulateMedia({ reducedMotion: 'reduce' });

// Wait for fonts and images
await page.waitForLoadState('networkidle');
```

## CI Integration

```yaml
# Update snapshots: npx playwright test --update-snapshots
# Store snapshots in git for review
# Different OS = different rendering → use Docker for consistency
jobs:
  visual-tests:
    runs-on: ubuntu-latest
    container: mcr.microsoft.com/playwright:v1.40.0-jammy
    steps:
      - uses: actions/checkout@v4
      - run: npx playwright test --project=visual
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: visual-diffs
          path: test-results/
```

## Anti-patterns
- Running visual tests on different OS than CI → different font rendering
- No masking of dynamic content → false failures every run
- Screenshot of entire page when only testing a component → noisy diffs
- Threshold too tight (0%) → every anti-aliasing change fails

## Quick reference
```
maxDiffPixelRatio: 0.01 (1%) for page, 0.05 for components
threshold: 0.2 for per-pixel color difference
mask: dynamic elements (timestamps, avatars, ads)
fullPage: true for layout regression
Update: npx playwright test --update-snapshots
CI: use Playwright Docker image for consistent rendering
Store snapshots in git for PR review
```
