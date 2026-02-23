# Rollback Plans, Risk Mitigation, and Communication

## When to load
Load when defining rollback procedures and triggers for migration phases, identifying and mitigating migration risks, or planning stakeholder and team communication during active migrations.

## Rollback Plans

- Every migration phase must have a documented rollback procedure. If the new system fails, you must be able to revert to the legacy system within the defined RTO.
- Data rollback: if the new system has accepted writes, those writes must be replayed to the legacy system on rollback. Plan for this explicitly.
- Traffic rollback: the routing layer (facade, gateway) must support instant traffic rerouting to the legacy system.
- Test rollback procedures before the migration. An untested rollback plan is not a plan.
- Define rollback triggers: specific error rate thresholds, latency thresholds, or data discrepancy counts that automatically initiate rollback.

## Risk Mitigation

- Identify risks for each phase: data loss, downtime, performance degradation, integration failures, team burnout.
- For each risk, define: likelihood (high/medium/low), impact (high/medium/low), mitigation strategy, and contingency plan.
- High-likelihood, high-impact risks must be mitigated before the phase begins. Do not proceed on hope.
- Common mitigations: feature flags (instant rollback), canary deployments (limit blast radius), automated rollback triggers, and dedicated incident response runbooks.

## Communication Plans

- Stakeholder communication: weekly status updates to business stakeholders with clear red/yellow/green status per phase.
- Team communication: daily standups during active migration phases. Dedicated Slack channel for migration issues.
- Customer communication: advance notice for any customer-visible changes. Status page updates during cutover windows.
- Post-migration retrospective: review what went well, what was harder than expected, and what to do differently next time.
