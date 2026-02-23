# Traffic Estimation and Resource Sizing

## When to load
Load when estimating QPS from DAU metrics, sizing CPU/memory/storage/network resources, or modeling linear, exponential, and step-function growth patterns for infrastructure planning.

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
- Connection limits: load balancers and reverse proxies have connection limits. Size for peak concurrent connections (long-lived connections like WebSockets require different planning than QPS).

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
