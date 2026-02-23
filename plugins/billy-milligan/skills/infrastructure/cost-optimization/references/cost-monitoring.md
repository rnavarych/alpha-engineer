# Cost Monitoring and FinOps

## When to load
Load when setting up cloud cost alerts, configuring budget thresholds, implementing
showback/chargeback, or establishing a FinOps practice for a team or organization.

## Budget Alerts

### AWS Budgets

```json
// AWS Budget — alert at 80% and 100% of monthly threshold
{
  "BudgetName": "production-monthly",
  "BudgetLimit": { "Amount": "5000", "Unit": "USD" },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST",
  "NotificationsWithSubscribers": [
    {
      "Notification": {
        "NotificationType": "ACTUAL",
        "ComparisonOperator": "GREATER_THAN",
        "Threshold": 80,
        "ThresholdType": "PERCENTAGE"
      },
      "Subscribers": [{ "SubscriptionType": "EMAIL", "Address": "ops@example.com" }]
    },
    {
      "Notification": {
        "NotificationType": "FORECASTED",
        "ComparisonOperator": "GREATER_THAN",
        "Threshold": 100,
        "ThresholdType": "PERCENTAGE"
      },
      "Subscribers": [{ "SubscriptionType": "EMAIL", "Address": "ops@example.com" }]
    }
  ]
}
```

```hcl
# Terraform: AWS Budget with SNS alert
resource "aws_budgets_budget" "monthly" {
  name         = "production-monthly"
  budget_type  = "COST"
  limit_amount = "5000"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_topic_arns  = [aws_sns_topic.cost_alerts.arn]
  }
}
```

### GCP Budget Alerts

```yaml
# GCP Budget via gcloud
gcloud billing budgets create \
  --billing-account=BILLING_ACCOUNT_ID \
  --display-name="Production Monthly" \
  --budget-amount=5000USD \
  --threshold-rule=percent=50 \
  --threshold-rule=percent=90 \
  --threshold-rule=percent=100,basis=forecasted-spend \
  --notifications-rule-pubsub-topic=projects/PROJECT/topics/billing-alerts
```

## Anomaly Detection

```python
# Lambda / Cloud Function: alert on daily spend spike > 20% vs 7-day average
import boto3
from datetime import datetime, timedelta

def handler(event, context):
    ce = boto3.client('ce')

    # Today's spend so far
    today = datetime.utcnow().date()
    yesterday = today - timedelta(days=1)
    week_ago = today - timedelta(days=8)

    today_cost = get_daily_cost(ce, str(yesterday), str(today))
    week_avg = get_avg_daily_cost(ce, str(week_ago), str(yesterday))

    if week_avg > 0:
        change_pct = ((today_cost - week_avg) / week_avg) * 100
        if change_pct > 20:
            send_alert(f"Cost spike: ${today_cost:.2f} today vs ${week_avg:.2f} avg ({change_pct:.1f}% increase)")
```

## Dev Environment Scheduling

```python
# Lambda: auto-stop dev/staging instances at 7PM, start at 8AM
import boto3

def handler(event, context):
    ec2 = boto3.client('ec2')
    action = event['action']  # 'start' or 'stop'

    filters = [
        {'Name': 'tag:Environment', 'Values': ['dev', 'staging']},
        {'Name': 'instance-state-name',
         'Values': ['running' if action == 'stop' else 'stopped']},
    ]
    instances = ec2.describe_instances(Filters=filters)
    ids = [i['InstanceId'] for r in instances['Reservations'] for i in r['Instances']]

    if ids:
        getattr(ec2, f'{action}_instances')(InstanceIds=ids)
    return {'action': action, 'count': len(ids)}
```

```
Savings calculation:
  24/7:                    720 hours/month
  8AM-7PM Mon-Fri:         ~195 hours/month (27% of 24/7)
  Savings:                 73% of dev compute costs

  Example: 10 x m5.large instances
    24/7 cost:   10 * $0.096 * 720 = $691/month
    Auto-stop:   10 * $0.096 * 195 = $187/month
    Monthly savings: $504
    Annual savings:  $6,048
```

## Showback and Chargeback

```
Showback: show teams what they cost, no actual billing
Chargeback: teams pay their actual cloud costs from their budget

When to use:
  Small org (<50 engineers): showback only — visibility without politics
  Mid-size (50-200):         showback + soft targets per team
  Large (200+):              chargeback — accountability at budget level

Tagging strategy for attribution:
  Required tags on all resources:
    team:        engineering | data | platform | ml
    environment: prod | staging | dev
    service:     api | worker | database | cache | cdn
    cost-center: CC-1234

  AWS tag policy to enforce:
    aws organizations create-policy --type TAG_POLICY \
      --content file://tag-policy.json
```

```sql
-- Athena query on AWS Cost and Usage Report for team showback
SELECT
  resource_tags_user_team   AS team,
  resource_tags_user_service AS service,
  SUM(line_item_unblended_cost) AS monthly_cost_usd
FROM cost_and_usage_report
WHERE
  line_item_usage_start_date >= DATE_TRUNC('month', CURRENT_DATE)
  AND resource_tags_user_environment = 'prod'
GROUP BY 1, 2
ORDER BY 3 DESC;
```

## FinOps Maturity Checklist

```
Crawl (visibility):
  [ ] All resources tagged with team, environment, service
  [ ] Budget alerts at 80% and 100% per environment
  [ ] Weekly cost report emailed to engineering leads
  [ ] Anomaly detection on daily spend

Walk (optimization):
  [ ] Dev/staging auto-stop schedules running
  [ ] Monthly unused resource audit (EBS, EIPs, LBs)
  [ ] Reserved instances or Savings Plans covering baseline compute
  [ ] CDN in front of all public content

Run (accountability):
  [ ] Showback dashboard per team updated weekly
  [ ] Cost reviewed in quarterly planning
  [ ] New service proposals include cost estimate
  [ ] On-call runbook includes "unexpected cost spike" scenario
```

## Quick reference

```
Budget alerts     : 80% actual + 100% forecasted = minimum viable alerting
Anomaly threshold : > 20% day-over-day increase = investigate
Dev auto-stop     : 73% compute savings on non-production environments
Tagging minimum   : team, environment, service on every resource
Showback → chargeback : showback first, chargeback only at 50+ engineers
Optimization patterns : see general-optimization.md
```
