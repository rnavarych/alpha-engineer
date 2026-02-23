# Peak Load Planning, Runway Calculation, and Load Testing

## When to load
Load when planning for seasonal or event-driven traffic spikes, calculating infrastructure runway, designing load tests, or correlating load test results to capacity thresholds.

## Peak Load Planning

### Seasonal Peaks
- Identify recurring peaks: end-of-month for fintech, holiday season for e-commerce, enrollment periods for education, tax season for accounting.
- Historical data is the best predictor. Compare year-over-year peak traffic and extrapolate with the current growth rate.
- Pre-scale infrastructure 1-2 weeks before expected peaks. Verify scaling by running load tests at projected peak levels.

### Event-Driven Peaks
- Marketing campaigns, product launches, and viral content cause unpredictable spikes.
- Design for graceful degradation: shed non-essential features under extreme load (disable recommendations, defer analytics, serve cached content).
- Implement admission control: queue excess requests rather than rejecting them. Use exponential backoff for retries.
- Post-event review: compare actual peak with projections. Update models and capacity plans.

### Thundering Herd
- All users or services attempt the same action simultaneously (cache expiration, service restart, scheduled job trigger).
- Mitigate with: staggered cache TTLs (jitter), request coalescing (single-flight pattern), and exponential backoff with jitter for retries.

## Infrastructure Runway Calculation

- Runway = time until current infrastructure reaches capacity at the projected growth rate.
- Calculate per resource type: CPU runway, memory runway, storage runway, network runway. The shortest runway is the binding constraint.
- Formula: runway_months = (capacity_limit - current_usage) / monthly_growth_increment.
- Maintain minimum 3-month runway for infrastructure that requires procurement or provisioning lead time. Maintain 1-month runway for auto-scalable resources.
- Dashboard the runway for each critical resource. Alert when runway drops below the minimum threshold.
- Factor in provisioning lead time: if adding capacity takes 2 weeks, trigger the process when runway reaches 6 weeks, not 2 weeks.

## Load Testing Correlation

### Establishing Baselines
- Run load tests against a production-like environment. Match instance types, data volume, and network topology.
- Test at: current peak QPS (validate headroom), 2x current peak (validate scaling behavior), and projected peak in 6-12 months (validate growth plan).
- Record metrics at each level: latency percentiles (P50, P95, P99), error rate, CPU utilization, memory utilization, and database query times.

### Correlating Test Results with Capacity
- Map load test results to capacity thresholds. At what QPS does P99 latency exceed the SLA? At what QPS does error rate exceed 0.1%? That is the effective capacity ceiling.
- Compare effective capacity with projected peak QPS. The gap is your safety margin.
- Identify the bottleneck resource at each load level. Fix bottlenecks in order: the first bottleneck you hit determines system capacity.

### Continuous Load Testing
- Run load tests regularly (weekly or per release) to detect capacity regressions early.
- Integrate load tests into the CI/CD pipeline for critical services. Block releases that degrade throughput by more than 10% or latency by more than 20%.
- Maintain a load test history. Track capacity trends over time to validate growth models.
- Chaos engineering: combine load tests with fault injection (kill instances, add latency, simulate network partitions) to validate resilience under load.
