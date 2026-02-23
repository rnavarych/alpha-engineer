# ML-Based Detection and Fraud Scoring Pipeline

## When to load
Load when implementing ML anomaly detection models, designing the real-time scoring pipeline,
building a feature store, or configuring scoring tiers with decision thresholds.

## Isolation Forest

- Unsupervised algorithm that isolates anomalies rather than profiling normal behavior
- Features: transaction amount, time since last transaction, merchant category, geo distance
- Train on historical legitimate transactions
- Anomaly score: shorter average path length = more anomalous
- Retrain periodically as customer behavior evolves

## Autoencoders

- Neural network that learns to reconstruct normal transaction patterns
- High reconstruction error indicates anomalous transaction
- Input features: amount, time, location, merchant, device, behavioral signals
- Train on labeled legitimate data; anomalies have high reconstruction loss
- Deploy as real-time scoring API with <50ms latency requirement

## Model Deployment Considerations

- Shadow mode: run model alongside rules, compare decisions without blocking
- Champion/challenger: A/B test new models against production model
- Model monitoring: track precision, recall, false positive rate continuously
- Feedback loop: case resolution outcomes feed back into model retraining
- Explainability: SHAP values or LIME for auditable decision reasoning

## Behavioral Biometrics

- Keystroke dynamics: typing speed, dwell time, flight time patterns
- Mouse movement: trajectory, speed, click patterns
- Touch screen: pressure, swipe velocity, hold duration
- Navigation patterns: page visit sequence, time on page
- Session anomaly: behavior diverges from user's established pattern

## Real-Time Scoring Pipeline

```
Transaction -> Feature Extraction -> Rule Engine -> ML Scoring -> Decision Engine -> Allow/Block/Review
                                         |              |
                                    Rule Score      ML Score
                                         |              |
                                    Combined Score -> Threshold
```

## Scoring Tiers

- **Score 0-30**: Low risk, auto-approve
- **Score 31-60**: Medium risk, apply step-up authentication
- **Score 61-80**: High risk, flag for manual review
- **Score 81-100**: Very high risk, auto-block with notification

## Feature Store

- Pre-computed features for low-latency scoring (user history, device history)
- Real-time features computed at transaction time (velocity, geo-distance)
- Batch features updated daily (behavioral profiles, risk models)
- Redis or similar in-memory store for sub-millisecond feature retrieval
