# Scaling and Load Balancing

## When to load
Load when configuring auto-scaling policies, choosing load balancing algorithms, implementing circuit breakers, or setting rate limits.

## Load Balancing Algorithms

| Algorithm | How It Works | Best For | Drawbacks |
|-----------|-------------|----------|-----------|
| **Round Robin** | Rotates through servers sequentially | Homogeneous servers, equal request cost | Ignores server load |
| **Weighted Round Robin** | Round robin with server weights | Heterogeneous servers (different CPU/RAM) | Static weights |
| **Least Connections** | Routes to server with fewest active connections | Long-lived connections, variable request duration | May burst to new servers |
| **Least Response Time** | Fastest response + fewest connections | Latency-sensitive applications | Requires active health monitoring |
| **IP Hash** | Hash client IP to consistent server | Session persistence without cookies | Uneven distribution behind NAT |
| **Consistent Hashing** | Hash ring with virtual nodes | Cache servers, stateful services | More complex |
| **Random Two Choices** | Pick 2 random servers, choose least loaded | Simple, effective at scale | Slightly less optimal than least-conn |

## Health Checks
- **HTTP health check**: `GET /health` -> 200 OK (every 10-30s)
- **Deep health check**: `GET /health/ready` -> verifies database, cache, downstream dependencies
- **Liveness vs. readiness**: Liveness = process alive, readiness = able to serve traffic
- **Thresholds**: Mark unhealthy after 3 consecutive failures, healthy after 2 successes

## Circuit Breaker Pattern
```
States: CLOSED -> OPEN -> HALF-OPEN -> CLOSED
- CLOSED: Normal operation, count failures
- OPEN: Fail fast (no requests to downstream), wait timeout (30-60s)
- HALF-OPEN: Allow limited requests; if successful -> CLOSED, if failed -> OPEN

Libraries:
- Node.js: opossum
- Java: Resilience4j, Hystrix (deprecated)
- Go: sony/gobreaker, afex/hystrix-go
- Python: pybreaker
- .NET: Polly
```

## Rate Limiting
- **Token bucket**: Smooth rate, allows bursts up to bucket size. Best for APIs.
- **Sliding window**: Precise rate limiting, no burst allowance. Best for strict limits.
- **Fixed window**: Simple but allows 2x burst at window boundaries.
- **Implementation**: Redis (`INCR` + `EXPIRE`), Nginx (`limit_req`), API Gateway (AWS, Kong, Envoy)

## Auto-Scaling

### Metrics-Based Scaling
- **CPU utilization**: Target 60-70%. Most common. Lagging indicator.
- **Request count**: Requests per target. Good for web services.
- **Queue depth**: Messages in queue. Good for worker services.
- **Custom metrics**: Business-specific (active users, processing jobs)

### Kubernetes HPA
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-server
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-server
  minReplicas: 3
  maxReplicas: 50
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
        - type: Percent
          value: 100
          periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 10
          periodSeconds: 60
  metrics:
    - type: Resource
      resource:
        name: cpu
        target: { type: Utilization, averageUtilization: 65 }
```

### KEDA (Event-Driven Autoscaling)
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
spec:
  minReplicaCount: 1
  maxReplicaCount: 50
  triggers:
    - type: rabbitmq
      metadata:
        queueName: orders
        queueLength: "10"  # 1 pod per 10 messages
    - type: prometheus
      metadata:
        query: sum(rate(http_requests_total{service="order-processor"}[1m]))
        threshold: "500"
```

### AWS Auto Scaling (Target Tracking)
```json
{
  "TargetTrackingScalingPolicyConfiguration": {
    "TargetValue": 65.0,
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ASGAverageCPUUtilization"
    },
    "ScaleInCooldown": 300,
    "ScaleOutCooldown": 60
  }
}
```

## Async Patterns by Language

| Language | Pattern | Library/Feature | Use Case |
|----------|---------|-----------------|----------|
| Node.js | Event loop, async/await | Built-in, `p-limit`, `p-queue` | I/O operations, API calls |
| Node.js | Worker threads | `worker_threads`, `piscina` | CPU-intensive: image processing, crypto |
| Python | asyncio | `asyncio`, `aiohttp`, `httpx[async]` | I/O-bound: HTTP, database, file |
| Python | Multiprocessing | `concurrent.futures` | CPU-bound: data processing, ML inference |
| Java | Virtual threads (Loom) | `Thread.ofVirtual()` (Java 21+) | High-concurrency I/O |
| Go | Goroutines + channels | Built-in, `errgroup`, `semaphore` | Concurrent I/O and CPU work |
| .NET | async/await, Task | `Task`, `ValueTask`, `Channel<T>` | I/O-bound work, producer-consumer |
