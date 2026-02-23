# Serverless Containers

## Cloud Run (GCP)

```yaml
# service.yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: myapp
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/minScale: '0'   # Scale to zero
        autoscaling.knative.dev/maxScale: '100'
        run.googleapis.com/cpu-throttling: 'false'
    spec:
      containerConcurrency: 80
      containers:
        - image: gcr.io/project/myapp:latest
          ports:
            - containerPort: 8080
          resources:
            limits:
              cpu: '2'
              memory: 1Gi
          startupProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 0
            periodSeconds: 1
            failureThreshold: 30
```

```bash
# Deploy
gcloud run deploy myapp --image gcr.io/project/myapp:latest \
  --region us-central1 --allow-unauthenticated \
  --min-instances 0 --max-instances 100 \
  --memory 1Gi --cpu 2
```

Pricing: per-request + per-second of CPU/memory. Free tier: 2M requests/month.

## AWS Fargate

```json
{
  "family": "myapp",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "containerDefinitions": [{
    "name": "app",
    "image": "123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:latest",
    "portMappings": [{ "containerPort": 3000 }],
    "healthCheck": {
      "command": ["CMD-SHELL", "curl -f http://localhost:3000/health || exit 1"],
      "interval": 30,
      "timeout": 5,
      "retries": 3,
      "startPeriod": 60
    },
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/myapp",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }]
}
```

Pricing: per-second of vCPU + memory. No free tier for Fargate.

## Lambda Containers

```dockerfile
FROM public.ecr.aws/lambda/nodejs:20
COPY dist/ ${LAMBDA_TASK_ROOT}/
CMD ["index.handler"]
```

Constraints: 15 min max execution, 10 GB max image, 10 GB ephemeral storage. Best for event-driven, short-lived tasks.

## Decision Criteria

| Factor | Cloud Run | Fargate | Lambda Container | Kubernetes |
|---|---|---|---|---|
| Scale to zero | Yes | No (min 1 task) | Yes | No (min 1 pod) |
| Cold start | 1-5s | 30-60s | 1-10s | N/A |
| Max request time | 60 min | Unlimited | 15 min | Unlimited |
| Concurrency | Per-container | Per-task | 1 per instance | Per-pod |
| Pricing model | Per-request + time | Per-second | Per-invocation + time | Per-node |
| Ops overhead | Minimal | Low | Minimal | High |
| Vendor lock-in | Medium (Knative) | High | High | Low |

## When to Use What

```
Choose Cloud Run when:
  - Web services with variable traffic (scale-to-zero saves cost)
  - Stateless HTTP APIs
  - Quick deploys without k8s complexity

Choose Fargate when:
  - Already on AWS ECS, want to drop EC2 management
  - Long-running services that don't benefit from scale-to-zero
  - Need tight AWS IAM integration

Choose Lambda containers when:
  - Event-driven processing (SQS, S3 triggers)
  - Execution < 15 minutes
  - Existing Lambda ecosystem, need custom runtime

Choose Kubernetes when:
  - Multi-cloud or on-prem requirement
  - Complex networking, service mesh needs
  - Team has k8s expertise and justifies ops overhead
```

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Fargate for bursty traffic | Use Cloud Run or Lambda (scale-to-zero) |
| Lambda for long tasks | Use Fargate or Cloud Run (15 min limit) |
| K8s for simple HTTP API | Use Cloud Run (less ops overhead) |
| No startup probe on Cloud Run | Cold starts cause health check failures |
