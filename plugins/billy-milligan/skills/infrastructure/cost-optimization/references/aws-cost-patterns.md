# AWS Cost Patterns

## Reserved Instances

```
When to buy:
  - Resource running stable for 3+ months
  - CPU utilization > 60% consistently
  - Same instance type expected for 12+ months

Pricing (m5.large, us-east-1):
  On-Demand:              $0.096/hr  ($70/month)
  1-year No Upfront:      $0.062/hr  ($45/month, 35% savings)
  1-year All Upfront:     $0.057/hr  ($41/month, 41% savings)
  3-year All Upfront:     $0.044/hr  ($32/month, 54% savings)

Never buy RI for:
  - Dev/staging (they should auto-stop)
  - Instances under evaluation (wrong size)
  - Services expecting major architecture changes
```

## Spot Instances

```
Savings: up to 90% vs On-Demand

Best for:
  - Batch processing, data pipelines
  - CI/CD build runners
  - Stateless worker pools
  - Big data (EMR, Spark)

Not suitable for:
  - Databases (interruption = downtime)
  - Stateful services without checkpointing
  - Services requiring consistent availability

Strategies:
  - Diversify across instance types and AZs
  - Use Spot Fleet or ASG mixed instances
  - Implement graceful handling of 2-minute interruption notice
```

```bash
# Check current Spot pricing
aws ec2 describe-spot-price-history \
  --instance-types m5.large m5.xlarge c5.large \
  --product-descriptions "Linux/UNIX" \
  --start-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --query 'SpotPriceHistory[*].{Type:InstanceType,AZ:AvailabilityZone,Price:SpotPrice}' \
  --output table
```

## Savings Plans

```
More flexible than Reserved Instances:
  - Compute Savings Plan: applies to any EC2, Fargate, Lambda
  - EC2 Instance Savings Plan: specific instance family, any size
  - Commit to $/hour spend, not specific instance

Savings:
  1-year: 30-40%
  3-year: 50-60%

Best approach:
  1. Review Cost Explorer "Savings Plans recommendations"
  2. Start with Compute Savings Plan (most flexible)
  3. Cover baseline spend only (use On-Demand for peaks)
```

## Right-Sizing

```
Thresholds:
  CPU < 30% (7-day average)   -> downsize
  CPU > 80% (7-day average)   -> upsize or scale out
  Memory < 40%                -> downsize
  Memory > 85%                -> upsize (OOM risk)

Process:
  1. Enable CloudWatch detailed monitoring (1-minute intervals)
  2. Collect 7-14 days of data
  3. Review with AWS Compute Optimizer or Cost Explorer
  4. Downsize by one tier (e.g., xlarge -> large)
  5. Monitor for 7 days after resize
  6. Then consider RI purchase for stable workloads
```

```bash
# Find underutilized EC2 instances
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-0123456789abcdef \
  --start-time $(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 86400 \
  --statistics Average
```

## S3 Storage Tiers

```
Tier                        $/GB/month    vs Standard
Standard                    $0.023        baseline
Standard-IA                 $0.0125       46% cheaper
One Zone-IA                 $0.010        57% cheaper
Glacier Instant Retrieval   $0.004        83% cheaper
Glacier Flexible            $0.0036       84% cheaper
Glacier Deep Archive         $0.00099      96% cheaper

Lifecycle rules:
  Active data:    Standard (0-30 days)
  Infrequent:     Standard-IA (30-90 days)
  Archive:        Glacier Instant (90-365 days)
  Deep archive:   Glacier Deep (365+ days)
  Delete:         Expiration based on retention policy

Hidden costs:
  - Incomplete multipart uploads (abort after 7 days)
  - S3 request costs ($0.005 per 1000 GET requests)
  - Egress: $0.09/GB to internet (use CloudFront)
```

```hcl
# Terraform: S3 lifecycle policy
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    id     = "lifecycle"
    status = "Enabled"
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    expiration {
      days = 365
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
```

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Buying RI before right-sizing | Right-size first (2-4 weeks data), then commit |
| Dev/staging running 24/7 | Auto-stop: 8AM-7PM weekdays saves 73% |
| No S3 lifecycle rules | Standard -> IA -> Glacier saves 80%+ |
| Ignoring egress costs | CloudFront: $0.0085/GB vs S3 direct: $0.09/GB |
| Unused EBS volumes | Audit monthly; delete unattached volumes |
| Oversized RDS instances | Use Performance Insights to right-size |

## Quick Reference

- Spot savings: up to **90%** (batch workloads)
- RI savings: **35-54%** (1-3 year commitment)
- Savings Plans: **30-60%** (flexible across EC2/Fargate/Lambda)
- Right-sizing trigger: CPU **< 30%** average over 7 days
- S3 lifecycle: Standard -> IA (30d) -> Glacier (90d) -> Delete (365d)
- Egress: CloudFront is **10x cheaper** than direct S3
- Dev auto-stop: saves **73%** of compute costs
