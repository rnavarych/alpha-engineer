---
name: compliance-gdpr
description: |
  GDPR compliance implementation: Subject Access Requests (30-day), right to erasure,
  consent management, data retention policies, 72-hour breach notification, lawful basis,
  PII detection, data minimization. PostgreSQL RLS for data isolation.
  Use when implementing GDPR features, data subject rights, consent flows, breach response.
allowed-tools: Read, Grep, Glob
---

# GDPR Compliance Implementation

## When to Use This Skill
- Implementing Subject Access Requests (SAR) and right to erasure
- Designing consent management systems
- Setting up data retention and automatic deletion
- Planning 72-hour breach notification workflow
- Choosing lawful basis for data processing

## Core Principles

1. **Privacy by design** — build privacy in from the start; retrofitting is 10× harder
2. **Data minimization** — collect only what you need for the stated purpose
3. **72 hours for breach notification** — to supervisory authority; 30 days for SAR response
4. **Consent must be specific and withdrawable** — "I agree to terms" does not cover marketing emails
5. **Document the lawful basis** — legitimate interest requires a balancing test; consent is not always the right choice

---

## Patterns ✅

### Subject Access Request (SAR) Implementation

```typescript
// SAR: must respond within 30 days
// Must provide: all personal data held, processing purposes, retention periods, recipients

export class SarService {
  async generateSarReport(userId: string): Promise<SarReport> {
    // Collect PII from all sources in parallel
    const [profile, orders, payments, analytics, consents, auditLog] = await Promise.all([
      this.db.query.users.findFirst({
        where: eq(users.id, userId),
        columns: { id: true, email: true, name: true, createdAt: true, phone: true },
      }),
      this.db.query.orders.findMany({
        where: eq(orders.userId, userId),
        columns: { id: true, createdAt: true, total: true, status: true, shippingAddress: true },
      }),
      this.paymentService.getPaymentHistory(userId),   // External — tokenized cards only
      this.analyticsService.getUserEvents(userId),      // Behavioral data
      this.consentService.getConsentHistory(userId),    // Consent audit trail
      this.auditService.getUserActions(userId),         // What did they do
    ]);

    return {
      generatedAt: new Date(),
      subject: { id: userId, email: profile?.email },
      data: {
        profile,
        orders,
        payments,      // Masked card numbers only: **** **** **** 4242
        analytics,
        consents,
        auditLog,
      },
      processingPurposes: this.getProcessingPurposes(),
      retentionPeriods: this.getRetentionSchedule(),
      dataRecipients: this.getThirdPartyRecipients(),
      rights: ['access', 'rectification', 'erasure', 'portability', 'objection'],
    };
  }
}
```

### Right to Erasure (Right to Be Forgotten)

```typescript
// Erasure: anonymize or delete all PII
// Exception: data required by law (financial records: 7 years), fraud prevention

export class ErasureService {
  async processErasureRequest(userId: string): Promise<ErasureReport> {
    const report: ErasureReport = {
      requestedAt: new Date(),
      userId,
      actions: [],
    };

    await this.db.transaction(async (tx) => {
      // 1. Anonymize user profile (don't delete — foreign key references)
      await tx.update(users)
        .set({
          email: `deleted_${userId}@anon.invalid`,
          name: 'Deleted User',
          phone: null,
          addressLine1: null,
          addressLine2: null,
          dateOfBirth: null,
          deletedAt: new Date(),
          erasedAt: new Date(),
        })
        .where(eq(users.id, userId));
      report.actions.push({ entity: 'user_profile', action: 'anonymized' });

      // 2. Anonymize orders (keep for financial compliance — anonymize PII)
      await tx.update(orders)
        .set({ shippingAddress: null, billingAddress: null })
        .where(eq(orders.userId, userId));
      report.actions.push({ entity: 'orders', action: 'pii_removed', retainedFor: 'financial_compliance_7y' });

      // 3. Delete marketing data (no legal basis to retain)
      await tx.delete(marketingProfiles).where(eq(marketingProfiles.userId, userId));
      report.actions.push({ entity: 'marketing_profile', action: 'deleted' });

      // 4. Delete analytics (no legal basis after consent withdrawn)
      await tx.delete(analyticsEvents).where(eq(analyticsEvents.userId, userId));
      report.actions.push({ entity: 'analytics_events', action: 'deleted' });

      // 5. Revoke all sessions
      await tx.delete(sessions).where(eq(sessions.userId, userId));
      report.actions.push({ entity: 'sessions', action: 'deleted' });

      // 6. Delete from external processors (async)
      await tx.insert(erasureQueue).values({
        userId,
        processors: ['mailchimp', 'intercom', 'segment'],
        status: 'pending',
      });
    });

    return report;
  }
}
```

### Consent Management

