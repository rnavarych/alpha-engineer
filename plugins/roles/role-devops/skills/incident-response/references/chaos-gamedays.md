# Chaos Engineering and Game Days

## When to load
Load when planning chaos experiments, setting up Litmus/Chaos Mesh/Gremlin/AWS FIS,
designing game day exercises, or building resilience regression tests into CI/CD pipelines.

## Chaos Engineering

- Use chaos engineering to proactively discover weaknesses before they cause incidents.
- Start with **steady-state hypothesis**: define what "normal" looks like in metrics and SLOs before injecting any failure.
- Introduce controlled failures using purpose-built tooling:
  - **Litmus Chaos** or **Chaos Mesh** for Kubernetes pod kill, network delay, CPU stress, memory pressure, and disk I/O experiments.
  - **Gremlin** for broader infrastructure chaos: instance termination, DNS failures, disk fill, packet loss, and latency injection across multiple cloud providers.
  - **AWS Fault Injection Simulator (FIS)** for managed AWS resource failures: EC2 instance stops, ECS task stops, RDS failovers, AZ disruptions.
- Run experiments in staging first. Graduate to production only with confidence and circuit breakers in place.
- Automate recurring chaos experiments in CI/CD as regression tests for resilience. A suite of chaos tests should run weekly at minimum.

### Chaos Experiment Design Checklist
1. Define steady-state metrics and SLO targets before starting.
2. Scope the blast radius — start small (single pod, single AZ).
3. Have a clear abort procedure and rollback plan ready.
4. Monitor dashboards throughout the experiment.
5. Document findings and create follow-up tickets for every identified weakness.
6. Validate that the system returned to steady state after the experiment ends.

### Common Experiment Scenarios
- **Pod kill**: terminate random pods in a Deployment. Validates PodDisruptionBudgets, readiness probes, and restart behavior.
- **Network partition**: block traffic between services. Validates circuit breakers, timeout behavior, and graceful degradation.
- **CPU/memory stress**: push node or container to resource limits. Validates resource limits and HPA behavior.
- **AZ failure simulation**: drain all pods from one availability zone. Validates topology spread constraints and multi-AZ data replication.
- **Database failover**: trigger an RDS or Aurora failover. Validates connection pooling, retry logic, and RDS Proxy behavior.
- **Dependency outage**: block calls to a third-party API. Validates fallback behavior and circuit breaker patterns.

## Game Days

- Schedule quarterly game day exercises: simulated incidents to practice response procedures.
- Inject a realistic failure scenario chosen from past incidents or anticipated risks. Do not reveal the exact scenario to responders in advance.
- Observe how the team detects the failure (monitoring, alerting, user reports), communicates across functions, and resolves the issue using runbooks.
- Assign an observer role separate from responders to record timeline, decisions, and gaps without participating in resolution.
- Debrief after each game day. Update runbooks, monitoring, and escalation policies based on findings.
- Include non-engineering stakeholders (support, communications, product management) to practice cross-functional incident response.

### Game Day Structure
1. **Pre-brief** (15 min): Set scope, confirm abort criteria, assign roles (Incident Commander, responders, observer, communications).
2. **Inject** (5 min): Observer or platform team injects the failure scenario.
3. **Respond** (60-90 min): Team responds as if it were a real incident.
4. **Resolve** (variable): Team resolves or observer calls time.
5. **Debrief** (30-45 min): Timeline review, what went well, what to improve, action items with owners and due dates.

### Metrics to Track Across Game Days
- Mean time to detect (MTTD): from failure injection to first alert or team awareness.
- Mean time to acknowledge (MTTA): from alert to on-call acknowledgment.
- Mean time to resolve (MTTR): from acknowledgment to full resolution.
- Runbook hit rate: percentage of responders who found and followed the correct runbook.
- Escalation accuracy: correct severity assigned and correct people looped in.
