---
name: fraud-detection
description: "Guides fraud detection implementation: rule-based detection (velocity checks, amount thresholds, geo-anomalies), ML-based anomaly detection (isolation forest, autoencoders), device fingerprinting, behavioral biometrics, 3DS2, fraud scoring pipelines, case management, and chargeback prevention. Use when building fraud prevention systems, designing real-time scoring pipelines, or implementing 3DS2 authentication flows."
allowed-tools: Read, Grep, Glob, Bash
---

# Fraud Detection

## When to use
- Building or tuning velocity checks, amount anomaly rules, and geo-anomaly detection
- Implementing ML-based anomaly detection (isolation forest, autoencoders)
- Designing a real-time fraud scoring pipeline with combined rule + ML scores
- Adding device fingerprinting or behavioral biometrics to authentication flows
- Implementing 3DS2 and optimizing frictionless approval rates
- Building fraud analyst case management queues and chargeback prevention

## Core principles
1. **Every false positive is a lost customer** — tune thresholds per risk tier, not globally
2. **Combine rules and ML** — rules catch known patterns fast; ML catches novel behavior
3. **Feature freshness determines accuracy** — stale user profiles produce wrong scores at scale
4. **Feedback loop is mandatory** — case outcomes that don't retrain the model are wasted signal
5. **Liability shift over blocking** — 3DS2 frictionless approval with liability shift beats auto-decline

## Workflow

### Step 1: Implement rule-based detection layer
```
# Velocity check example
rules:
  - name: card_velocity_1h
    condition: tx_count(card_id, 1h) > 5
    score: 30
  - name: amount_anomaly
    condition: tx_amount > (user_avg_amount * 3)
    score: 25
  - name: geo_anomaly
    condition: distance(last_tx_location, current_location) > 500km
              AND time_delta < 1h
    score: 40
```
- Define rules with individual risk scores (0-100)
- Set per-tier thresholds: low-risk users tolerate higher scores before blocking
- Log all rule evaluations for audit trail

### Step 2: Add ML scoring pipeline
```
# Real-time scoring architecture
Transaction → Feature Store → [Rule Engine (ms)] → Combined Score
                             → [ML Model (ms)]   ↗
                                                    ↓
                             Score > threshold? → Block / 3DS2 / Allow
```
- Deploy isolation forest for unsupervised anomaly detection
- Use champion-challenger pattern: shadow model scores alongside production model
- Combine rule score + ML score with weighted average (e.g., 0.4 * rules + 0.6 * ML)

### Step 3: Configure 3DS2 authentication
- Route medium-risk transactions (score 40-70) to 3DS2 frictionless flow
- High-risk (score 70+) triggers 3DS2 challenge flow
- Track frictionless approval rate — target >90% for good user experience
- Liability shift on 3DS2 reduces chargeback exposure

### Step 4: Close the feedback loop
- Route flagged transactions to analyst case management queue
- Record case outcomes (confirmed fraud, false positive, inconclusive)
- Feed outcomes back to ML model retraining pipeline weekly
- Monitor chargeback ratio — alert if approaching card network thresholds (0.9%)

## Reference Files
- `references/rule-based-detection.md` — velocity checks, amount thresholds, geographic anomaly rules, rule engine schema with scoring, device fingerprinting signals and risk scoring
- `references/ml-scoring-pipeline.md` — isolation forest and autoencoder models, model deployment (shadow/champion-challenger), behavioral biometrics, real-time scoring pipeline, scoring tiers, feature store design
- `references/3ds2-case-management.md` — 3DS2 frictionless vs challenge flow, implementation via processor SDK, analyst review workflow, feedback loop, chargeback prevention and ratio monitoring
