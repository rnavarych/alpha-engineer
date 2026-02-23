# GDPR Data Mapping

## When to load
Load when creating data inventories, determining lawful basis, or setting retention periods.

## Personal Data Inventory

```
For each data type, document:
1. What: type of personal data
2. Why: lawful basis for processing
3. Where: storage location(s)
4. Who: who has access
5. How long: retention period
6. How protected: encryption, access controls
```

| Data Type | Lawful Basis | Storage | Retention | Encryption |
|-----------|-------------|---------|-----------|------------|
| Email | Contract | PostgreSQL | Account lifetime + 30d | At-rest (AES-256) |
| Name | Contract | PostgreSQL | Account lifetime + 30d | At-rest |
| IP Address | Legitimate Interest | Logs (CloudWatch) | 90 days | In-transit (TLS) |
| Payment card | Contract (tokenized) | Stripe (not stored locally) | N/A | Stripe PCI Level 1 |
| Cookie ID | Consent | Browser + analytics | 13 months | N/A |
| Usage analytics | Legitimate Interest | PostHog | 24 months | At-rest + in-transit |

## Lawful Basis Decision Tree

```
Is it necessary for the contract? → Contract (Art. 6(1)(b))
  Examples: email for account, address for shipping

Is it required by law? → Legal Obligation (Art. 6(1)(c))
  Examples: tax records, audit logs

Is there a legitimate business need? → Legitimate Interest (Art. 6(1)(f))
  Must pass 3-part test: purpose, necessity, balancing
  Examples: fraud prevention, security logs, analytics

None of the above? → Consent (Art. 6(1)(a))
  Must be: freely given, specific, informed, unambiguous
  Examples: marketing emails, cookies, third-party sharing
```

## Retention Schedule

```
Active account data: lifetime of account + 30 days after deletion
Invoices/tax records: 7 years (legal obligation)
Server logs: 90 days
Analytics: 24 months
Support tickets: 3 years
Marketing consent: until withdrawn
Deleted account backup: 30 days maximum
```

## Anti-patterns
- Storing data "just in case" without lawful basis → GDPR violation
- No retention schedule → data accumulates indefinitely
- Relying on consent when contract basis applies → unnecessary consent fatigue
- No data inventory → can't respond to DSARs or DPIAs

## Quick reference
```
Data mapping: what, why, where, who, how long, how protected
Lawful basis: contract > legal obligation > legitimate interest > consent
Retention: define per data type, automate deletion
DPIA required: high-risk processing, large-scale, new technology
Record of Processing Activities (ROPA): mandatory for 250+ employees
Data inventory review: annually or when processing changes
```
