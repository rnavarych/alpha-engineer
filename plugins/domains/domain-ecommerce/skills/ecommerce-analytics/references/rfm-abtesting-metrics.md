# RFM Segmentation, A/B Testing, and Key Metrics

## When to load
Load when building RFM customer segmentation, designing or analyzing A/B tests, or setting up an e-commerce metrics dashboard.

## RFM Segmentation

### Dimensions
- **Recency**: how recently the customer made a purchase (days since last order).
- **Frequency**: how often the customer purchases (total order count in a period).
- **Monetary**: how much the customer spends (total revenue in a period).

### Scoring
- Score each dimension 1-5 (quintiles). R=5, F=5, M=5 = top customer.
- Segments: Champions (high R/F/M), Loyal (high F), At Risk (low R, high F/M), Lost (low R/F/M).

### Actions per Segment
- **Champions**: exclusive offers, ask for reviews, enroll in referral programs.
- **At Risk**: win-back campaigns with discounts or personalized recommendations.
- **New Customers**: onboarding emails and first-purchase incentives.
- **Lost**: aggressive reactivation offers; suppress from regular marketing to reduce costs.

## A/B Test Analysis

### Statistical Significance
- Define significance level (alpha = 0.05) and minimum detectable effect before starting.
- Calculate required sample size from baseline conversion rate and expected lift.
- Two-proportion z-test or chi-squared test for conversion rate comparisons.
- Do not peek before reaching required sample size (or use sequential testing methods).

### Revenue-Based Tests
- Compare average revenue per visitor, not just conversion rate — captures order value differences.
- t-test or Mann-Whitney U for revenue comparisons.
- Watch for outlier orders that skew results; consider winsorizing extreme values.

### Reporting
- Report results with confidence intervals, not just p-values.
- Calculate expected annual revenue impact of the winning variant.
- Document test hypothesis, setup, duration, sample size, and outcome for organizational learning.

## Key Metrics Dashboard

### Core Metrics
- **Average Order Value (AOV)**: total revenue / number of orders.
- **Conversion Rate**: orders / sessions (or unique visitors).
- **Cart Abandonment Rate**: (carts created - orders completed) / carts created.
- **Repeat Purchase Rate**: customers with 2+ orders / total customers.
- **Revenue per Visitor (RPV)**: total revenue / unique visitors.

### Operational Metrics
- **Orders per day/week/month** with trend lines.
- **Fulfillment time**: average time from order to shipment.
- **Return rate**: returned orders / total orders.
- **Customer acquisition cost (CAC)**: marketing spend / new customers acquired.

### Monitoring
- Real-time dashboards for daily operations (orders, revenue, stock levels).
- Alerts for anomalies: sudden conversion rate drops, cart abandonment spike, payment failure rate increase.
- Weekly stakeholder review; monthly deep-dive into cohort and CLV reports.
