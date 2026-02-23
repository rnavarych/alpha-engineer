# General Cost Optimization

## When to load
Load when reducing cloud bills through caching, CDN configuration, autoscaling tuning, or
identifying and eliminating unused resources.

## Caching to Reduce Compute

```
Cache layer hierarchy:
  Browser cache (client)     -> 0 cost, fastest
  CDN cache (edge)           -> low cost, global
  Application cache (Redis)  -> medium cost, per-region
  Database query cache       -> varies, per-instance

Impact by layer:
  CDN:           offloads 60-90% of static content requests
  Redis/Memcache: reduces DB queries by 80-95% for read-heavy workloads
  HTTP cache:     eliminates redundant API calls entirely

Cost math:
  Without cache: 10M requests/day x $0.0001/request = $1,000/day
  With CDN (90% hit): 1M origin requests/day = $100/day + $50/day CDN = $150/day
  Savings: 85%
```

```typescript
// Redis cache with TTL
async function getUser(userId: string): Promise<User> {
  const cacheKey = `user:${userId}`;
  const cached = await redis.get(cacheKey);
  if (cached) return JSON.parse(cached);

  const user = await db.query('SELECT * FROM users WHERE id = $1', [userId]);
  await redis.set(cacheKey, JSON.stringify(user), 'EX', 300); // 5 min TTL
  return user;
}
```

## CDN for Egress Optimization

```
Direct serving costs:
  S3 to internet:        $0.09/GB
  GCS to internet:       $0.12/GB
  EC2 to internet:       $0.09/GB

CDN costs:
  CloudFront:            $0.085/GB (first 10TB), lower after
  Cloud CDN:             $0.02-0.08/GB
  Fastly:                $0.08/GB

Savings: 50-80% on egress for cacheable content

What to cache via CDN:
  - Static assets (JS, CSS, images, fonts)
  - API responses with Cache-Control headers
  - Video/media files
  - Publicly accessible documents
```

```yaml
# CloudFront + S3 (Terraform)
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.assets.bucket_regional_domain_name
    origin_id   = "S3Assets"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3Assets"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true  # Gzip/Brotli = smaller transfer
    default_ttl            = 86400 # 24 hours
    max_ttl                = 604800 # 7 days
  }
}
```

## Autoscaling Tuning

```
Common autoscaling mistakes and fixes:

Problem: Scale-up too slow (traffic spike causes errors)
  Fix: Lower scale-up threshold (60% -> 50% CPU)
  Fix: Reduce stabilization window (300s -> 60s for scale-up)
  Fix: Increase maxSurge in scale-up policy

Problem: Scale-down too aggressive (constant scale up/down flapping)
  Fix: Increase scale-down stabilization (60s -> 300s)
  Fix: Scale down by percentage (10%) not absolute count
  Fix: Add cooldown period between scale events

Problem: Over-provisioned minimum (paying for idle capacity)
  Fix: Analyze minimum traffic patterns
  Fix: Use time-based scaling for predictable patterns
  Fix: Lower minReplicas during off-peak hours
```

```yaml
# HPA with tuned behavior
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
spec:
  minReplicas: 3
  maxReplicas: 50
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 60  # Target 60% for headroom
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60   # React quickly to load
      policies:
        - type: Pods
          value: 4
          periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300  # Wait 5 min before scaling down
      policies:
        - type: Percent
          value: 10
          periodSeconds: 60
```

## Unused Resource Detection

```bash
# AWS: find unattached EBS volumes
aws ec2 describe-volumes \
  --filters Name=status,Values=available \
  --query 'Volumes[*].{ID:VolumeId,Size:Size,Created:CreateTime}' \
  --output table

# AWS: find unused Elastic IPs
aws ec2 describe-addresses \
  --query 'Addresses[?AssociationId==null].{IP:PublicIp,AllocId:AllocationId}' \
  --output table

# AWS: find idle load balancers (0 healthy targets)
aws elbv2 describe-target-health \
  --target-group-arn <arn> \
  --query 'TargetHealthDescriptions[?TargetHealth.State!=`healthy`]'
```

```
Regular cost audit checklist (monthly):
  [ ] Unattached EBS volumes (cost: $0.10/GB/month)
  [ ] Unused Elastic IPs ($3.60/month each)
  [ ] Idle load balancers ($16-23/month each)
  [ ] Old snapshots beyond retention policy
  [ ] Stopped instances with attached EBS (still paying for storage)
  [ ] Unused NAT Gateways ($32/month + data processing)
  [ ] Oversized RDS instances
  [ ] Unused ECR images (storage costs)
```

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| No caching layer | Add Redis/CDN; 80-95% query reduction |
| Serving static files from app server | Use CDN (CloudFront, Cloud CDN) |
| Autoscaling without tuning | Tune thresholds and stabilization windows |
| Never auditing unused resources | Monthly audit of idle resources |
| No resource tagging | Tag everything for cost attribution |

## Quick Reference

- CDN egress vs direct: **50-80%** savings on transfer
- Redis cache hit: **80-95%** fewer DB queries
- Unused EBS volume: **$0.10/GB/month** waste
- Unused Elastic IP: **$3.60/month** waste
- Audit cadence: **monthly** for unused resources
- Autoscaling: target **60%** CPU, scale down stabilization **300s**
- Cost alerting and budgets: see cost-monitoring.md
