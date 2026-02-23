# Feature Flags

## LaunchDarkly

```typescript
import * as ld from '@launchdarkly/node-server-sdk';

const client = ld.init(process.env.LAUNCHDARKLY_SDK_KEY!);
await client.waitForInitialization();

async function getFlag(key: string, userId: string, defaultValue: boolean): Promise<boolean> {
  const context: ld.LDContext = {
    kind: 'user',
    key: userId,
    email: user.email,
    custom: { plan: user.plan, region: user.region },
  };
  return client.variation(key, context, defaultValue);
}

// Usage
const useNewCheckout = await getFlag('new-checkout-flow', userId, false);
if (useNewCheckout) {
  return newCheckoutService.process(request);
}
return legacyCheckoutService.process(request);
```

## Unleash (Open Source)

```typescript
import { Unleash } from 'unleash-client';

const unleash = new Unleash({
  url: process.env.UNLEASH_URL!,
  appName: 'order-service',
  customHeaders: { Authorization: process.env.UNLEASH_API_TOKEN! },
});

await unleash.start();

// Simple boolean check
const enabled = unleash.isEnabled('new-checkout-flow', {
  userId,
  properties: { plan: user.plan },
});

// Gradual rollout: 10% -> 25% -> 50% -> 100%
// Configured in Unleash UI with "gradualRollout" strategy
```

## Homegrown Implementation

```typescript
// Simple feature flag for small projects
interface FeatureFlag {
  name: string;
  enabled: boolean;
  rolloutPercentage: number;    // 0-100
  allowedUsers: string[];       // Override list
  enabledEnvironments: string[];
}

const flags: Map<string, FeatureFlag> = new Map();

function isEnabled(flagName: string, userId?: string): boolean {
  const flag = flags.get(flagName);
  if (!flag) return false;

  // Environment check
  if (!flag.enabledEnvironments.includes(process.env.NODE_ENV!)) return false;

  // User override
  if (userId && flag.allowedUsers.includes(userId)) return true;

  // Global toggle
  if (!flag.enabled) return false;

  // Percentage rollout (deterministic by userId)
  if (userId && flag.rolloutPercentage < 100) {
    const hash = hashCode(userId + flagName) % 100;
    return hash < flag.rolloutPercentage;
  }

  return flag.enabled;
}
```

Store flags in: database, Redis, config file, or environment variables. For small teams, a JSON config with hot-reload is sufficient.

## Feature Flag Lifecycle

```
Phase 1: Create flag (disabled)
  - Define flag in system
  - Implement code behind flag (if/else or strategy pattern)
  - Ship code to production (flag off = old behavior)

Phase 2: Gradual rollout
  - Enable for internal users (dogfood)
  - Enable for 1% -> 5% -> 25% -> 50% -> 100%
  - Monitor error rate, latency, business metrics at each step
  - If issues: set to 0% instantly (no deploy needed)

Phase 3: Full rollout
  - Flag at 100% for 2+ weeks
  - No issues reported

Phase 4: Cleanup (CRITICAL)
  - Remove flag check from code
  - Remove old code path
  - Delete flag from system
  - PR title: "chore: remove feature flag new-checkout-flow"
```

## Cleanup Strategy

```
Flag age tracking:
  > 30 days at 100%: cleanup candidate
  > 90 days at 100%: mandatory cleanup (create ticket)
  > 180 days: escalate to tech lead

Automation:
  # Lint rule: flag age check
  # CI job: report flags older than 90 days
  # Dashboard: flag inventory with age and status

Anti-pattern: "temporary" flags that live for years
  Result: code full of dead branches, impossible to reason about behavior
  Fix: treat flag cleanup as part of the feature work, not a separate task
```

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Flag in code but never cleaned up | Set cleanup deadline at creation time |
| Nested flag dependencies | Keep flags independent; one flag per feature |
| Flag checked in tight loop | Cache flag value per request, not per check |
| No monitoring on flagged code paths | Add metrics to both old and new code paths |
| Using flags for config | Flags are boolean toggles; use config service for values |

## Quick Reference

- Rollout ramp: **1% -> 5% -> 25% -> 50% -> 100%**
- Kill switch: set to **0%** instantly (no deploy)
- Cleanup deadline: **90 days** after 100% rollout
- Flag naming: `kebab-case`, descriptive (e.g., `new-checkout-flow`)
- LaunchDarkly: managed SaaS, rich targeting, $$$
- Unleash: open-source, self-hosted, feature-rich
- Homegrown: simple, no dependency, limited targeting
