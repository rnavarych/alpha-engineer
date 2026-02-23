# Event Tracking

## When to load
Load when designing event taxonomy, naming conventions, or analytics instrumentation.

## Event Naming Convention

```
Format: object_action

Examples:
  page_viewed
  button_clicked
  signup_started
  signup_completed
  order_placed
  order_cancelled
  subscription_upgraded
  feature_used

Rules:
  1. past tense (completed, not complete)
  2. snake_case (not camelCase)
  3. object first (order_placed, not placed_order)
  4. max 3 words (feature_flag_evaluated, not user_clicked_the_submit_button)
  5. consistent vocabulary (use "started/completed" not "began/finished")
```

## Event Properties

```typescript
// Every event should have these base properties
interface BaseEvent {
  event: string;
  timestamp: string;           // ISO 8601
  userId?: string;             // Null for anonymous
  anonymousId: string;         // Device/session ID
  properties: {
    page_url: string;
    page_title: string;
    referrer?: string;
    utm_source?: string;
    utm_medium?: string;
    utm_campaign?: string;
  };
}

// Specific event example
analytics.track('order_placed', {
  order_id: 'ord_123',
  total_cents: 4999,
  currency: 'USD',
  item_count: 3,
  payment_method: 'card',
  coupon_code: 'SAVE10',
  is_first_order: true,
});
```

## Implementation (PostHog / Segment)

```typescript
// PostHog
import posthog from 'posthog-js';

posthog.init('phc_xxx', { api_host: 'https://ph.yoursite.com' });

// Identify user
posthog.identify(userId, { email, plan, created_at });

// Track event
posthog.capture('feature_used', { feature: 'export', format: 'csv' });

// Group (for B2B: associate user with company)
posthog.group('company', companyId, { name: 'Acme Inc', plan: 'enterprise' });
```

```typescript
// Segment (if using multi-tool analytics)
import Analytics from '@segment/analytics-node';
const analytics = new Analytics({ writeKey: 'xxx' });

analytics.identify({ userId, traits: { email, plan } });
analytics.track({ userId, event: 'order_placed', properties: { total: 4999 } });
```

## Event Taxonomy Template

```
Lifecycle:
  signup_started, signup_completed, onboarding_completed
  login_succeeded, login_failed, logout_completed
  account_deleted

Core Actions:
  [object]_created, [object]_updated, [object]_deleted
  [object]_viewed, [object]_shared, [object]_exported

Conversion:
  trial_started, subscription_created, subscription_upgraded
  subscription_cancelled, subscription_renewed
  payment_succeeded, payment_failed

Engagement:
  feature_used (with feature property)
  search_performed, filter_applied
  notification_clicked, email_opened
```

## Anti-patterns
- Tracking everything → noise drowns signal, storage costs explode
- Inconsistent naming → "click_signup" and "signup_clicked" both exist
- PII in event properties → GDPR violation
- No event schema documentation → nobody knows what events mean

## Quick reference
```
Format: object_action (past tense, snake_case)
Base properties: userId, anonymousId, timestamp, page_url
Identify: call once per session with user traits
Group: for B2B, associate users with companies
Track lifecycle: signup, activation, retention, revenue events
No PII: email/name in identify(), not in track()
Document: maintain event taxonomy spreadsheet
Review: quarterly cleanup of unused events
```
