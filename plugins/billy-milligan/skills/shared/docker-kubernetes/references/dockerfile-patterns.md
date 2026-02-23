# Dockerfile Patterns

## When to load
Load when writing Dockerfiles, optimizing image size, or fixing build performance.

## Multi-Stage Build (Node.js)

```dockerfile
# Stage 1: Install dependencies
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --only=production

# Stage 2: Build
FROM node:20-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 3: Production image
FROM node:20-alpine AS runtime
WORKDIR /app

# Security: non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup
USER appuser

COPY --from=deps --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=build --chown=appuser:appgroup /app/dist ./dist
COPY --from=build --chown=appuser:appgroup /app/package.json ./

ENV NODE_ENV=production
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "dist/server.js"]
```

## Multi-Stage Build (Go)

```dockerfile
FROM golang:1.22-alpine AS build
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /server ./cmd/server

FROM scratch
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /server /server
USER 65534:65534
EXPOSE 8080
ENTRYPOINT ["/server"]
# Final image: ~10MB vs ~300MB with golang base
```

## Multi-Stage Build (Python)

```dockerfile
FROM python:3.12-slim AS build
WORKDIR /app
RUN pip install --no-cache-dir poetry
COPY pyproject.toml poetry.lock ./
RUN poetry export -f requirements.txt -o requirements.txt --without-hashes

FROM python:3.12-slim AS runtime
WORKDIR /app
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
COPY --from=build /app/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY --chown=appuser:appgroup . .
USER appuser
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Layer Caching Optimization

```dockerfile
# ORDER MATTERS: least-changing layers first

# 1. Base image (rarely changes)
FROM node:20-alpine

# 2. System deps (rarely changes)
RUN apk add --no-cache dumb-init

# 3. Package files (changes when deps change)
COPY package.json package-lock.json ./
RUN npm ci

# 4. Source code (changes frequently)
COPY . .
RUN npm run build

# If you change source code, only layers 4+ rebuild
# If you change package.json, layers 3+ rebuild
```

## .dockerignore

```
node_modules
.git
.env
.env.*
*.md
.github
.vscode
coverage
dist
.next
Dockerfile
docker-compose*.yml
```

## Image Size Comparison

```
Base image sizes:
  node:20          ~1.1GB  (never use in production)
  node:20-slim     ~200MB  (Debian slim)
  node:20-alpine   ~130MB  (Alpine, smallest)
  distroless/nodejs ~120MB  (Google, no shell)
  scratch          ~0MB    (Go/Rust only, no OS)

Tips:
  - Use alpine or slim for 50-80% reduction
  - Multi-stage: copy only artifacts to final stage
  - npm ci --only=production: skip devDependencies
  - Go: use scratch (statically compiled)
```

## Anti-patterns
- Running as root → security risk, use USER directive
- No .dockerignore → context includes node_modules, .git (slow builds)
- COPY . . before npm install → busts cache on every source change
- Using latest tag → non-reproducible builds
- No HEALTHCHECK → orchestrator can't detect unhealthy containers
- Installing dev dependencies in production image → bloat

## Quick reference
```
Multi-stage: deps → build → runtime (minimal final image)
Layer order: system deps → package files → install → source → build
Alpine: smallest with shell, use for Node.js/Python
Scratch: Go/Rust only, no OS, smallest possible
Non-root: adduser + USER directive, always in production
Healthcheck: wget/curl to /health endpoint
.dockerignore: node_modules, .git, .env, coverage
Cache: COPY package*.json first, then npm ci, then source
```
