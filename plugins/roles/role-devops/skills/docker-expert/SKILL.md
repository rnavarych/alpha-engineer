---
name: role-devops:docker-expert
description: |
  Expert-level Docker guidance covering multi-stage builds, image optimization,
  Docker Compose orchestration, networking, volume management, security scanning,
  and container registry operations.
allowed-tools: Read, Grep, Glob, Bash
---

# Docker Expert

## Multi-Stage Builds

- Separate build and runtime stages to minimize final image size. The build stage installs compilers, dev dependencies, and produces artifacts; the runtime stage copies only the compiled output.
- Use named stages (`FROM node:20 AS builder`) for clarity and to enable targeted builds with `--target`.
- Cache package manager layers early: copy lockfiles first, run install, then copy source code. This maximizes Docker layer caching.

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --production=false
COPY . .
RUN npm run build

FROM gcr.io/distroless/nodejs20-debian12
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
USER nonroot
EXPOSE 3000
CMD ["dist/main.js"]
```

## Image Optimization

- Prefer `distroless` images for production (no shell, no package manager, minimal attack surface). Use Alpine when you need a shell for debugging.
- Remove unnecessary files: test directories, documentation, build toolchains. Use `.dockerignore` aggressively to exclude `.git`, `node_modules`, IDE configs, and local env files.
- Pin base image digests in production Dockerfiles for reproducibility: `FROM node:20-alpine@sha256:abc123...`.
- Combine `RUN` commands with `&&` to reduce layers, and clean up package manager caches in the same layer.

## Docker Compose

- Use `docker-compose.yml` for local development with service dependencies, shared networks, and volume mounts.
- Define health checks in Compose so dependent services wait for readiness, not just container start.
- Use `profiles` to group services (e.g., `debug`, `monitoring`) that are not needed in every run.
- Override files (`docker-compose.override.yml`) for local-specific settings; keep the base file production-like.

## Networking

- **Bridge networks** for single-host isolation between services. Create named networks instead of relying on the default bridge.
- **Overlay networks** for multi-host communication in Docker Swarm or when bridging to Kubernetes.
- Never expose database ports to the host in production. Use internal Docker networks and let application containers connect directly.
- Use aliases to give containers DNS names within a network for service discovery.

## Volume Management

- Use named volumes for persistent data (databases, uploads). Bind mounts are for development source-code hot-reload only.
- Back up named volumes with `docker run --volumes-from` or volume driver plugins that support snapshots.
- Set appropriate volume permissions; avoid running containers as root to write to volumes.

## Security Scanning and Hardening

- Integrate **Trivy** or **Snyk Container** in CI to scan images for CVEs before pushing to the registry. Fail the pipeline on critical/high findings.
- Run containers as a non-root user. Add `USER nonroot` or a dedicated UID in the Dockerfile.
- Drop all Linux capabilities and add back only what is needed: `--cap-drop=ALL --cap-add=NET_BIND_SERVICE`.
- Set `read-only` root filesystems where possible and mount tmpfs for directories that need writes.
- Never store secrets in image layers. Use build-time secrets (`--mount=type=secret`) or runtime injection.

## Registry Management

- Use private registries (ECR, GCR, ACR, or self-hosted Harbor) for production images. Tag images with both the Git SHA and a semantic version.
- Enable image signing and verification with cosign or Docker Content Trust.
- Implement lifecycle policies to prune untagged and old images, keeping registry storage costs under control.
- Use vulnerability scanning built into the registry (ECR scanning, GCR Container Analysis) as a second gate.

## Health Checks

- Define `HEALTHCHECK` in every Dockerfile: an HTTP endpoint for web services, a TCP check for databases, or a command for CLI tools.
- Set sensible intervals (30s), timeouts (5s), and retries (3) so orchestrators can detect and replace unhealthy containers promptly.

## Best Practices Checklist

1. `.dockerignore` is present and comprehensive
2. Base images are pinned and minimal
3. Runs as non-root user
4. Health check is defined
5. No secrets baked into the image
6. Image is scanned for vulnerabilities in CI
7. Layers are optimized for caching
8. Compose health checks gate dependent services
