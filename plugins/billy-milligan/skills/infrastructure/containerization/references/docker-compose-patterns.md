# Docker Compose Patterns

## Local Development Setup

```yaml
services:
  app:
    build:
      context: .
      target: deps           # Use deps stage for hot reload
    command: npm run dev
    ports:
      - '3000:3000'
    volumes:
      - .:/app
      - /app/node_modules    # Exclude node_modules from mount
    environment:
      NODE_ENV: development
      DATABASE_URL: postgresql://app:secret@postgres:5432/myapp
      REDIS_URL: redis://redis:6379
    depends_on:
      postgres:
        condition: service_healthy
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

## depends_on with Health Checks

```yaml
depends_on:
  postgres:
    condition: service_healthy    # Wait for healthcheck to pass
  redis:
    condition: service_healthy
  migrations:
    condition: service_completed_successfully  # Wait for exit 0
```

Without `condition: service_healthy`: app starts before DB is ready, crashes, restart loops.

## Volume Patterns

```yaml
volumes:
  # Named volume: persists between restarts
  - postgres_data:/var/lib/postgresql/data

  # Bind mount: source code for hot reload
  - .:/app

  # Anonymous volume: exclude from bind mount
  - /app/node_modules

  # Read-only bind mount: config files
  - ./nginx.conf:/etc/nginx/nginx.conf:ro
```

## Network Patterns

```yaml
services:
  frontend:
    networks:
      - frontend
  api:
    networks:
      - frontend
      - backend
  database:
    networks:
      - backend      # Not accessible from frontend

networks:
  frontend:
  backend:
```

Network isolation: DB only reachable from API, not directly from frontend.

## Multi-Environment with Override Files

```bash
# Base: docker-compose.yml
# Dev overrides: docker-compose.override.yml (auto-loaded)
# Prod: docker-compose.prod.yml

# Development (auto-loads override)
docker compose up

# Production
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Testing
docker compose -f docker-compose.yml -f docker-compose.test.yml run --rm tests
```

## Anti-patterns

| Anti-pattern | Fix |
|---|---|
| No healthcheck on DB | Add `healthcheck` + `service_healthy` condition |
| Bind-mounting node_modules | Add anonymous volume `/app/node_modules` |
| Hardcoded passwords in compose | Use `.env` file with `${VAR}` syntax |
| No named volumes for data | Data lost on `docker compose down` |
| `restart: always` in dev | Use `restart: unless-stopped` or omit |

## Quick Reference

- Health check interval: **5s** for local dev services
- Start period: **10s** for databases (init takes time)
- Volume for data: **named volumes** (persist across restarts)
- Volume for code: **bind mount** (hot reload)
- Network isolation: separate frontend/backend networks
- Override file: `docker-compose.override.yml` auto-loaded in dev
