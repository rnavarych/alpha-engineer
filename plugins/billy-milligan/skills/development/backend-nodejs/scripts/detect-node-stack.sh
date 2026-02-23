#!/usr/bin/env bash
# detect-node-stack.sh — Reads package.json to identify Node.js stack components
# Usage: ./detect-node-stack.sh [path/to/package.json]
set -euo pipefail

PACKAGE_JSON="${1:-package.json}"

if [ ! -f "$PACKAGE_JSON" ]; then
  echo "Error: $PACKAGE_JSON not found"
  exit 1
fi

echo "=== Node.js Stack Detection ==="
echo "File: $PACKAGE_JSON"
echo ""

# Framework detection
echo "--- Framework ---"
if grep -q '"fastify"' "$PACKAGE_JSON" 2>/dev/null; then
  echo "  Fastify"
elif grep -q '"express"' "$PACKAGE_JSON" 2>/dev/null; then
  echo "  Express"
elif grep -q '"@hono/node-server"\|"hono"' "$PACKAGE_JSON" 2>/dev/null; then
  echo "  Hono"
elif grep -q '"koa"' "$PACKAGE_JSON" 2>/dev/null; then
  echo "  Koa"
elif grep -q '"next"' "$PACKAGE_JSON" 2>/dev/null; then
  echo "  Next.js"
elif grep -q '"@nestjs/core"' "$PACKAGE_JSON" 2>/dev/null; then
  echo "  NestJS"
else
  echo "  (not detected)"
fi

# ORM / Database
echo "--- ORM / Database ---"
if grep -q '"drizzle-orm"' "$PACKAGE_JSON" 2>/dev/null; then
  echo "  Drizzle ORM"
fi
if grep -q '"@prisma/client"\|"prisma"' "$PACKAGE_JSON" 2>/dev/null; then
  echo "  Prisma"
fi
if grep -q '"knex"' "$PACKAGE_JSON" 2>/dev/null; then
  echo "  Knex"
fi
if grep -q '"typeorm"' "$PACKAGE_JSON" 2>/dev/null; then
  echo "  TypeORM"
fi
if grep -q '"mongoose"' "$PACKAGE_JSON" 2>/dev/null; then
  echo "  Mongoose (MongoDB)"
fi
if grep -q '"pg"\|"postgres"' "$PACKAGE_JSON" 2>/dev/null; then
  echo "  PostgreSQL driver"
fi

# Test runner
echo "--- Test Runner ---"
if grep -q '"vitest"' "$PACKAGE_JSON" 2>/dev/null; then
  echo "  Vitest"
elif grep -q '"jest"' "$PACKAGE_JSON" 2>/dev/null; then
  echo "  Jest"
elif grep -q '"mocha"' "$PACKAGE_JSON" 2>/dev/null; then
  echo "  Mocha"
fi

# Validation
echo "--- Validation ---"
if grep -q '"zod"' "$PACKAGE_JSON" 2>/dev/null; then
  echo "  Zod"
fi
if grep -q '"@sinclair/typebox"' "$PACKAGE_JSON" 2>/dev/null; then
  echo "  TypeBox"
fi
if grep -q '"joi"' "$PACKAGE_JSON" 2>/dev/null; then
  echo "  Joi"
fi

# Auth
echo "--- Auth ---"
if grep -q '"next-auth"\|"@auth/core"' "$PACKAGE_JSON" 2>/dev/null; then
  echo "  NextAuth / Auth.js"
fi
if grep -q '"jsonwebtoken"' "$PACKAGE_JSON" 2>/dev/null; then
  echo "  jsonwebtoken (JWT)"
fi
if grep -q '"passport"' "$PACKAGE_JSON" 2>/dev/null; then
  echo "  Passport.js"
fi

# Queue
echo "--- Queue ---"
if grep -q '"bullmq"\|"bull"' "$PACKAGE_JSON" 2>/dev/null; then
  echo "  BullMQ / Bull"
fi

echo ""
echo "=== Detection Complete ==="
