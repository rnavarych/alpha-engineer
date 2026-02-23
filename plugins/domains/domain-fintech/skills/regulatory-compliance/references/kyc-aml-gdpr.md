# KYC/AML and GDPR for Financial Data

## When to load
Load when implementing Customer Due Diligence, PEP/sanctions screening, transaction monitoring
rules, or navigating the GDPR retention vs AML deletion tension in financial systems.

## Customer Due Diligence (CDD)

- **Simplified (SDD)**: low-risk customers, limited verification
- **Standard (CDD)**: identity document verification, address verification, source of funds
- **Enhanced (EDD)**: PEPs, high-risk countries (FATF grey/black list), complex structures

## PEP Screening

- Screen against PEP databases at onboarding and periodically (at least annually)
- Include family members and close associates (RCA) in screening
- Fuzzy matching with configurable Levenshtein distance threshold
- Four-eyes principle: screening matches require independent review

## Sanction List Checking

- OFAC SDN list (US), EU consolidated sanctions, UN Security Council list
- HMT sanctions list (UK), SECO (Switzerland)
- Real-time screening for all transactions, not just onboarding
- Update lists within 24 hours of publication
- Match disposition: true match, false positive, escalation required

## Transaction Monitoring Rules

- Structuring detection: multiple transactions just below reporting thresholds
- Rapid movement: funds in and out within short time window
- Geographic anomalies: transactions from sanctioned or high-risk jurisdictions
- Unusual patterns: deviation from established customer behavior profile
- Threshold: Currency Transaction Reports (CTR) for cash >$10,000 (US)

## GDPR for Financial Data

### Retention vs Deletion Tension
- GDPR requires deletion on request; AML requires retention for 5-7 years
- Legal obligation (AML) overrides right to erasure for regulated data
- Separate regulated data from non-regulated data in schema design
- Anonymize non-regulated data upon deletion request; retain regulated data with legal basis annotation

### Data Minimization
- Collect only data required for the stated purpose
- Regularly review data holdings against active purposes
- Implement automated data lifecycle management with retention policies
- Pseudonymize where possible (replace names with tokens in analytics)
