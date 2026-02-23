# ROI Projection, Cost Growth Modeling, and Breakeven Analysis

## When to load
Load when projecting ROI on infrastructure investments, modeling cost growth against a primary driver (users, transactions, data volume), or performing breakeven analysis for build vs. buy or migration decisions.

## ROI Projection

- Define the investment: total cost over the analysis period (build/buy cost, infrastructure, operations).
- Define the return: quantifiable business value — revenue increase, cost reduction, time savings, or risk reduction.
- ROI = (Net Return / Investment) x 100%. A positive ROI means the investment pays for itself.
- Time to ROI: how many months until cumulative returns exceed cumulative costs.
- Sensitivity analysis: vary key assumptions (adoption rate, cost growth, traffic growth) by +/- 20% and show how ROI changes. If ROI goes negative under realistic pessimistic assumptions, the investment is risky.

## Cost Growth Modeling

- Model cost growth as a function of the primary cost driver (users, transactions, data volume, features).
- **Linear growth**: cost increases proportionally with the driver. Typical for per-seat and storage costs.
- **Sublinear growth**: cost grows slower than the driver due to economies of scale (volume discounts, better utilization at scale). Typical for infrastructure with reserved capacity.
- **Superlinear growth**: cost grows faster than the driver. Warning sign. Occurs when architecture does not scale efficiently (e.g., O(n^2) query patterns, unpartitioned databases).
- Plot cost per unit (cost per user, cost per transaction) over time. If cost per unit is increasing, investigate the scaling bottleneck.
- Plan cost optimization checkpoints: when monthly spend reaches defined thresholds, trigger architecture review for cost efficiency.

## Breakeven Analysis

- Breakeven point: the usage level or time at which the investment's returns equal its costs.
- For build vs. buy: at what usage level does building become cheaper than buying per month? This is the breakeven usage.
- For migration: at what month do the savings from the new system (reduced ops cost, better performance, fewer incidents) pay back the migration cost?
- Visualize as a crossover chart: plot cumulative cost of each option over time. The crossover point is the breakeven.
- Include opportunity cost in breakeven calculations. The months spent building could have been spent on revenue-generating features.
