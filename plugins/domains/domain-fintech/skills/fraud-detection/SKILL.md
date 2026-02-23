---
name: fraud-detection
description: Guides fraud detection implementation: rule-based detection (velocity checks, amount thresholds, geo-anomalies), ML-based anomaly detection (isolation forest, autoencoders), device fingerprinting, behavioral biometrics, 3DS2, fraud scoring pipelines, case management, and chargeback prevention. Use when building fraud prevention systems.
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

## Reference Files
- `references/rule-based-detection.md` — velocity checks, amount thresholds, geographic anomaly rules, rule engine schema with scoring, device fingerprinting signals and risk scoring
- `references/ml-scoring-pipeline.md` — isolation forest and autoencoder models, model deployment (shadow/champion-challenger), behavioral biometrics, real-time scoring pipeline, scoring tiers, feature store design
- `references/3ds2-case-management.md` — 3DS2 frictionless vs challenge flow, implementation via processor SDK, analyst review workflow, feedback loop, chargeback prevention and ratio monitoring
