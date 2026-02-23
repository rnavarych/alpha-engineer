# Chaos Engineering

## Principles

```
1. Define steady state: what does "normal" look like in metrics?
2. Hypothesize: "if X fails, the system should Y"
3. Introduce failure: run the experiment
4. Observe: did the system behave as expected?
5. Learn: fix gaps, improve resilience
```

## Chaos Monkey (Netflix)

```
What: randomly terminates EC2 instances in production
Why: forces services to be stateless and handle instance failure
How: runs during business hours, kills random instances

Setup (Simian Army):
  - Configure ASG (Auto Scaling Group) for minimum capacity
  - Ensure health checks and auto-recovery
  - Start with non-critical services
  - Run during business hours only (engineers available)
```

## Litmus Chaos (Kubernetes)

```yaml
# Pod kill experiment
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: pod-kill-test
spec:
  appinfo:
    appns: default
    applabel: app=order-service
    appkind: deployment
  chaosServiceAccount: litmus-admin
  experiments:
    - name: pod-delete
      spec:
        components:
          env:
            - name: TOTAL_CHAOS_DURATION
              value: '30'
            - name: CHAOS_INTERVAL
              value: '10'
            - name: FORCE
              value: 'false'
```

```yaml
# Network latency injection
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: network-latency-test
spec:
  appinfo:
    appns: default
    applabel: app=order-service
  experiments:
    - name: pod-network-latency
      spec:
        components:
          env:
            - name: NETWORK_INTERFACE
              value: eth0
            - name: NETWORK_LATENCY
              value: '500'      # 500ms added latency
            - name: TOTAL_CHAOS_DURATION
              value: '60'
```

## Failure Injection Types

| Type | Tool | What it tests |
|---|---|---|
| Pod kill | Litmus, Chaos Mesh | Auto-restart, load balancing |
| Network latency | tc, Litmus | Timeout handling, circuit breakers |
| Network partition | Litmus, Toxiproxy | Split-brain resilience |
| CPU stress | stress-ng, Litmus | Autoscaling, throttling behavior |
| Memory pressure | stress-ng | OOM handling, graceful degradation |
| DNS failure | CoreDNS config | Fallback behavior, caching |
| Disk I/O | fio, Litmus | Write failure handling |
| Dependency failure | Toxiproxy, WireMock | Circuit breaker, fallback responses |

## Toxiproxy for Dependency Failure

```typescript
// Simulate database latency and failures in tests
import Toxiproxy from 'toxiproxy-node-client';

const toxiproxy = new Toxiproxy('http://localhost:8474');

// Create proxy for database
const proxy = await toxiproxy.createProxy({
  name: 'postgres',
  listen: '0.0.0.0:15432',
  upstream: 'postgres:5432',
});

// Add 500ms latency
await proxy.addToxic({
  type: 'latency',
  attributes: { latency: 500, jitter: 100 },
});

// Simulate connection refused
await proxy.disable();
// Test: does the app return graceful error?
// Test: does the circuit breaker open?

await proxy.enable();  // Restore connectivity
```

## Game Day Planning

```
Pre-game day (1 week before):
  [ ] Define scope: which services, which failure modes
  [ ] Define success criteria: "order service continues serving with 1 pod down"
  [ ] Notify stakeholders (not customers)
  [ ] Prepare rollback plan if experiment causes unexpected impact
  [ ] Ensure monitoring dashboards are ready
  [ ] Schedule during business hours (engineers available)

Game day execution:
  1. Briefing: explain experiment to all participants (15 min)
  2. Verify steady state: confirm baseline metrics
  3. Run experiment: introduce failure
  4. Observe: watch dashboards, check alerts
  5. Record findings: what happened vs what was expected
  6. Restore: remove failure injection
  7. Debrief: discuss findings, create action items (30 min)

Post-game day:
  [ ] Document findings and action items
  [ ] Fix identified gaps
  [ ] Schedule next game day (quarterly)
```

## Progressive Chaos Maturity

```
Level 1: Game days (quarterly, manual, staging only)
  - Kill pods manually
  - Inject network latency with tc
  - Document findings

Level 2: Automated experiments (monthly, staging + production)
  - Litmus/Chaos Mesh scheduled runs
  - Automated steady-state verification
  - Alert on experiment impact

Level 3: Continuous chaos (weekly, production)
  - Chaos Monkey running daily
  - Automated experiment validation
  - Integrated into CI/CD pipeline

Most teams should aim for Level 2.
```

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| Chaos in production without preparation | Start in staging, graduate to production |
| No steady-state definition | Define what "normal" looks like before experiments |
| Running during off-hours | Run when engineers are available to respond |
| No rollback plan | Always have a way to stop the experiment instantly |
| Chaos without follow-up | Create action items for every gap found |

## Quick Reference

- Start in **staging**, graduate to production
- Run during **business hours** (engineers available)
- Define **steady state** before every experiment
- Have a **kill switch** for every experiment
- Quarterly **game days** (minimum)
- Tools: Litmus (k8s), Chaos Mesh (k8s), Toxiproxy (dependency), Gremlin (SaaS)
- Maturity target: **Level 2** (automated, staging + production)
