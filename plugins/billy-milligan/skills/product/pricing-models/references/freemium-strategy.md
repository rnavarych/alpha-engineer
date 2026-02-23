# Freemium Strategy

## When to load
Load when designing free tier limits, conversion funnels, or upgrade triggers.

## Free Tier Design Principles

```
1. Free must deliver REAL value — not a demo
   → Users must experience the "aha moment" on free
   → If free feels crippled, users leave instead of upgrading

2. Limits should be natural, not artificial
   Good: 3 projects (real resource constraint)
   Bad: watermark on exports (feels punitive)

3. Upgrade trigger = user hits limit doing something valuable
   → "You've used 80% of your free storage" ← natural
   → "Upgrade to remove ads" ← feels like ransom

4. Free tier is a MARKETING CHANNEL, not a product
   → CAC for free users should be near $0
   → Free users generate word-of-mouth and content
```

## Conversion Funnel

```
Free users (100%)
  │
  ├─ Never activate (40-50%) → improve onboarding
  │
  ├─ Active but under limits (30-40%) → these are your marketers
  │
  ├─ Hit limits (10-20%) → upgrade prompt
  │     │
  │     ├─ Upgrade to paid (30-50% of limit-hitters)
  │     │
  │     └─ Stay limited / leave (50-70%)
  │
  └─ Power users who upgrade without hitting limits (5%)
      → Team features, SSO, priority support

Target: 2-5% of free users convert to paid
  (Higher = free tier too limited)
  (Lower = free tier too generous)
```

## Feature Gate Implementation

```typescript
// Feature flags by plan
const PLAN_FEATURES = {
  free: {
    maxProjects: 3,
    maxTeamMembers: 1,
    maxStorage: 500_000_000, // 500MB
    features: ['core', 'basic_export'],
  },
  pro: {
    maxProjects: 50,
    maxTeamMembers: 10,
    maxStorage: 50_000_000_000, // 50GB
    features: ['core', 'basic_export', 'advanced_export', 'api_access', 'integrations'],
  },
  enterprise: {
    maxProjects: Infinity,
    maxTeamMembers: Infinity,
    maxStorage: Infinity,
    features: ['core', 'basic_export', 'advanced_export', 'api_access', 'integrations', 'sso', 'audit_log', 'sla'],
  },
};

// Middleware
function requireFeature(feature: string) {
  return async (req, res, next) => {
    const plan = await getUserPlan(req.userId);
    if (!PLAN_FEATURES[plan].features.includes(feature)) {
      return res.status(403).json({
        error: 'upgrade_required',
        message: `This feature requires a ${getMinimumPlan(feature)} plan`,
        upgradeUrl: '/settings/billing',
      });
    }
    next();
  };
}
```

## Upgrade Triggers

```
Effective triggers (user sees value, wants more):
  ✅ "You've created 3/3 projects — upgrade for unlimited"
  ✅ "Your team has 1/1 seats — add teammates on Pro"
  ✅ "Storage: 450MB/500MB used"
  ✅ "API access requires Pro plan" (after they discover the need)

Ineffective triggers (feels punitive):
  ❌ "Upgrade to remove watermark"
  ❌ "Free trial expired" (after generous trial with no activation)
  ❌ Pop-up every session asking to upgrade
  ❌ Degrading performance on free tier
```

## Anti-patterns
- Too generous free tier → no reason to upgrade (5%+ conversion means too restricted)
- Too restricted free tier → users never experience value, leave
- Feature gating core value → kills activation
- No upgrade prompts → users don't know paid features exist
- Aggressive upgrade nags → users feel harassed, leave

## Quick reference
```
Free tier: deliver real value, limit by quantity not quality
Conversion target: 2-5% free → paid
Upgrade trigger: user hits limit while doing valuable work
Feature gate: 403 with upgrade_url, not silent degradation
Limits: projects, seats, storage, API calls (natural constraints)
Never gate: core value proposition
Monitor: activation rate, limit-hit rate, conversion rate
```
