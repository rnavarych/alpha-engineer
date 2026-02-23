# Visual Regression Testing and Cloud Cross-Browser Testing

## When to load
When setting up Percy, Chromatic, Applitools, BackstopJS, Lost Pixel, or reg-suit; when configuring BrowserStack, Sauce Labs, or LambdaTest for cross-browser runs; when defining visual testing best practices.

## Percy (BrowserStack)
- Cloud-based visual review with multi-browser rendering.
- `percy exec -- npx playwright test` captures snapshots automatically.
- Review and approve/reject diffs in pull request comments.
- Renders at multiple resolutions (responsive breakpoints).

## Chromatic (Storybook)
- Component-level visual testing integrated with Storybook.
- `npx chromatic --project-token=<token>` publishes stories and catches visual changes.
- Isolates visual regressions to specific component states.

## Applitools Eyes
- AI-powered visual comparison ignores rendering differences (anti-aliasing, sub-pixel fonts).
- Ultra-fast grid: render in 50+ browser/device combos simultaneously.
- Best for complex UIs with dynamic content regions.

```typescript
import { BatchInfo, Configuration, EyesRunner, Eyes } from '@applitools/eyes-playwright';

const eyes = new Eyes(runner, config);
await eyes.open(page, 'App Name', 'Test Name');
await eyes.checkWindow('Product Page');
await eyes.close();
```

## BackstopJS
- Local visual regression testing with Docker rendering.
- Configuration in JSON. Captures and diffs screenshots.
- Good for projects avoiding cloud dependencies or vendor lock-in.

```json
{
  "scenarios": [{
    "label": "Homepage",
    "url": "http://localhost:3000",
    "hideSelectors": [".dynamic-price", ".timestamp"],
    "misMatchThreshold": 0.5
  }]
}
```

## Lost Pixel
- Open-source visual regression. Integrates with Storybook, Ladle, Histoire, and full pages.
- Stores baselines in S3 or local filesystem.

## reg-suit
- Visual regression testing toolkit.
- Connects to S3 for baseline storage, reports diffs in GitHub PR comments.
- Framework-agnostic: works with any screenshot tool.

## Visual Testing Best Practices
- Mask dynamic content (timestamps, prices, user avatars) before snapshotting.
- Set pixel diff thresholds to account for anti-aliasing across OS/GPU rendering differences.
- Disable CSS animations during visual tests (`animations: 'disabled'` in Playwright).
- Run visual tests in a consistent, headless Docker environment.
- Review all diffs before approving new baselines. Do not auto-approve via CI.
- Separate visual regression job from functional tests. Run on schedule or design-related PRs.

## Cross-Browser Testing (Cloud)

### BrowserStack Automate
- Real devices and browsers in the cloud.
- Parallel execution across hundreds of device/OS/browser combos.
- Video recording, network logs, visual logs for every test run.
- BrowserStack Local for testing behind firewalls.

### Sauce Labs
- Real devices and emulators/simulators.
- Sauce Connect Proxy for internal application testing.
- Unified reporting across web and mobile.

### LambdaTest
- Cloud browser testing with HyperExecute for faster parallel execution.
- Smart Test Orchestration for optimal test distribution.
- Real-time testing and automated testing support.
