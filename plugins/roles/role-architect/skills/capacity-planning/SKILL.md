---
name: capacity-planning
description: |
  Capacity planning expertise including traffic estimation, resource sizing,
  growth modeling, peak load planning, infrastructure runway calculation,
  and load testing correlation.
allowed-tools: Read, Grep, Glob, Bash
---

# Capacity Planning

## Traffic Estimation

### From DAU to QPS
- Start with business metrics: Daily Active Users (DAU), Monthly Active Users (MAU), and the ratio between them (DAU/MAU indicates engagement intensity; 0.2 is low, 0.5+ is high).
- Actions per session: average number of API calls or page views per user visit. Measure from analytics or estimate from user flow analysis.
- Average QPS = DAU x actions_per_session / 86,400 (seconds per day).
- Peak QPS = Average QPS x peak_multiplier. Typical multipliers: 2x-3x for B2B SaaS, 3x-5x for consumer apps, 10x-100x for event-driven traffic (flash sales, live events).
- Time-of-day distribution: most applications see 70-80% of traffic in 8-10 hours. Adjust QPS calculations to reflect this concentration.

### Traffic Composition
- Break traffic into categories: read vs. write, authenticated vs. anonymous, API vs. static content.
- Typical read/write ratios: 90/10 for content platforms, 70/30 for e-commerce, 50/50 for messaging.
- Each category has different resource requirements. Reads are typically CPU-light and cache-friendly; writes are CPU-heavy and require database access.

### Growth Projections
- Gather growth targets from business stakeholders: expected user growth rate (monthly or quarterly).
- Model conservatively: plan for the expected case, stress-test for 2x the expected case.
- Revalidate projections quarterly. Actual growth rarely matches forecasts; adjust infrastructure plans accordingly.

## Resource Sizing

### CPU
- Profile application under realistic load to determine CPU utilization per request.
- Target: 60-70% CPU utilization at expected peak. Remaining headroom absorbs unexpected spikes and prevents latency degradation.
- Rule of thumb: one modern vCPU handles 100-1000 simple API requests/second or 10-50 compute-intensive requests/second. Profile to get actual numbers.
- Account for background processes: garbage collection, log rotation, health checks, metrics collection.

### Memory
- Application memory: base footprint + per-request allocation x concurrent requests.
- Cache memory: working set size (frequently accessed data). Size to achieve target cache hit ratio (typically 90-95%).
- Connection memory: each database connection uses 5-10 MB, each HTTP/2 connection uses 1-5 MB.
- Buffer memory: OS page cache, network buffers, temporary file processing.
- Target: 70-80% memory utilization at peak. OOM kills are catastrophic; always leave headroom.

### Storage
- Calculate data volume: record_size x records_per_day x retention_days.
- Include overhead: indexes (20-50% of data size), WAL/transaction logs (2-5x write volume for databases), and replication (2x-3x for redundancy).
- IOPS requirements: random_reads_per_second + random_writes_per_second. Match to storage tier (SSD: 3000-64000 IOPS, HDD: 100-200 IOPS).
- Plan for storage growth: current_volume x (1 + monthly_growth_rate)^months. Set alerts at 70% capacity to trigger expansion.

### Network
- Bandwidth: average_response_size x QPS. Convert to Mbps. Include both application traffic and replication traffic.
- Latency: inter-service calls add network latency. Target < 1ms within the same availability zone, < 5ms cross-zone, < 50-100ms cross-region.
- Connection limits: load balancers and reverse proxies have connection limits. Size for peak concurrent connections (not QPS; long-lived connections like WebSockets require different planning).

## Growth Modeling

### Linear Growth
- Cost and resource needs increase proportionally with load. Each new user adds a fixed increment of resource consumption.
- Plan for: adding capacity in discrete steps (new instances, larger disks) ahead of demand.
- Example: a SaaS application that adds 1000 users/month, each consuming 50 MB of storage.

### Exponential Growth
- Resource needs compound over time. Early stages feel manageable; later stages require rapid scaling.
- Warning signs: doubling period is shrinking, or growth rate is accelerating.
- Plan for: auto-scaling, horizontal architecture, and frequent capacity review cycles (weekly instead of monthly).

### Step-Function Growth
- Growth happens in discrete jumps (new enterprise customer, viral event, geographic expansion).
- Plan for: pre-provisioned capacity pools, rapid scaling runbooks, and capacity reservations.
- Maintain a "dark capacity" buffer: infrastructure provisioned but not actively serving traffic, ready to absorb sudden load.

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
