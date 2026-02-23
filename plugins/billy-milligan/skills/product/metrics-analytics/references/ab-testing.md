# A/B Testing

## When to load
Load when designing experiments: sample size, significance, common pitfalls.

## Sample Size Calculation

```
Required sample size per variant:
  n = (Z² × p × (1-p)) / E²

Where:
  Z = 1.96 (95% confidence)
  p = baseline conversion rate
  E = minimum detectable effect (MDE)

Example:
  Baseline conversion: 5% (p = 0.05)
  Want to detect: 10% relative improvement (5% → 5.5%)
  MDE = 0.005 (absolute)
  n = (1.96² × 0.05 × 0.95) / 0.005² = 7,300 per variant
  Total: ~14,600 visitors needed

Quick estimates (95% confidence, 80% power):
  5% baseline, 10% relative MDE:  ~30,000 per variant
  5% baseline, 20% relative MDE:  ~8,000 per variant
  10% baseline, 10% relative MDE: ~15,000 per variant
  10% baseline, 20% relative MDE: ~4,000 per variant
```

## Test Design

```
1. Define hypothesis: "Changing CTA from 'Sign Up' to 'Start Free'
   will increase signup rate by 15%"

2. Choose primary metric: signup_completed (not clicks)

3. Choose guardrail metrics: page load time, error rate, revenue

4. Calculate sample size → determine test duration
   Daily traffic: 5,000 visitors
   Required per variant: 8,000
   Minimum duration: 4 days (ideally run full weeks to avoid day-of-week bias)

5. Run test for FULL duration — never peek and stop early

6. Analyze: is p-value < 0.05? Is effect size meaningful?
```

## Statistical Significance

```
p-value < 0.05: statistically significant at 95% confidence
  → "There is less than 5% probability this result is due to chance"

BUT: statistical significance ≠ practical significance
  → A 0.01% lift with p < 0.05 is real but not worth implementing

Always check:
  1. p-value < 0.05 (significance)
  2. Confidence interval doesn't cross 0
  3. Effect size is practically meaningful (worth the complexity)
  4. Guardrail metrics not degraded
```

## Common Pitfalls

```
1. Peeking: checking results daily and stopping when significant
   → Inflates false positive rate from 5% to 30%+
   Fix: pre-calculate duration, run for full period

2. Multiple comparisons: testing 5 variants, one is "significant"
   → Expected by chance with 5 comparisons
   Fix: Bonferroni correction (0.05/n) or sequential testing

3. Small sample: declaring winner after 100 visitors
   → High variance, unreliable results
   Fix: calculate required sample size BEFORE starting

4. Survivorship bias: only measuring users who completed the flow
   → Ignoring users who dropped off
   Fix: intent-to-treat analysis (count all assigned users)
```

## Anti-patterns
- Stopping test when result "looks good" → peeking bias
- Running test for < 1 full week → day-of-week variation
- Multiple metrics without correction → false discovery
- No guardrail metrics → winning variant degrades other metrics

## Quick reference
```
Sample size: calculate BEFORE starting, not after
Duration: minimum 1 full week, ideally 2
Significance: p < 0.05 AND meaningful effect size
No peeking: run for planned duration regardless of results
Guardrails: monitor page speed, error rate, revenue
One primary metric per test
Multiple variants: Bonferroni correction (α/n)
Sequential testing: allows early stopping with valid statistics
```
