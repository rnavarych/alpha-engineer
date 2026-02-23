---
name: containerization
description: |
  Docker and Kubernetes containerization patterns. Multi-stage builds, layer caching, distroless images, Docker Compose, k8s deployments, HPA, RBAC, serverless containers.
allowed-tools: Read, Grep, Glob
---

# Containerization

## When to use

Use when writing Dockerfiles, setting up Docker Compose for local development, deploying to Kubernetes, or evaluating serverless container platforms. Covers image optimization, security hardening, and orchestration patterns.

## Core principles

1. Multi-stage builds always — dev dependencies must not reach production
2. Non-root user in production — running as root is a container security violation
3. Layer order matters — most-changing layers last for cache reuse
4. Health checks in every container — orchestrators need them for traffic routing
5. Resource limits are mandatory — unbounded containers destabilize the cluster

## References available

- `references/dockerfile-patterns.md` — Multi-stage builds, layer caching, security scanning, distroless, .dockerignore
- `references/kubernetes-patterns.md` — Deployment, HPA, resource limits, health checks, RBAC
- `references/docker-compose-patterns.md` — Local dev, depends_on with healthcheck, volumes, networks
- `references/serverless-containers.md` — Cloud Run, Fargate, Lambda containers, decision criteria

## Scripts available

- `scripts/detect-containerization.sh` — Checks for Dockerfile, docker-compose.yml, k8s manifests

## Assets available

- `assets/dockerfile-template` — Optimized multi-stage Node.js Dockerfile
- `assets/k8s-deployment-template.yaml` — Deployment + Service + HPA with best-practice defaults
