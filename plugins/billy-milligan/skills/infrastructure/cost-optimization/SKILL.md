---
name: cost-optimization
description: |
  Cloud cost optimization: resource tagging strategy, rightsizing (CPU <30% = downsize),
  S3 lifecycle policies ($0.023 → $0.00099/GB), Kubernetes VPA, dev environment auto-stop,
  Reserved Instances, Spot Instances for batch jobs, cost allocation and showback.
  Use when reviewing cloud bills, planning cost reduction, setting up cost governance.
allowed-tools: Read, Grep, Glob
---

# Cost Optimization

## When to Use This Skill
- Cloud bill review and cost reduction planning
- Rightsizing over-provisioned resources
- Setting up cost governance and tagging
- S3 and object storage lifecycle management
- Dev/staging environment cost control

## Core Principles

1. **Measure before cutting** — rightsizing requires utilization data, not guesses
2. **Tag everything** — can't optimize what you can't attribute
3. **Dev/staging should sleep** — most expensive cost waste is idle non-production resources
4. **Storage lifecycle is always worth it** — S3 Glacier is 50× cheaper than Standard
5. **Right-size before Reserved Instances** — buying RI for wrong size locks in waste

---

## Patterns ✅

### Resource Tagging Strategy

```hcl
# Terraform: enforce tagging on all resources
variable "required_tags" {
  description = "Required tags for all resources"
  type = object({
    Environment = string  # prod, staging, dev
    Team        = string  # backend, frontend, platform
    Service     = string  # order-service, auth-service
    CostCenter  = string  # eng-backend, eng-platform
    Owner       = string  # email of team lead
  })
}

resource "aws_instance" "app_server" {
  # ...
  tags = merge(var.required_tags, {
    Name = "${var.required_tags.Service}-${var.required_tags.Environment}"
  })
}

# AWS Config rule: non-compliant if missing required tags
resource "aws_config_config_rule" "required_tags" {
  name = "required-tags"
  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }
  input_parameters = jsonencode({
    tag1Key   = "Environment"
    tag2Key   = "Team"
    tag3Key   = "Service"
    tag4Key   = "CostCenter"
  })
}
```

### Rightsizing (EC2 / ECS / Kubernetes)

```
Rightsizing thresholds:
  CPU utilization < 30% (7-day average) → downsize by one tier
  CPU utilization > 80% (7-day average) → upsize or scale horizontally
  Memory utilization < 40% → downsize
  Memory utilization > 85% → risk of OOM, upsize

EC2 rightsizing savings examples:
  m5.xlarge (4vCPU/16GB, $0.192/hr)  → m5.large (2vCPU/8GB, $0.096/hr)
  Savings: 50% if CPU < 30% of 4 vCPU
  Annual: $1,684 → $842 (saving $842/year per instance)
```

```bash
# AWS CLI: find underutilized EC2 instances
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-1234567890abcdef0 \
  --start-time 2024-01-15T00:00:00Z \
  --end-time 2024-01-22T00:00:00Z \
  --period 86400 \
  --statistics Average \
  --query 'Datapoints[*].Average' \
  --output text
# If all values < 30 → rightsizing candidate
```

```yaml
# Kubernetes VPA (Vertical Pod Autoscaler)
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: order-service-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: order-service
  updatePolicy:
    updateMode: "Off"  # Recommendation-only mode (don't auto-apply in prod)
  resourcePolicy:
    containerPolicies:
      - containerName: app
        minAllowed:
          cpu: 100m
          memory: 128Mi
        maxAllowed:
          cpu: 2
          memory: 2Gi

# After running for 7 days, check recommendations:
# kubectl describe vpa order-service-vpa
# Look for: spec.recommendation.containerRecommendations.target
```

### S3 Lifecycle Policies

```
AWS S3 Storage Classes and Prices (us-east-1, approximate):
  Standard:                   $0.023/GB/month
  Standard-IA (Infrequent):   $0.0125/GB/month  (54% savings)
  Glacier Instant Retrieval:  $0.004/GB/month    (83% savings)
  Glacier Flexible:           $0.0036/GB/month   (84% savings)
  Glacier Deep Archive:       $0.00099/GB/month  (96% savings)

Rule: Standard → Standard-IA after 30 days → Glacier after 90 days
      For logs: delete after 365 days (or 7 years for compliance)
```

```hcl
# Terraform: S3 lifecycle policy
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "logs-lifecycle"
    status = "Enabled"

    # Transition to IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Transition to Glacier after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Delete after 365 days (adjust for compliance)
    expiration {
      days = 365
    }

    # Clean up incomplete multipart uploads (hidden cost)
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
```

