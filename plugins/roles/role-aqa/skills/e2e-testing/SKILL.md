---
name: role-aqa:e2e-testing
description: |
  End-to-end test automation with Playwright (codegen, trace viewer, MCP, sharding,
  visual comparisons, fixtures, component testing), Cypress v13, Selenium 4 (BiDi),
  WebdriverIO, TestCafe, Robot Framework. Visual regression: Percy, Chromatic, Applitools,
  BackstopJS, Lost Pixel. Cross-browser: BrowserStack, Sauce Labs. Accessibility in E2E.
allowed-tools: Read, Grep, Glob, Bash
---

# E2E Testing

## When to use
- Setting up or extending an E2E test suite (Playwright, Cypress, Selenium, WebdriverIO)
- Writing reliable locators, fixtures, or multi-browser project configs in Playwright
- Adding visual regression testing (Percy, Chromatic, Applitools, BackstopJS)
- Running cross-browser tests on BrowserStack, Sauce Labs, or LambdaTest
- Adding accessibility checks (axe) to existing E2E flows
- Debugging or quarantining flaky tests
- Choosing a framework for a team that includes non-developer testers

## Core principles
1. **Auto-wait over sleep** — Playwright's auto-wait eliminates race conditions; any `sleep()` in tests is a bug waiting to happen
2. **Locator hierarchy matters** — role > label > placeholder > text > testId > CSS; resilience decreases from left to right
3. **Fixtures own setup and teardown** — create data via API before tests, clean up after; never rely on pre-existing state
4. **Flaky = broken** — a test with >2% unreliable failure rate is a broken test; quarantine and fix, never retry into silence
5. **Visual tests need masking** — dynamic content (prices, timestamps, avatars) must be masked before snapshotting or diffs are noise

## Reference Files
- `references/playwright-core.md` — auto-wait, locator hierarchy, fixtures, test.step, multi-browser projects, sharding, API testing, component testing, visual comparisons, MCP integration
- `references/cypress-selenium-alternatives.md` — Cypress v13 (session, intercept, component testing, multi-origin), Selenium 4 (BiDi, relative locators, CDP, Grid), WebdriverIO, TestCafe, Robot Framework, CodeceptJS
- `references/visual-regression-cloud-testing.md` — Percy, Chromatic, Applitools, BackstopJS, Lost Pixel, reg-suit; visual testing best practices; BrowserStack, Sauce Labs, LambdaTest setup
- `references/pom-accessibility-flaky-tests.md` — Page Object Model with TypeScript, playwright-axe and cypress-axe integration, WCAG assertions, flaky test detection and quarantine workflow, test data patterns
