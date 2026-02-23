# Consent Management

## When to load
Load when implementing consent collection, withdrawal, granularity, or audit trails.

## Consent Requirements (GDPR Art. 7)

```
Valid consent must be:
  1. Freely given — no bundling with service, no penalty for refusal
  2. Specific — separate consent per purpose (marketing ≠ analytics)
  3. Informed — clear explanation of what data, why, who processes
  4. Unambiguous — affirmative action (no pre-ticked boxes)
  5. Withdrawable — as easy to withdraw as to give
```

## Implementation

```typescript
// Consent preferences model
interface ConsentRecord {
  userId: string;
  purpose: 'marketing_email' | 'analytics' | 'third_party_sharing';
  granted: boolean;
  grantedAt: Date | null;
  withdrawnAt: Date | null;
  source: 'signup_form' | 'settings_page' | 'cookie_banner';
  ipAddress: string;       // Record for audit
  userAgent: string;       // Record for audit
  version: string;         // Privacy policy version consented to
}

// Grant consent
async function grantConsent(userId: string, purpose: string, context: RequestContext) {
  await db.consents.upsert({
    where: { userId_purpose: { userId, purpose } },
    create: {
      userId, purpose,
      granted: true,
      grantedAt: new Date(),
      source: context.source,
      ipAddress: context.ip,
      userAgent: context.userAgent,
      version: CURRENT_PRIVACY_POLICY_VERSION,
    },
    update: {
      granted: true,
      grantedAt: new Date(),
      withdrawnAt: null,
      version: CURRENT_PRIVACY_POLICY_VERSION,
    },
  });
}

// Withdraw consent — must be as easy as granting
async function withdrawConsent(userId: string, purpose: string) {
  await db.consents.update({
    where: { userId_purpose: { userId, purpose } },
    data: { granted: false, withdrawnAt: new Date() },
  });

  // Immediate effect: stop processing
  if (purpose === 'marketing_email') {
    await emailService.unsubscribe(userId);
  }
}
```

## Cookie Consent Banner

```
Minimum categories:
  1. Strictly Necessary — no consent needed, always on
  2. Analytics — requires consent
  3. Marketing — requires consent
  4. Third-party — requires consent

Implementation:
  - Show banner on first visit
  - Default: all optional categories OFF
  - "Accept All" and "Reject All" equally prominent
  - Granular settings accessible
  - Store preference in cookie + server-side
  - Re-consent when privacy policy changes
```

## Anti-patterns
- Pre-ticked consent boxes → invalid consent under GDPR
- "Accept All" button prominent, "Reject" hidden → not freely given
- No audit trail → can't prove consent was given
- Bundled consent ("agree to everything") → must be purpose-specific

## Quick reference
```
Valid: freely given, specific, informed, unambiguous, withdrawable
Granularity: separate consent per purpose
Audit: store who, when, what, where, which policy version
Withdrawal: must be as easy as granting — one click
Cookie categories: necessary (no consent) + analytics + marketing
Re-consent: when privacy policy or processing changes
Children: age verification required (16 in EU, varies by country)
```
