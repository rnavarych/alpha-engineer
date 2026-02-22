---
name: containerization
description: |
  Docker and containerization: multi-stage Node.js Dockerfile (180MB vs 1.2GB), Go distroless
  image (~20MB), Docker Compose with health checks, .dockerignore, non-root user, security
  scanning, container resource limits, production-ready configurations.
  Use when writing Dockerfiles, setting up Docker Compose, optimizing image sizes.
allowed-tools: Read, Grep, Glob
---

# Containerization

## When to Use This Skill
- Writing production-ready Dockerfiles
- Optimizing Docker image sizes
- Setting up Docker Compose for local development
- Configuring container security (non-root, read-only filesystem)
- Multi-stage builds for different runtimes

## Core Principles

1. **Multi-stage builds always** — dev dependencies must not reach production image
2. **Non-root user in production containers** — running as root is a security vulnerability
3. **Layer order matters** — most-changing layers last, maximizes cache reuse
4. **.dockerignore is mandatory** — without it, `node_modules` goes into build context
5. **Health checks in every production container** — orchestrators need them for traffic routing

---

## Patterns ✅

### Production Node.js Dockerfile

```dockerfile
# Target: ~180MB final image (vs ~1.2GB without optimization)

FROM node:20-alpine AS base
WORKDIR /app
# Install pnpm at base layer (cached until node version changes)
RUN corepack enable && corepack prepare pnpm@latest --activate

# Dependencies layer — cached until lockfile changes
FROM base AS deps
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# Build layer — rebuilds when source changes
FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN pnpm build

# Production runner — minimal image
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

# Create non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nodeuser

# Production deps only
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && corepack prepare pnpm@latest --activate && \
    pnpm install --frozen-lockfile --prod && \
    rm -rf /root/.cache /root/.npm

# Copy built application
COPY --from=builder --chown=nodeuser:nodejs /app/dist ./dist
COPY --from=builder --chown=nodeuser:nodejs /app/public ./public

USER nodeuser
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O- http://localhost:3000/health || exit 1

CMD ["node", "dist/server.js"]
```

**Image size breakdown**:
- `node:20` full: ~1.2GB
- `node:20-alpine` dev: ~400MB (with devDependencies)
- `node:20-alpine` prod deps only: ~180MB

### Go Distroless Image (~20MB)

```dockerfile
# Go: compile to static binary, run in distroless (no OS, no shell)
FROM golang:1.22 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download   # Cache module downloads separately

COPY . .
# Static binary — CGO disabled, no external dependencies
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w -extldflags=-static" \
    -o server ./cmd/server

FROM gcr.io/distroless/static-debian12:nonroot AS runner
# Distroless: no shell, no package manager, minimal attack surface
# nonroot variant: runs as uid 65532 by default

WORKDIR /app
COPY --from=builder /app/server .

EXPOSE 8080
ENTRYPOINT ["/app/server"]
```

**Image size**:
- Go builder stage: ~800MB (not in final image)
- `gcr.io/distroless/static:nonroot`: ~2MB base
- Final image with binary: ~20–25MB

### Python FastAPI Dockerfile

```dockerfile
FROM python:3.12-slim AS base
WORKDIR /app
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

FROM base AS builder
COPY requirements.txt .
RUN pip install --prefix=/install -r requirements.txt

FROM base AS runner
RUN useradd --system --create-home --uid 1001 appuser

COPY --from=builder /install /usr/local
COPY --chown=appuser:appuser . .

USER appuser
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

### .dockerignore

```
# .dockerignore — ALWAYS include this

node_modules/
.git/
.gitignore
.env
.env.*
*.log
dist/
build/
coverage/
.nyc_output/
.pytest_cache/
__pycache__/
*.pyc
.DS_Store
*.md
docs/
.github/
.vscode/
test/
tests/
**/*.test.ts
**/*.spec.ts
Dockerfile
docker-compose*.yml
```

Without `.dockerignore`: build context sends `node_modules` (200–500MB) to Docker daemon on every build.

### Docker Compose for Local Development

```yaml
# docker-compose.yml
version: '3.9'

services:
  app:
    build:
      context: .
      target: deps        # Use deps stage — mount source for hot reload
    command: pnpm dev
    ports:
      - '3000:3000'
    volumes:
      - .:/app
      - /app/node_modules  # Exclude node_modules from mount
    environment:
      NODE_ENV: development
      DATABASE_URL: postgresql://app:secret@postgres:5432/myapp
      REDIS_URL: redis://redis:6379
    depends_on:
      postgres:
        condition: service_healthy  # Wait for health check
      redis:
        condition: service_healthy

  postgres:
    image: postgres:16-alpine
    ports:
      - '5432:5432'
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: app
      POSTGRES_PASSWORD: secret
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U app -d myapp']
      interval: 5s
      timeout: 5s
      retries: 5
      start_period: 10s

  redis:
    image: redis:7-alpine
    ports:
      - '6379:6379'
    healthcheck:
      test: ['CMD', 'redis-cli', 'ping']
      interval: 5s
      timeout: 3s
      retries: 5

volumes:
  postgres_data:
```

### Container Security Scanning

```yaml
# GitHub Actions: scan image before push
- uses: aquasecurity/trivy-action@master
  with:
    image-ref: 'ghcr.io/myorg/myapp:${{ github.sha }}'
    format: 'sarif'
    output: 'trivy-results.sarif'
    severity: 'CRITICAL,HIGH'
    exit-code: '1'  # Fail pipeline on CRITICAL/HIGH CVEs

- uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: 'trivy-results.sarif'
```

---

## Anti-Patterns ❌

### Single-Stage Build with Dev Dependencies
**What it is**: One `FROM node:20` stage, `npm install` (including devDependencies), copy everything.
**What breaks**: 1.2GB image. Devtools, test runners, TypeScript compiler all in production. Larger attack surface. Slower pulls. Higher egress costs.
**Fix**: Multi-stage build. Final image has only production deps and compiled output.

### Running as Root
**What it is**: No `USER` directive → container runs as root.
**What breaks**: Container escape vulnerability means attacker gets root on host. Violates PCI DSS and SOC 2 requirements. Every container security scan will flag it.
**Fix**: `RUN adduser --system --uid 1001 appuser && USER appuser`

### Copying .env Files into Image
**What it is**: `COPY . .` without .dockerignore → `.env` ends up in the image.
**What breaks**: Image pushed to registry → anyone who can pull the image has all your secrets. Especially catastrophic on public registries.
**Fix**: `.dockerignore` must include `.env` and `.env.*`. Secrets via environment variables at runtime, not baked into image.

### No Health Check
**What it is**: No `HEALTHCHECK` directive in Dockerfile or Kubernetes probe.
**What breaks**: Orchestrator routes traffic to container that has started but app is still initializing. Or app crashed internally but process is still running. Users see errors.
**Fix**: Always define a health check endpoint and configure it in Dockerfile or Kubernetes.

---

## Quick Reference

```
Node.js final image: ~180MB (alpine + prod deps + dist)
Go distroless: ~20MB (static binary + distroless base)
Non-root user UID: 1001 (avoid 0 = root)
.dockerignore: always include node_modules/, .git/, .env
Health check: --interval=30s --timeout=3s --retries=3
Layer order: package.json → install → source → build
Build context size: should be <50MB (check with docker build . --progress=plain)
```
