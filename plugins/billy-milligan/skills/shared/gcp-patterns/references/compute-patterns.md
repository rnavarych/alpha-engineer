# GCP Compute Patterns

## When to load
Load when choosing between Cloud Run, GKE, Cloud Functions, or Compute Engine.

## Compute Decision Tree

```
Is your workload event-driven or HTTP-based?
  │
  ├─ YES → How long does it run?
  │        │
  │        ├─ < 9 min, simple trigger → Cloud Functions (2nd gen)
  │        │   ✅ Zero ops, event-driven, auto-scale to 0
  │        │   ❌ 9min timeout, limited concurrency control
  │        │
  │        └─ < 60 min, HTTP or container → Cloud Run
  │            ✅ Container-based, scale to 0, concurrency control
  │            ❌ 60min timeout, stateless only
  │
  └─ NO → Do you need Kubernetes?
          │
          ├─ YES → GKE Autopilot
          │         ✅ Managed K8s, pay per pod, no node management
          │         ❌ Some K8s features restricted
          │
          └─ NO → Compute Engine
                   ✅ Full control, GPUs, persistent state
                   ❌ Manual scaling, patching, ops overhead
```

## Cloud Run

```yaml
# service.yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: api-server
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/minScale: "1"    # min instances
        autoscaling.knative.dev/maxScale: "100"   # max instances
        run.googleapis.com/cpu-throttling: "false" # always-on CPU
    spec:
      containerConcurrency: 80  # requests per instance
      timeoutSeconds: 300
      containers:
        - image: gcr.io/my-project/api:v1.2.0
          ports:
            - containerPort: 3000
          resources:
            limits:
              cpu: "2"
              memory: 1Gi
          env:
            - name: NODE_ENV
              value: production
          startupProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 0
            periodSeconds: 3
```

```bash
# Deploy Cloud Run service
gcloud run deploy api-server \
  --image gcr.io/my-project/api:v1.2.0 \
  --platform managed \
  --region us-central1 \
  --min-instances 1 \
  --max-instances 100 \
  --memory 1Gi \
  --cpu 2 \
  --concurrency 80 \
  --set-env-vars NODE_ENV=production \
  --set-secrets DATABASE_URL=db-url:latest \
  --allow-unauthenticated
```

## Cloud Functions (2nd gen)

```typescript
import { onRequest } from 'firebase-functions/v2/https';
import { onMessagePublished } from 'firebase-functions/v2/pubsub';

// HTTP function
export const api = onRequest(
  { memory: '256MiB', timeoutSeconds: 60, minInstances: 1 },
  async (req, res) => {
    const result = await processRequest(req.body);
    res.json(result);
  }
);

// Pub/Sub triggered function
export const processOrder = onMessagePublished(
  { topic: 'orders', memory: '512MiB', timeoutSeconds: 300 },
  async (event) => {
    const order = event.data.message.json;
    await fulfillOrder(order);
  }
);
```

## GKE Autopilot

```bash
# Create Autopilot cluster
gcloud container clusters create-auto my-cluster \
  --region us-central1 \
  --release-channel regular

# Deploy — uses standard K8s manifests
# Autopilot: pay per pod resources, no node management
# Restrictions: no privileged containers, no host networking
# Benefits: auto-scaling, auto-repair, auto-upgrade
```

## Cost Comparison

```
Cloud Run:       $0 idle (scale to 0), ~$0.00002400/vCPU-s
Cloud Functions: $0 idle, $0.0000025/invocation + compute
GKE Autopilot:   ~$0.0445/vCPU-hr + $0.0049/GiB-hr (per pod)
Compute Engine:  ~$0.0210/vCPU-hr (e2-standard, on-demand)
Committed Use:   ~$0.0133/vCPU-hr (1-year, 37% discount)

Rule of thumb:
  Variable traffic → Cloud Run (scale to 0)
  Predictable load → GKE Autopilot or Compute Engine
  Event processing → Cloud Functions
  GPU/specialized → Compute Engine
```

## Anti-patterns
- Cloud Functions for long-running tasks → use Cloud Run or GKE
- GKE Standard for simple workloads → Autopilot or Cloud Run simpler
- Compute Engine without managed instance groups → no auto-healing
- Cloud Run with CPU throttling for background workers → use always-on CPU

## Quick reference
```
Cloud Run: containers, scale to 0, HTTP/gRPC, 60min timeout
Cloud Functions: event-driven, simple triggers, 9min timeout
GKE Autopilot: managed K8s, pay per pod, no node ops
Compute Engine: full VMs, GPUs, persistent state
Scale to 0: Cloud Run + Cloud Functions (pay nothing when idle)
Secrets: Secret Manager, --set-secrets flag for Cloud Run
Min instances: 1 for production (avoid cold starts)
Region: us-central1 cheapest, choose closest to users
```