**Savings example**: 10TB of logs/month
- Without lifecycle: 10TB × $0.023 × 12 months = $2,760/year
- With lifecycle (mostly Glacier): ~10TB × $0.004 = $480/year
- Savings: ~$2,280/year for one S3 bucket

### Dev/Staging Environment Auto-Stop

```python
# Lambda function: stop non-production EC2 at 7PM, start at 8AM
import boto3
from datetime import datetime

ec2 = boto3.client('ec2')

def handler(event, context):
    action = event['action']  # 'start' or 'stop'

    # Find instances tagged Environment=dev or Environment=staging
    response = ec2.describe_instances(
        Filters=[
            {'Name': 'tag:Environment', 'Values': ['dev', 'staging']},
            {'Name': 'instance-state-name', 'Values': ['running' if action == 'stop' else 'stopped']},
        ]
    )

    instance_ids = [
        i['InstanceId']
        for r in response['Reservations']
        for i in r['Instances']
    ]

    if not instance_ids:
        return {'stopped': 0}

    if action == 'stop':
        ec2.stop_instances(InstanceIds=instance_ids)
    else:
        ec2.start_instances(InstanceIds=instance_ids)

    return {'action': action, 'count': len(instance_ids), 'instances': instance_ids}
```

```yaml
# EventBridge schedule (Terraform):
# Stop at 7PM UTC Mon-Fri: cron(0 19 ? * MON-FRI *)
# Start at 8AM UTC Mon-Fri: cron(0 8 ? * MON-FRI *)
```

**Savings**: Dev instances run 9h/day, 5 days/week instead of 24/7
- 24/7: 720 hours/month
- 8AM-7PM Mon-Fri: 45 hours/week = ~195 hours/month
- Savings: 73% of dev compute costs

### Reserved Instances and Savings Plans

```
When to buy Reserved Instances:
  - Resource has been running > 3 months (stable pattern)
  - CPU utilization > 60% consistently
  - Same instance type for > 12 months expected

RI vs On-Demand savings:
  m5.large (1-year no upfront): $0.096/hr → $0.062/hr (35% savings)
  m5.large (3-year all upfront): $0.096/hr → $0.044/hr (54% savings)

Never buy RI for:
  - Dev/staging (they should auto-stop)
  - Instances under evaluation (wrong size)
  - Services expecting major architecture changes

Compute Savings Plans (more flexible than RI):
  - Applies to any EC2, Fargate, or Lambda
  - Commit to $/hour spend, not specific instance type
  - 30-60% savings with 1-year commitment
```

---

## Anti-Patterns ❌

### Buying Reserved Instances Without Rightsizing First
**What it is**: Buying 1-year RI for current instances without checking utilization.
**What breaks**: Locked into wrong size for 1 year. Paying for capacity you're not using. 20% CPU utilization on an instance you're paying full price for.
**Fix**: Rightsize first (takes 2-4 weeks of data), THEN buy RI for the correctly-sized instances.

### No Resource Tagging
**What it is**: Cloud resources with no tags, or inconsistent tags.
**What breaks**: Can't determine which team/service is responsible for which cost. Unable to do cost allocation or chargeback. Unknown resources (potential zombie resources).
**Fix**: Required tags enforced via AWS Config or policy-as-code.

### Dev/Staging Running 24/7
**What it is**: Non-production environments running around the clock like production.
**Cost**: 15 dev instances × $0.096/hr × 8,760 hr/year = $12,614/year
With auto-stop: $12,614 × 27% = $3,406/year (saving $9,208/year)
**Fix**: EventBridge schedule + Lambda auto-stop. Engineers start instances on demand.

### Forgetting Egress Costs
**What it is**: Only looking at compute and storage costs, ignoring data transfer.
**What breaks**: S3 to internet egress: $0.09/GB. Large application serving files from S3 directly: $90/TB.
**Fix**: CloudFront in front of S3 ($0.0085/GB after first 10TB). For high-volume: CloudFront + S3 Transfer Acceleration.

---

## Quick Reference

```
Rightsize trigger: CPU < 30% (7-day avg) → downsize
S3 lifecycle: Standard → IA after 30d → Glacier after 90d → delete after 365d
S3 savings: Standard ($0.023) vs Deep Archive ($0.00099) = 96% savings
Dev auto-stop: 73% savings (9h/day vs 24h/day)
RI timing: rightsize first, then commit to RI for stable workloads
Tagging: Environment, Team, Service, CostCenter — enforce in policy
Egress: CloudFront for public content (10× cheaper than direct S3)
```
