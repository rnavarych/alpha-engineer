# DSAR Procedures

## When to load
Load when handling Data Subject Access Requests: right of access, erasure, portability.

## Rights & Timelines

```
Right of Access (Art. 15): provide all personal data — 30 days
Right to Rectification (Art. 16): correct inaccurate data — 30 days
Right to Erasure (Art. 17): delete personal data — 30 days
Right to Portability (Art. 20): export in machine-readable format — 30 days
Right to Restriction (Art. 18): stop processing, keep data — 30 days
Right to Object (Art. 21): stop specific processing — without delay

Extension: additional 2 months for complex requests (must notify within 30 days)
```

## Right to Erasure Implementation

```typescript
async function handleErasureRequest(userId: string) {
  // 1. Verify identity (prevent unauthorized deletion)
  await verifyIdentity(userId);

  // 2. Check for legal retention obligations
  const retentionHolds = await checkRetentionObligations(userId);
  // Tax invoices: must retain 7 years (legal obligation overrides erasure)

  // 3. Delete or anonymize
  await db.$transaction(async (tx) => {
    // Hard delete: data with no retention requirement
    await tx.userProfiles.delete({ where: { userId } });
    await tx.consents.deleteMany({ where: { userId } });
    await tx.sessions.deleteMany({ where: { userId } });

    // Anonymize: data with retention requirement
    await tx.invoices.updateMany({
      where: { userId },
      data: {
        customerName: 'DELETED',
        customerEmail: 'deleted@anonymized.invalid',
        // Keep: amount, date, tax ID (legal requirement)
      },
    });

    // Anonymize: analytics data
    await tx.events.updateMany({
      where: { userId },
      data: { userId: null, ipAddress: null },
    });

    // Mark account as deleted
    await tx.users.update({
      where: { id: userId },
      data: {
        email: `deleted-${userId}@anonymized.invalid`,
        name: 'Deleted User',
        deletedAt: new Date(),
      },
    });
  });

  // 4. Notify third-party processors
  await notifyProcessors(userId, 'erasure');

  // 5. Confirm to data subject
  await sendConfirmation(userId, 'erasure_completed');

  // 6. Log for compliance (what was deleted, when, by whom)
  await auditLog.record({
    action: 'DSAR_ERASURE',
    userId,
    timestamp: new Date(),
    details: { retentionHolds: retentionHolds.map(h => h.reason) },
  });
}
```

## Right to Portability

```typescript
async function exportUserData(userId: string): Promise<Buffer> {
  const data = {
    profile: await db.users.findUnique({ where: { id: userId } }),
    orders: await db.orders.findMany({ where: { userId } }),
    preferences: await db.preferences.findMany({ where: { userId } }),
    consents: await db.consents.findMany({ where: { userId } }),
  };

  // Machine-readable format (JSON or CSV)
  return Buffer.from(JSON.stringify(data, null, 2));
}
```

## Anti-patterns
- No identity verification before erasure → anyone can delete accounts
- Hard-deleting data with legal retention → violates tax/financial regulations
- No audit trail of DSAR handling → can't prove compliance
- Ignoring third-party processors → data persists in external systems

## Quick reference
```
Timeline: 30 days, extendable by 2 months (notify within 30)
Identity: verify before processing any DSAR
Erasure: delete OR anonymize (anonymization = no longer personal data)
Retention override: tax records, legal disputes, fraud prevention
Portability: JSON export of all personal data
Third parties: notify processors to delete/restrict
Audit: log every DSAR: type, date, outcome, what was done
Free: first request free, can charge for excessive/repetitive
```
