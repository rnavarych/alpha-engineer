# Horizontal Scaling

## When to load
Load when discussing stateless services, load balancing strategies, session affinity, autoscaling, or scaling beyond a single instance.

## Patterns

### Stateless service design
```typescript
// Stateless: no in-process state between requests
// All shared state lives in external stores

// BAD: in-memory state (dies with instance)
const sessions = new Map<string, Session>(); // lost on restart

// GOOD: external state store
async function getSession(sessionId: string): Promise<Session> {
  return JSON.parse(await redis.get(`session:${sessionId}`));
}

// Stateless checklist:
// - Sessions in Redis/DB, not in-memory
// - File uploads to S3/GCS, not local disk
// - Cache in Redis, not in-process (or use L1+L2 pattern)
// - WebSocket state in Redis pub/sub for cross-instance delivery
// - Scheduled jobs in distributed scheduler (not node-cron)
```

### Load balancing strategies
```nginx
# Round-robin (default, simplest)
upstream backend {
  server 10.0.0.1:3000;
  server 10.0.0.2:3000;
  server 10.0.0.3:3000;
}

# Least connections (best for varying request duration)
upstream backend {
  least_conn;
  server 10.0.0.1:3000;
  server 10.0.0.2:3000;
  server 10.0.0.3:3000;
}

# IP hash (sticky sessions without cookies)
upstream backend {
  ip_hash;
  server 10.0.0.1:3000;
  server 10.0.0.2:3000;
}

# Health checks
upstream backend {
  server 10.0.0.1:3000 max_fails=3 fail_timeout=30s;
  server 10.0.0.2:3000 max_fails=3 fail_timeout=30s;
  server 10.0.0.3:3000 backup;  # only when others fail
}
```

| Algorithm | Use case | Trade-off |
|-----------|----------|-----------|
| Round-robin | Uniform request cost | Uneven load if requests vary |
| Least connections | Variable request duration | Slightly more overhead |
| IP hash | Need sticky sessions | Uneven distribution with NAT |
| Random with 2 choices | Large clusters | Good balance, low overhead |

### Session affinity (when unavoidable)
```yaml
# Kubernetes: cookie-based session affinity
apiVersion: v1
kind: Service
metadata:
  name: web-app
spec:
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 600  # 10 minutes

# ALB sticky sessions
resource "aws_lb_target_group" "app" {
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 600
    enabled         = true
  }
}
```
Prefer stateless design. Use affinity only for WebSocket or long-polling connections.

### Autoscaling
```yaml
# Kubernetes HPA: scale on CPU (default threshold: 70%)
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 2        # always at least 2 for HA
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70   # scale up at 70% CPU
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60   # wait 1min before scaling up more
      policies:
        - type: Percent
          value: 50           # add up to 50% more pods
          periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300  # wait 5min before scaling down
      policies:
        - type: Pods
          value: 1            # remove 1 pod at a time
          periodSeconds: 120
```

```yaml
# AWS Auto Scaling Group
resource "aws_autoscaling_policy" "cpu_policy" {
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# Custom metric autoscaling (e.g., queue depth)
resource "aws_autoscaling_policy" "queue_policy" {
  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    customized_metric_specification {
      metric_name = "ApproximateNumberOfMessagesVisible"
      namespace   = "AWS/SQS"
      statistic   = "Average"
    }
    target_value = 10.0  # target: 10 messages per instance
  }
}
```

### Graceful shutdown
```typescript
// Handle SIGTERM for zero-downtime scaling
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, starting graceful shutdown');

  // 1. Stop accepting new connections
  server.close();

  // 2. Finish in-flight requests (30s timeout)
  const timeout = setTimeout(() => process.exit(1), 30000);

  // 3. Close database connections
  await db.end();
  await redis.quit();

  clearTimeout(timeout);
  process.exit(0);
});

// Kubernetes: set terminationGracePeriodSeconds: 30
// ALB: set deregistration_delay: 30
```

## Anti-patterns
- In-process state without external store -> lost on restart/scale
- Autoscaling on memory without leak detection -> keeps adding instances
- No minimum replicas (min=1) -> single point of failure
- Scaling down too aggressively -> thrashing (scale up/down repeatedly)
- No graceful shutdown -> dropped requests during deploy

## Decision criteria
- **Round-robin**: default, equal-cost requests
- **Least connections**: requests with variable processing time (file uploads, DB queries)
- **CPU autoscaling at 70%**: safe default for compute-bound workloads
- **Custom metric scaling**: queue depth, request latency, business metrics
- **Min replicas = 2**: minimum for high availability

## Quick reference
```
Stateless: sessions in Redis, files in S3, cache in Redis
Load balancing: least-connections for variable workloads
Autoscale trigger: CPU 70%, memory 80%, or custom metric
Min replicas: 2 (HA), scale up by 50%, scale down by 1
Graceful shutdown: SIGTERM handler, 30s drain, close connections
Scale-up stabilization: 60s, scale-down: 300s (prevent thrashing)
Health check: /health endpoint, 3 failures = unhealthy
```
