# Rule-Based Fraud Detection

## When to load
Load when implementing velocity checks, amount thresholds, geographic anomaly rules, or designing
a configurable rule engine with scoring. Covers detection logic, rule schema, and device signals.

## Velocity Checks

- Transaction count per user per time window (e.g., >5 transactions in 10 minutes)
- Cumulative amount per user per day (e.g., >$5,000 in 24 hours)
- Distinct merchant count per user per hour
- Card-not-present transaction frequency thresholds
- Configure thresholds per customer risk tier (new vs established)

## Amount Thresholds

- Flag transactions exceeding customer's historical average by N standard deviations
- Absolute thresholds: flag all transactions above configurable amounts
- Round-number detection: suspicious clustering at exact amounts ($1,000, $5,000)
- Micro-transaction patterns: many small charges (card testing attack)

## Geographic Anomalies

- Impossible travel: transaction in New York then London within 2 hours
- High-risk country origin: FATF grey/black list jurisdictions
- IP geolocation vs billing address mismatch
- VPN/Tor exit node detection
- Shipping address different from billing address (for e-commerce)

## Rule Engine Design

```yaml
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
