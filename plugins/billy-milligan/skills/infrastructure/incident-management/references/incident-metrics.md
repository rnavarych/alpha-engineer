# Incident Metrics

## When to load
Load when classifying incident severity, tracking MTTR and MTTD, measuring SLO error budget
impact, or setting up dashboards for reliability metrics.

## Severity Classification

```
SEV1 — Critical (customer-facing, widespread)
  Definition: Complete service outage or data loss affecting all or majority of users
  Examples:
    - Payment processing down for all customers
    - Authentication service unavailable
    - Data corruption or loss detected
    - Security breach in progress
  Response SLA:
    Acknowledge: 5 minutes
    IC assigned: 10 minutes
    Status page update: 15 minutes
    Executive notification: 30 minutes

SEV2 — High (significant degradation or partial outage)
  Definition: Core feature unavailable for a subset of users, or severe performance degradation
  Examples:
    - Checkout failing for 20% of users
    - API latency > 5x normal for 30+ minutes
    - Background job processing halted
  Response SLA:
    Acknowledge: 15 minutes
    IC assigned: 20 minutes
    Status page update: 30 minutes

SEV3 — Medium (degraded experience, workaround exists)
  Definition: Non-critical feature broken, elevated error rate, minor data inconsistency
  Examples:
    - Email notifications delayed by > 2 hours
    - Search results stale by > 30 minutes
    - Non-critical dashboard missing data
  Response SLA:
    Acknowledge: 1 hour
    Resolution target: next business day

SEV4 — Low (minor issue, no user impact)
  Definition: Cosmetic issues, minor bugs, technical debt items surfaced by monitoring
  Response SLA:
    Log in issue tracker
    Resolution target: within 2 weeks
```

## Core Reliability Metrics

### MTTD — Mean Time to Detect

```
Definition: Time from incident start to first alert or human detection
Formula:    MTTD = (detection_time - incident_start_time) averaged over incidents

Target benchmarks:
  SEV1: < 5 minutes
  SEV2: < 15 minutes
  SEV3: < 1 hour

How to improve:
  - Synthetic monitoring (uptime probes every 30s from multiple regions)
  - Alerting on error rate spikes, not just absolute thresholds
  - User-facing health checks, not just infrastructure metrics
  - Anomaly detection on latency percentiles (p99 > 2x baseline)
```

### MTTR — Mean Time to Resolve

```
Definition: Time from incident detection to full service restoration
Formula:    MTTR = (resolution_time - detection_time) averaged over incidents

Target benchmarks:
  SEV1: < 30 minutes
  SEV2: < 2 hours
  SEV3: < 8 hours

Components of MTTR:
  Triage time   : detection → root cause identified
  Mitigation    : root cause → service partially restored (stop the bleeding)
  Resolution    : partial → full restoration

How to reduce MTTR:
  - Runbooks for every recurring failure mode
  - Feature flags for instant rollback without deploy
  - Rollback procedure tested quarterly
  - Blast radius reduction (canary deploys)
```

### MTBF — Mean Time Between Failures

```
Definition: Average time between incidents of the same severity
Formula:    MTBF = total_uptime / number_of_incidents

Higher MTBF = more stable system.
Track per service, not globally — a noisy service hides stable ones.
```

## SLO Error Budget Tracking

```
Example SLO: 99.9% availability over 30-day rolling window
  Error budget: 0.1% of 30 days = 43.2 minutes/month

Incident impact calculation:
  SEV1 — 90 minutes outage
    Error budget consumed: 90 / 43.2 = 208% — budget blown, freeze deployments

  SEV2 — 20% of users affected for 45 minutes
    Weighted impact: 45 * 0.20 = 9 minutes equivalent
    Error budget consumed: 9 / 43.2 = 20.8%

  SEV3 — non-critical feature, 10% of users, 2 hours
    Weighted impact: 120 * 0.10 = 12 minutes equivalent
    Error budget consumed: 12 / 43.2 = 27.8%
```

```yaml
# Prometheus recording rule for error budget
groups:
  - name: slo_error_budget
    rules:
      - record: slo:error_budget_remaining_minutes
        expr: |
          (1 - slo:availability_ratio_30d) * (30 * 24 * 60)
        labels:
          service: "{{ $labels.service }}"

      - alert: ErrorBudgetBurnRateHigh
        expr: slo:error_budget_burn_rate_1h > 14.4  # 1-hour burn rate > 14.4x
        for: 5m
        labels:
          severity: page
        annotations:
          summary: "Error budget burning too fast — projected exhaustion in < 3 days"
```

## Incident Metrics Dashboard

```
Key panels for reliability dashboard:
  1. MTTD by severity (rolling 30 days, trend)
  2. MTTR by severity (rolling 30 days, trend)
  3. Incident frequency by severity (weekly bar chart)
  4. Error budget remaining per service (gauge)
  5. On-call load (incidents per person per week)
  6. Postmortem action item completion rate

Alert on:
  - Error budget < 20% remaining in current window
  - MTTR for SEV1 > 45 minutes (missed SLA)
  - Incident frequency increasing week-over-week
  - On-call load > 3 SEV1/2 incidents per person per week
```

## Quick reference

```
SEV1 acknowledge  : 5 minutes | resolve target: 30 minutes
SEV2 acknowledge  : 15 minutes | resolve target: 2 hours
SEV3 acknowledge  : 1 hour | resolve target: next business day
MTTD target SEV1  : < 5 minutes
MTTR target SEV1  : < 30 minutes
Error budget math : outage_minutes / (slo_percentage * window_minutes)
Budget blown      : freeze non-critical deployments until replenished
Postmortem guide  : see postmortem-guide.md
```
