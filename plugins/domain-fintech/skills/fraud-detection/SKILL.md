---
name: fraud-detection
description: |
  Guides fraud detection implementation: rule-based detection (velocity checks, amount
  thresholds, geo-anomalies), ML-based anomaly detection (isolation forest, autoencoders),
  device fingerprinting, behavioral biometrics, 3DS2, fraud scoring pipelines,
  case management, and chargeback prevention. Use when building fraud prevention systems.
allowed-tools: Read, Grep, Glob, Bash
---

You are a fraud detection specialist. Balance fraud prevention with user experience — every false positive is a frustrated customer.

## Rule-Based Detection

### Velocity Checks
- Transaction count per user per time window (e.g., >5 transactions in 10 minutes)
- Cumulative amount per user per day (e.g., >$5,000 in 24 hours)
- Distinct merchant count per user per hour
- Card-not-present transaction frequency thresholds
- Configure thresholds per customer risk tier (new vs established)

### Amount Thresholds
- Flag transactions exceeding customer's historical average by N standard deviations
- Absolute thresholds: flag all transactions above configurable amounts
- Round-number detection: suspicious clustering at exact amounts ($1,000, $5,000)
- Micro-transaction patterns: many small charges (card testing attack)

### Geographic Anomalies
- Impossible travel: transaction in New York then London within 2 hours
- High-risk country origin: FATF grey/black list jurisdictions
- IP geolocation vs billing address mismatch
- VPN/Tor exit node detection
- Shipping address different from billing address (for e-commerce)

### Rule Engine Design
```
rules:
  - name: velocity_check
    condition: "tx_count(user, 1h) > 5"
    action: flag_for_review
    score: 30
  - name: amount_anomaly
    condition: "tx_amount > user_avg_amount * 3"
    action: flag_for_review
    score: 25
  - name: impossible_travel
    condition: "distance(prev_tx_location, tx_location) / time_diff > 900 km/h"
    action: block
    score: 80
```

## ML-Based Anomaly Detection

### Isolation Forest
- Unsupervised algorithm that isolates anomalies rather than profiling normal behavior
- Features: transaction amount, time since last transaction, merchant category, geo distance
- Train on historical legitimate transactions
- Anomaly score: shorter average path length = more anomalous
- Retrain periodically as customer behavior evolves

### Autoencoders
- Neural network that learns to reconstruct normal transaction patterns
- High reconstruction error indicates anomalous transaction
- Input features: amount, time, location, merchant, device, behavioral signals
- Train on labeled legitimate data; anomalies have high reconstruction loss
- Deploy as real-time scoring API with <50ms latency requirement

### Model Deployment Considerations
- Shadow mode: run model alongside rules, compare decisions without blocking
- Champion/challenger: A/B test new models against production model
- Model monitoring: track precision, recall, false positive rate continuously
- Feedback loop: case resolution outcomes feed back into model retraining
- Explainability: SHAP values or LIME for auditable decision reasoning

## Device Fingerprinting

### Browser Fingerprint Signals
- User agent string, screen resolution, timezone, language
- Canvas fingerprint, WebGL renderer, audio context
- Installed fonts and plugins
- Hardware concurrency, device memory
- Do Not Track setting (ironically a distinguishing signal)

### Mobile Device Signals
- Device ID (IDFA/GAID with user consent), app version
- Jailbreak/root detection
- Emulator detection (for synthetic fraud)
- SIM card change detection, carrier information

### Device Risk Scoring
- Known fraudulent device: immediate block
- New device + high-value transaction: step-up authentication
- Device age on platform: new devices are higher risk
- Multiple accounts from same device: potential synthetic identity fraud

## Behavioral Biometrics

- Keystroke dynamics: typing speed, dwell time, flight time patterns
- Mouse movement: trajectory, speed, click patterns
- Touch screen: pressure, swipe velocity, hold duration
- Navigation patterns: page visit sequence, time on page
- Session anomaly: behavior diverges from user's established pattern

## 3DS2 (3-D Secure 2.0)

### Frictionless vs Challenge Flow
- Frictionless: issuer approves based on risk assessment (no user interaction)
- Challenge: additional authentication required (OTP, biometric, app approval)
- Send rich data to issuer for better risk assessment (device, behavior, history)
- Optimize for frictionless approval rate while maintaining security

### Implementation
- Integrate via payment processor SDK (Stripe 3DS, Adyen 3DS2)
- Collect browser data for device fingerprinting (3DS Method)
- Handle authentication response: Y (authenticated), N (not authenticated), A (attempted), U (unavailable)
- Liability shift: successful 3DS shifts chargeback liability to issuer

## Fraud Scoring Pipeline

### Real-Time Pipeline
```
Transaction -> Feature Extraction -> Rule Engine -> ML Scoring -> Decision Engine -> Allow/Block/Review
                                         |              |
                                    Rule Score      ML Score
                                         |              |
                                    Combined Score -> Threshold
```

### Scoring Tiers
- **Score 0-30**: Low risk, auto-approve
- **Score 31-60**: Medium risk, apply step-up authentication
- **Score 61-80**: High risk, flag for manual review
- **Score 81-100**: Very high risk, auto-block with notification

### Feature Store
- Pre-computed features for low-latency scoring (user history, device history)
- Real-time features computed at transaction time (velocity, geo-distance)
- Batch features updated daily (behavioral profiles, risk models)
- Redis or similar in-memory store for sub-millisecond feature retrieval

## Case Management

### Review Workflow
- Queue management: prioritize by risk score, amount, SLA deadline
- Analyst workspace: transaction details, customer history, device info, linked accounts
- Decision options: approve, block, escalate, request information
- Decision documentation: mandatory reason code and free-text notes
- Four-eyes principle: high-value cases require independent second review

### Feedback Loop
- Case outcomes (confirmed fraud vs false positive) feed into:
  - Rule threshold tuning
  - ML model retraining datasets
  - Customer risk profile updates
  - Device reputation database

## Chargeback Prevention

- Compelling evidence collection: delivery proof, IP logs, device fingerprint, 3DS result
- Descriptor clarity: ensure statement descriptor matches what customer expects
- Pre-dispute alerts: Verifi CDRN, Ethoca alerts for early resolution
- Refund automation: auto-refund for known dispute patterns when cheaper than fighting
- Chargeback ratio monitoring: stay below card network thresholds (Visa: 0.9%, Mastercard: 1.0%)