```typescript
// Consent must be: specific, informed, unambiguous, freely given, withdrawable

export type ConsentPurpose =
  | 'marketing_email'
  | 'marketing_sms'
  | 'analytics_tracking'
  | 'personalization'
  | 'third_party_sharing';

export class ConsentService {
  // Grant consent — record immutably
  async grant(userId: string, purpose: ConsentPurpose, metadata: ConsentMetadata): Promise<void> {
    await this.db.insert(consentRecords).values({
      userId,
      purpose,
      status: 'granted',
      grantedAt: new Date(),
      ipAddress: metadata.ipAddress,
      userAgent: metadata.userAgent,
      // Capture the consent text shown — for audit trail
      consentTextVersion: metadata.consentTextVersion,
      consentTextHash: metadata.consentTextHash,
    });
  }

  // Withdraw consent — record immutably (don't update the grant record)
  async withdraw(userId: string, purpose: ConsentPurpose): Promise<void> {
    await this.db.insert(consentRecords).values({
      userId,
      purpose,
      status: 'withdrawn',
      withdrawnAt: new Date(),
    });

    // Trigger downstream cleanup
    if (purpose === 'analytics_tracking') {
      await this.analyticsService.deleteUserData(userId);
    }
    if (purpose === 'marketing_email') {
      await this.emailService.unsubscribe(userId);
    }
  }

  // Check current consent (latest record wins)
  async hasConsent(userId: string, purpose: ConsentPurpose): Promise<boolean> {
    const latest = await this.db.query.consentRecords.findFirst({
      where: and(
        eq(consentRecords.userId, userId),
        eq(consentRecords.purpose, purpose),
      ),
      orderBy: desc(consentRecords.createdAt),
    });
    return latest?.status === 'granted';
  }
}
```

### Data Retention with Automatic Deletion

```sql
-- Retention schedule table
CREATE TABLE data_retention_policies (
  entity       TEXT PRIMARY KEY,
  retain_days  INT NOT NULL,
  lawful_basis TEXT NOT NULL,  -- 'contract', 'legal_obligation', 'consent', 'legitimate_interest'
  notes        TEXT
);

INSERT INTO data_retention_policies VALUES
  ('orders',           2557, 'legal_obligation', '7 years financial records'),
  ('payment_records',  2557, 'legal_obligation', '7 years financial records'),
  ('audit_logs',       365,  'legitimate_interest', 'fraud prevention'),
  ('analytics_events', 90,   'consent', 'deleted when consent withdrawn'),
  ('sessions',         30,   'contract', 'active session validity'),
  ('marketing_events', 365,  'consent', 'deleted when consent withdrawn');

-- Automated deletion job (run daily via pg_cron or application scheduler)
-- Example: delete analytics events older than 90 days
DELETE FROM analytics_events
WHERE created_at < NOW() - INTERVAL '90 days';

-- Anonymize old orders (keep for compliance, remove PII)
UPDATE orders
SET shipping_address = NULL,
    billing_address = NULL,
    customer_name = 'Anonymized'
WHERE created_at < NOW() - INTERVAL '7 years'
  AND anonymized_at IS NULL;
```

### 72-Hour Breach Notification Workflow

```typescript
// GDPR Art 33: notify supervisory authority within 72 hours of awareness
// Art 34: notify affected individuals "without undue delay" if high risk

export class BreachNotificationService {
  async recordBreach(breach: BreachReport): Promise<void> {
    const record = await this.db.insert(dataBreaches).values({
      id: generateId(),
      discoveredAt: breach.discoveredAt,
      notificationDeadline: addHours(breach.discoveredAt, 72),
      affectedUsers: breach.affectedUserCount,
      dataCategories: breach.dataCategories,  // e.g., ['email', 'hashed_password']
      severity: breach.severity,              // 'low' | 'medium' | 'high'
      description: breach.description,
      status: 'discovered',
    }).returning();

    // Alert DPO and legal immediately
    await this.alertService.sendUrgent({
      to: [process.env.DPO_EMAIL!, process.env.LEGAL_EMAIL!],
      subject: `GDPR DATA BREACH - 72hr notification required by ${record[0].notificationDeadline}`,
      body: this.formatBreachAlert(record[0]),
    });

    // Schedule reminder at 48h (24h before deadline)
    await this.scheduler.schedule({
      at: addHours(breach.discoveredAt, 48),
      job: 'breach_notification_reminder',
      payload: { breachId: record[0].id },
    });
  }
}
```

---

## Anti-Patterns ❌

### Bundled Consent
**What it is**: Single "I agree to all terms" checkbox covering analytics, marketing, profiling.
**GDPR violation**: Art 7(2) — consent must be specific; bundled consent is not valid.
**Fix**: Separate checkboxes per purpose. Marketing email ≠ analytics ≠ third-party sharing.

### Deleting Instead of Anonymizing for Financial Records
**What it is**: Deleting entire order records to fulfill erasure requests.
**What breaks**: Financial records must be retained 7 years (legal obligation in most jurisdictions). Deleting them violates financial regulations.
**Fix**: Anonymize the PII fields (name, address) in orders, retain the financial record. Document the lawful basis: legal obligation overrides erasure right.

### No Audit Trail for Consent
**What it is**: Updating a boolean `marketing_opt_in` flag. No history.
**What breaks**: Cannot prove what consent text the user saw when they agreed. Cannot demonstrate compliance in a supervisory audit.
**Fix**: Immutable consent log — each grant/withdrawal is a new record with timestamp, consent text version, IP address.

---

## Quick Reference

```
SAR response deadline: 30 days (extendable to 90 days for complex cases)
Breach notification to authority: 72 hours from awareness
Individual notification: "without undue delay" for high-risk breaches
Financial records retention: 7 years (legal obligation)
Session/marketing data: delete when consent withdrawn
Consent requirements: specific, informed, unambiguous, freely given, withdrawable
Lawful bases: consent, contract, legal obligation, vital interests, public task, legitimate interests
Right to erasure exceptions: legal obligation, public interest, legal claims
```
