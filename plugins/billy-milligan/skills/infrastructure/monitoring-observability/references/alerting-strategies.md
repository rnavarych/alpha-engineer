# Alerting Strategies

## SLO-Based Alerting

Alert on error budget consumption rate, not raw error counts.

```
SLO: 99.9% availability = 0.1% error budget = 43 min/month

Fast burn: consuming 2% of monthly budget in 1 hour
  Error rate threshold: 14.4 * 0.001 = 1.44%
  Action: Page immediately (SEV1/SEV2)

Slow burn: consuming 5% of monthly budget in 6 hours
  Error rate threshold: 6 * 0.001 = 0.6%
  Action: Warning, investigate during business hours
```

## Burn Rate Alert Rules

```yaml
# Prometheus alerting rules
groups:
  - name: slo-burn-rate
    rules:
      # Fast burn: 14.4x over 1h (pages)
      - alert: ErrorBudgetFastBurn
        expr: |
          (
            rate(http_requests_total{status_code=~"5.."}[1h])
            / rate(http_requests_total[1h])
          ) > (14.4 * 0.001)
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Fast error budget burn detected"
          description: "Error rate {{ $value | humanizePercentage }} exceeds 14.4x burn rate"
          runbook_url: "https://wiki.example.com/runbooks/error-budget"

      # Slow burn: 6x over 6h (warns)
      - alert: ErrorBudgetSlowBurn
        expr: |
          (
            rate(http_requests_total{status_code=~"5.."}[6h])
            / rate(http_requests_total[6h])
          ) > (6 * 0.001)
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "Slow error budget burn detected"
          description: "Error rate {{ $value | humanizePercentage }} exceeds 6x burn rate"

      # Latency SLO: P99 > 1s
      - alert: LatencySLOBreach
        expr: |
          histogram_quantile(0.99,
            rate(http_request_duration_seconds_bucket[5m])
          ) > 1.0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "P99 latency exceeds 1s SLO"
```

## Multi-Window Multi-Burn-Rate

Google SRE recommended approach using two windows per severity:

```
Critical (page):
  Short window: 1h burn rate > 14.4x  AND
  Long window:  5m burn rate > 14.4x
  Detection time: ~3 minutes
  Budget consumed before alert: 2%

Warning (ticket):
  Short window: 6h burn rate > 6x  AND
  Long window:  30m burn rate > 6x
  Detection time: ~18 minutes
  Budget consumed before alert: 5%

Combining short AND long windows reduces false positives from brief spikes.
```

## Alert Fatigue Prevention

```
Rules for healthy alerting:
  1. Every alert must have a runbook URL
  2. Every alert must be actionable (if nobody knows what to do, delete it)
  3. If an alert fires > 5x/week without action, it needs tuning or removal
  4. Separate pages (wake someone up) from warnings (next business day)
  5. Group related alerts to avoid notification storms

Alert severity mapping:
  critical -> PagerDuty/OpsGenie page (wakes someone up)
  warning  -> Slack channel + ticket creation
  info     -> Dashboard only (no notification)
```

## Alert Design Checklist

```
For every new alert, answer:
  [ ] What service/SLO does this protect?
  [ ] What action should the on-call take?
  [ ] Is there a runbook linked?
  [ ] Is the threshold based on SLO, not arbitrary?
  [ ] Does the `for` duration prevent spike false positives?
  [ ] Is the severity correct (page vs warn)?
  [ ] Who gets notified?
  [ ] Has this alert been tested (fire it intentionally)?
```

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Alert on raw error count | Use rate-based or burn-rate alerting |
| No `for` duration | Add `for: 2m+` to filter transient spikes |
| Alert without runbook | Every alert needs `runbook_url` annotation |
| Everything is critical | Reserve `critical` for revenue/data impact |
| Alerting on symptoms AND causes | Alert on symptoms (user impact), investigate causes |
| Individual host alerts | Alert on service-level aggregates |

## Quick Reference

- Fast burn: **14.4x** over **1h** = page immediately
- Slow burn: **6x** over **6h** = warning, business hours
- Multi-window: combine short + long window to reduce false positives
- Runbook: mandatory for every alert
- Review cadence: monthly alert hygiene review
- Max pages per week: **< 2** per on-call engineer (target)
- SLO 99.9% error budget: **43 min/month**
