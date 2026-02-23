#!/usr/bin/env bash
# detect-go-stack.sh — Reads go.mod to identify Go stack components
# Usage: ./detect-go-stack.sh [path/to/go.mod]
set -euo pipefail

GO_MOD="${1:-go.mod}"

if [ ! -f "$GO_MOD" ]; then
  echo "Error: $GO_MOD not found"
  exit 1
fi

echo "=== Go Stack Detection ==="
echo "File: $GO_MOD"
echo ""

# Module name
MODULE=$(grep '^module ' "$GO_MOD" | head -1 | awk '{print $2}')
echo "Module: $MODULE"
echo ""

# Go version
GO_VERSION=$(grep '^go ' "$GO_MOD" | head -1 | awk '{print $2}')
echo "Go version: $GO_VERSION"
echo ""

# HTTP framework
echo "--- HTTP Framework ---"
if grep -q 'github.com/go-chi/chi' "$GO_MOD" 2>/dev/null; then
  echo "  Chi"
elif grep -q 'github.com/gin-gonic/gin' "$GO_MOD" 2>/dev/null; then
  echo "  Gin"
elif grep -q 'github.com/labstack/echo' "$GO_MOD" 2>/dev/null; then
  echo "  Echo"
elif grep -q 'github.com/gofiber/fiber' "$GO_MOD" 2>/dev/null; then
  echo "  Fiber"
elif grep -q 'github.com/gorilla/mux' "$GO_MOD" 2>/dev/null; then
  echo "  Gorilla Mux"
else
  echo "  net/http (stdlib)"
fi

# Database
echo "--- Database ---"
if grep -q 'github.com/jackc/pgx' "$GO_MOD" 2>/dev/null; then
  echo "  pgx (PostgreSQL)"
fi
if grep -q 'github.com/jmoiron/sqlx' "$GO_MOD" 2>/dev/null; then
  echo "  sqlx"
fi
if grep -q 'gorm.io/gorm' "$GO_MOD" 2>/dev/null; then
  echo "  GORM"
fi
if grep -q 'entgo.io/ent' "$GO_MOD" 2>/dev/null; then
  echo "  Ent"
fi
if grep -q 'github.com/go-sql-driver/mysql' "$GO_MOD" 2>/dev/null; then
  echo "  MySQL driver"
fi
if grep -q 'go.mongodb.org/mongo-driver' "$GO_MOD" 2>/dev/null; then
  echo "  MongoDB"
fi
if grep -q 'github.com/redis/go-redis' "$GO_MOD" 2>/dev/null; then
  echo "  Redis"
fi

# Migrations
echo "--- Migrations ---"
if grep -q 'github.com/golang-migrate/migrate' "$GO_MOD" 2>/dev/null; then
  echo "  golang-migrate"
elif grep -q 'github.com/pressly/goose' "$GO_MOD" 2>/dev/null; then
  echo "  goose"
elif grep -q 'ariga.io/atlas' "$GO_MOD" 2>/dev/null; then
  echo "  Atlas"
fi

# Logging
echo "--- Logging ---"
if grep -q 'go.uber.org/zap' "$GO_MOD" 2>/dev/null; then
  echo "  Zap"
elif grep -q 'github.com/rs/zerolog' "$GO_MOD" 2>/dev/null; then
  echo "  Zerolog"
else
  echo "  slog (stdlib)"
fi

# Validation
echo "--- Validation ---"
if grep -q 'github.com/go-playground/validator' "$GO_MOD" 2>/dev/null; then
  echo "  go-playground/validator"
fi

# Testing
echo "--- Testing ---"
if grep -q 'github.com/stretchr/testify' "$GO_MOD" 2>/dev/null; then
  echo "  Testify"
fi
if grep -q 'github.com/onsi/ginkgo' "$GO_MOD" 2>/dev/null; then
  echo "  Ginkgo"
fi

# Observability
echo "--- Observability ---"
if grep -q 'go.opentelemetry.io/otel' "$GO_MOD" 2>/dev/null; then
  echo "  OpenTelemetry"
fi
if grep -q 'github.com/prometheus/client_golang' "$GO_MOD" 2>/dev/null; then
  echo "  Prometheus"
fi

echo ""
echo "=== Detection Complete ==="
