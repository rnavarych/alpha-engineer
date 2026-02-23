# SLI/SLO/SLA, Alerting, and Dashboards

## When to load
Load when defining SLIs/SLOs, calculating error budgets, designing alerting rules, building dashboards, or setting up on-call processes.

## SLI / SLO / SLA Definitions
- **SLI**: Quantitative measure of service quality (request latency p99, availability ratio, error rate)
- **SLO**: Target value or range for an SLI (e.g., 99.9% availability over 30-day rolling window)
- **SLA**: Contractual commitment around SLOs with financial or legal consequences
- **Error budget**: `100% - SLO target = allowed downtime/errors`

## Concrete SLO Examples

| Service Type | SLI | SLO Target |
|-------------|-----|------------|
| API Gateway | Availability | 99.95% (21.9 min/month downtime) |
| Payment Service | Latency (p99) | < 500ms |
| Auth Service | Availability | 99.99% (4.3 min/month downtime) |
| CDN | Cache Hit Ratio | > 95% |

## Error Budget Calculations
```
SLO: 99.9% availability (30-day window) → Error budget: 0.1% = 43.2 minutes/month

Burn rate = (errors_consumed / error_budget) * (window / elapsed_time)

Multi-window alerting:
- Page:   burn rate > 14.4x for 1 hour  (consumes 2% budget in 1h)
- Page:   burn rate > 6x   for 6 hours  (consumes 5% budget in 6h)
- Ticket: burn rate > 3x   for 1 day    (consumes 10% budget in 1d)
```

## Alerting Best Practices
- **Alert on symptoms** (what users experience): high error rate, slow responses, unavailability
- **Do NOT alert on causes**: high CPU, disk at 80%, single pod restart — these are dashboard items
- **Exception**: Alert on causes only when imminent threats (disk 95%+, certificate expiring in 7 days)

## Alert Severity Levels

| Severity | Action | Response Time | Example |
|----------|--------|---------------|---------|
| **Critical / P1** | Page on-call | < 15 min | Service down, error budget burning > 14x |
| **Warning / P2** | Create ticket | < 4 hours | Elevated error rate, degraded performance |
| **Info / P3** | Dashboard review | Next business day | Capacity trending, minor anomalies |

## Runbook Template
Every alert must link to a runbook:
1. **Alert name and description**: What does this alert mean?
2. **Impact**: What is the user impact?
3. **Diagnosis steps**: Commands/queries to run, dashboards to check
4. **Remediation steps**: Step-by-step fix instructions
5. **Escalation**: When and whom to escalate to

## Dashboard Hierarchy
1. **Executive dashboard**: Business KPIs, SLO status, overall system health (red/amber/green)
2. **Service overview**: All services, error rates, latency heatmaps, traffic volume
3. **Service detail**: Per-service RED metrics, dependency health, deployment markers
4. **Infrastructure**: Node/pod CPU, memory, disk, network (USE method)
5. **Debug/investigation**: Trace search, log exploration, ad-hoc queries

## RED and USE Dashboards
- **RED** (Rate, Errors, Duration): requests/second, error rate %, latency percentiles (p50/p90/p99)
- **USE** (Utilization, Saturation, Errors): CPU%, memory%, queue depth, connection pool exhaustion

## Correlation Workflow
1. **Alert fires** on high error rate (metric)
2. **Dashboard** shows which endpoint/service is affected
3. **Exemplar** on the metric links to a specific trace
4. **Trace view** shows the full request path and where it failed
5. **Span** links to logs with same `trace_id` showing error details

## On-Call Design
- Rotation: 1-week primary + secondary; follow-the-sun for global teams
- Escalation: primary (5 min) → secondary (10 min) → engineering manager (15 min)
- On-call load target: < 2 pages per shift; review if consistently exceeded
- Blameless post-mortems for every P1/P2 incident within 48 hours
