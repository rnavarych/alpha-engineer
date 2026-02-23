# Dockerfile Patterns

## Multi-Stage Builds

```dockerfile
# Stage 1: Dependencies (cached until lockfile changes)
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts

# Stage 2: Build (rebuilds when source changes)
FROM deps AS builder
COPY . .
RUN npm run build

# Stage 3: Production runner (minimal image)
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 appuser

COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:nodejs /app/dist ./dist
COPY --from=builder --chown=appuser:nodejs /app/package.json ./

RUN npm prune --production && rm -rf /root/.npm /root/.cache

USER appuser
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O- http://localhost:3000/health || exit 1

CMD ["node", "dist/server.js"]
```

Image size: `node:20` full ~1.2GB vs alpine + prod deps ~180MB.

## Layer Caching Best Practices

Order layers by change frequency (least to most changing):

```
1. Base image            (changes: monthly)
2. System packages       (changes: weekly)
3. package.json/lockfile (changes: per-feature)
4. npm install           (cached if lockfile unchanged)
5. Source code COPY      (changes: every commit)
6. Build command         (changes: every commit)
```

Key rule: **COPY package*.json before COPY source** to cache `npm install`.

## Security Scanning

```bash
# Trivy: scan image for CVEs
trivy image --severity CRITICAL,HIGH myapp:latest

# Grype: alternative scanner
grype myapp:latest --only-fixed

# Hadolint: lint Dockerfile
hadolint Dockerfile
```

CI integration:

```yaml
# GitHub Actions
- uses: aquasecurity/trivy-action@master
  with:
    image-ref: myapp:${{ github.sha }}
    severity: 'CRITICAL,HIGH'
    exit-code: '1'
```

## Distroless Images

```dockerfile
# Go: compile to static binary, run in distroless
FROM golang:1.22 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o server ./cmd/server

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /app/server /server
EXPOSE 8080
ENTRYPOINT ["/server"]
```

Final image: **~20MB**. No shell, no package manager, minimal attack surface.

## .dockerignore

```
node_modules/
.git/
.env
.env.*
*.log
dist/
coverage/
.nyc_output/
__pycache__/
*.pyc
.DS_Store
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

Without `.dockerignore`: build context sends `node_modules` (200-500MB) to Docker daemon on every build.

## Anti-patterns

| Anti-pattern | Impact | Fix |
|---|---|---|
| Single-stage with devDeps | 1.2GB image, larger attack surface | Multi-stage build |
| Running as root | Container escape = host root | `USER appuser` (UID 1001) |
| COPY before install | Invalidates npm cache every commit | COPY lockfile first, then install |
| No .dockerignore | Sends node_modules to daemon | Always include .dockerignore |
| Latest tag in FROM | Non-reproducible builds | Pin to specific version |

## Quick Reference

- Alpine base: **~180MB** final (Node.js)
- Distroless: **~20MB** final (Go)
- Non-root UID: **1001** (avoid 0)
- Health check interval: **30s** timeout **3s** retries **3**
- Build context target: **<50MB**
