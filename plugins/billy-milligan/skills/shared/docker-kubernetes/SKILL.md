---
name: docker-kubernetes
description: |
  Docker and Kubernetes production patterns: multi-stage Dockerfile, distroless images,
  Kubernetes Deployment with resource limits, HPA, liveness/readiness/startup probes,
  ConfigMaps and Secrets, PodDisruptionBudget, NetworkPolicy, RBAC. Production checklist.
  Use when containerizing apps, writing K8s manifests, scaling workloads, hardening clusters.
allowed-tools: Read, Grep, Glob
---

# Docker & Kubernetes Production Patterns

## When to Use This Skill
- Writing production-grade Dockerfiles
- Creating Kubernetes Deployment manifests
- Configuring autoscaling with HPA
- Setting up liveness/readiness probes
- Hardening cluster security with RBAC and NetworkPolicy

## Core Principles

1. **Multi-stage builds for small images** — builder stage installs dependencies; final stage is minimal; 180MB vs 1.2GB
2. **Resource limits are mandatory** — no limits = one pod can starve all others on the node
3. **Readiness != Liveness** — readiness controls traffic; liveness triggers restart; startup handles slow init
4. **Pods are ephemeral** — never store state in a pod; PVCs for persistence, external services for state
5. **Least privilege RBAC** — service accounts with minimum permissions; separate SA per service

## References available
- `references/dockerfile-patterns.md` — multi-stage Node.js Dockerfile, distroless Go image, non-root user, dumb-init
- `references/k8s-manifests.md` — Deployment with resource limits, HPA, PodDisruptionBudget, health check endpoints, topology spread
- `references/helm-patterns.md` — Helm chart structure, values templating, hooks, release strategies

## Scripts available
- `scripts/docker-lint.sh` — lint Dockerfile against production checklist
