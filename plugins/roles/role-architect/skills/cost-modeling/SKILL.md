---
name: cost-modeling
description: |
  Cost modeling expertise including infrastructure cost estimation, TCO calculation,
  build vs buy analysis, pricing model comparison, ROI projection,
  cost growth modeling, and breakeven analysis.
allowed-tools: Read, Grep, Glob, Bash
---

# Cost Modeling

## Infrastructure Cost Estimation

### Compute Costs
- Estimate based on workload type: on-demand for unpredictable traffic, reserved/committed use for baseline load (30-60% savings), spot/preemptible for fault-tolerant batch jobs (60-90% savings).
- Size instances by profiling: CPU-bound workloads need compute-optimized instances, memory-bound workloads need memory-optimized, and I/O-bound workloads need storage-optimized.
- Account for auto-scaling: define minimum (baseline cost), desired (expected cost), and maximum (peak cost) instance counts.
- Include orchestration overhead: Kubernetes control plane, load balancers, NAT gateways, and service mesh sidecars.

### Storage Costs
- Classify data by access frequency: hot (SSD, highest cost), warm (standard, medium cost), cold (archival, lowest cost).
- Calculate per tier: data_volume x price_per_GB x retention_period. Include replication (typically 3x for durability).
- Account for data transfer costs between storage tiers, regions, and to the internet. Egress fees are often the surprise line item.
- Include backup costs: full snapshots (daily) plus incremental backups (hourly). Calculate based on change rate.

### Network Costs
- Intra-region traffic is usually free or cheap. Cross-region and internet egress are expensive.
- Estimate monthly egress: average_response_size x requests_per_month x percentage_served_from_origin (not CDN).
- CDN costs: price per GB served + price per 10K requests. Compare CDN providers (CloudFront, Cloudflare, Fastly) at your projected traffic.
- Include VPN/interconnect costs for hybrid cloud or multi-cloud architectures.

### Managed Service Costs
- Database: per-instance-hour + storage + I/O operations + backup storage. Compare managed (RDS, Cloud SQL) vs. self-hosted (EC2 + PostgreSQL).
- Message queues: per-message or per-request pricing. Calculate based on throughput projections.
- Monitoring and logging: per-GB ingested, per-metric tracked, per-dashboard. Logging costs scale faster than most teams expect.

## TCO Calculation

- Structure TCO across five categories over a 3-year horizon:
  1. **License fees**: Software licenses, SaaS subscriptions, support contracts. Include annual escalation (typically 3-8%).
  2. **Infrastructure fees**: Compute, storage, network, managed services (as estimated above).
  3. **Operations costs**: Person-hours for deployment, monitoring, patching, incident response. Engineer_hourly_rate x hours_per_month x 36 months.
  4. **Training costs**: Courses, certifications, ramp-up productivity loss. Estimate 1-3 months of reduced output per engineer learning a new technology.
  5. **Migration costs**: One-time costs to adopt the technology: integration development, data migration, testing, and cutover.
- Present as annual and cumulative 3-year totals. Show both pessimistic and optimistic scenarios.

## Build vs. Buy Analysis

### When to Build
- The capability is your core competitive advantage.
- No vendor product fits without extensive customization (>30% of features require custom development).
- The vendor's roadmap does not align with your needs.
- Regulatory or security requirements prohibit third-party data handling.

### When to Buy
- The capability is commodity (authentication, email, payments, analytics).
- Time-to-market pressure makes building infeasible.
- The vendor's solution is battle-tested at your required scale.
- The total cost of buying (license + integration + operations) is less than building (development + maintenance + opportunity cost).

### Quantifying the Decision
- Build cost: (developer_days x daily_rate) + ongoing_maintenance (typically 15-20% of build cost per year).
- Buy cost: license_fee + integration_cost (developer_days x daily_rate) + annual_subscription + operational_overhead.
- Compare over 3 years. Building is usually cheaper in year 1 but more expensive by year 3 when maintenance accumulates.
- Factor in risk: building carries execution risk (delays, scope creep); buying carries vendor risk (price increases, feature gaps, acquisition/shutdown).

## Pricing Model Comparison

### Per-Seat Pricing
- Predictable costs. Easy to budget. Scales linearly with team size.
- Disadvantage: penalizes growth. As the team expands, costs increase regardless of actual usage.
- Best for: tools with consistent per-user usage (IDEs, project management, communication).

### Usage-Based Pricing
- Pay for what you use. Aligns cost with value delivered.
- Disadvantage: unpredictable costs. A traffic spike can cause a surprise bill.
- Mitigate with: billing alerts, spend caps, committed use discounts.
- Best for: infrastructure (compute, storage, bandwidth), API services, and transaction-based platforms.

### Flat-Rate Pricing
- Fixed monthly/annual fee regardless of usage. Simplest to budget.
- Disadvantage: overpay at low usage, underpay (and risk throttling or overage fees) at high usage.
- Best for: small teams with predictable, moderate usage.

### Hybrid Pricing
- Base fee (flat) plus overage charges (usage-based). Combines predictability with elasticity.
- Negotiate the base tier to cover 80% of expected usage. Overage covers spikes.

## ROI Projection

- Define the investment: total cost over the analysis period (build/buy cost, infrastructure, operations).
- Define the return: quantifiable business value. Revenue increase, cost reduction, time savings, or risk reduction.
- ROI = (Net Return / Investment) x 100%. A positive ROI means the investment pays for itself.
- Time to ROI: how many months until cumulative returns exceed cumulative costs.
- Sensitivity analysis: vary key assumptions (adoption rate, cost growth, traffic growth) by +/- 20% and show how ROI changes. If ROI goes negative under realistic pessimistic assumptions, the investment is risky.

## Cost Growth Modeling

- Model cost growth as a function of the primary cost driver (users, transactions, data volume, features).
- Linear growth: cost increases proportionally with the driver. Typical for per-seat and storage costs.
- Sublinear growth: cost grows slower than the driver due to economies of scale (volume discounts, better utilization at scale). Typical for infrastructure with reserved capacity.
- Superlinear growth: cost grows faster than the driver. Warning sign. Occurs when architecture does not scale efficiently (e.g., O(n^2) query patterns, unpartitioned databases).
- Plot cost per unit (cost per user, cost per transaction) over time. If cost per unit is increasing, investigate the scaling bottleneck.
- Plan cost optimization checkpoints: when monthly spend reaches defined thresholds, trigger architecture review for cost efficiency.

## Breakeven Analysis

- Breakeven point: the usage level or time at which the investment's returns equal its costs.
- For build vs. buy: at what usage level does building become cheaper than buying per month? This is the breakeven usage.
- For migration: at what month do the savings from the new system (reduced ops cost, better performance, fewer incidents) pay back the migration cost?
- Visualize as a crossover chart: plot cumulative cost of each option over time. The crossover point is the breakeven.
- Include opportunity cost in breakeven calculations. The months spent building could have been spent on revenue-generating features.
