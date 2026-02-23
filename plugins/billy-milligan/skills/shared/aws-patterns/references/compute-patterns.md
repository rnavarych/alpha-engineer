# AWS Compute Patterns

## When to load
Load when choosing between Lambda, ECS, EKS, or EC2 for workloads.

## Compute Decision Tree

```
Is your workload event-driven or short-lived (< 15 min)?
  │
  ├─ YES → AWS Lambda
  │         ✅ Zero ops, auto-scale to 0, pay per invocation
  │         ❌ Cold starts (100ms-2s), 15min timeout, 10GB RAM max
  │
  └─ NO → Do you need containers?
          │
          ├─ YES → Do you need full Kubernetes?
          │        │
          │        ├─ YES → EKS (Elastic Kubernetes Service)
          │        │         ✅ Full K8s API, ecosystem, portability
          │        │         ❌ Complex ops, control plane cost ($73/mo)
          │        │
          │        └─ NO → ECS Fargate
          │                 ✅ Serverless containers, no node management
          │                 ❌ ~20% more expensive than EC2 launch type
          │
          └─ NO → EC2
                   ✅ Full control, GPU, persistent state
                   ❌ Manual scaling, patching, capacity planning
```

## Lambda Patterns

```typescript
// API Gateway + Lambda
export const handler = async (event: APIGatewayProxyEvent) => {
  const body = JSON.parse(event.body || '{}');

  try {
    const result = await processRequest(body);
    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(result),
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Internal server error' }),
    };
  }
};

// Cold start optimization
// 1. Initialize outside handler (reused across invocations)
const dbPool = createPool(process.env.DATABASE_URL);

// 2. Use Provisioned Concurrency for latency-sensitive
// 3. Minimize package size (bundle with esbuild)
// 4. Use ARM64 (Graviton2) — 20% cheaper, 34% better perf
```

## ECS Fargate Task Definition

```json
{
  "family": "api-server",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "api-server",
      "image": "123456789.dkr.ecr.us-east-1.amazonaws.com/api:v1.2.0",
      "portMappings": [{ "containerPort": 3000, "protocol": "tcp" }],
      "healthCheck": {
        "command": ["CMD-SHELL", "wget -qO- http://localhost:3000/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3
      },
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/api-server",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "secrets": [
        {
          "name": "DATABASE_URL",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:123456789:secret:db-url"
        }
      ]
    }
  ]
}
```

## Cost Comparison (typical web API, 1M requests/month)

```
Lambda:       ~$5-20/mo   (pay per invocation, great for variable load)
Fargate:      ~$30-80/mo  (pay for running tasks, good for steady load)
ECS on EC2:   ~$25-60/mo  (cheaper compute, more ops overhead)
EC2 Reserved: ~$15-40/mo  (cheapest, 1-year commitment, most ops)

Break-even: Lambda cheaper below ~1M requests/day
            Fargate cheaper for always-on services
            EC2 Reserved cheapest for predictable workloads
```

## Anti-patterns
- Lambda for long-running processes (>15min) → use Step Functions or ECS
- EC2 without auto-scaling groups → manual scaling, wasted capacity
- EKS for simple workloads → over-engineering, use Fargate
- Fargate without Service Auto Scaling → paying for idle capacity
- Lambda without VPC when no VPC needed → adds cold start latency

## Quick reference
```
Lambda: event-driven, < 15min, auto-scale to 0, cold starts
Fargate: serverless containers, no nodes, steady workloads
ECS on EC2: containers on managed instances, spot instances
EKS: full Kubernetes, complex workloads, portability
EC2: full control, GPU, persistent state, legacy apps
Graviton (ARM64): 20% cheaper, use for Lambda + Fargate
Spot instances: 60-90% discount for fault-tolerant workloads
Right-sizing: start small, monitor, adjust (Compute Optimizer)
```
