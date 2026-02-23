#!/usr/bin/env bash
# detect-python-stack.sh — Reads requirements.txt/pyproject.toml to identify Python stack
# Usage: ./detect-python-stack.sh [project_directory]
set -euo pipefail

PROJECT_DIR="${1:-.}"
FOUND_FILE=""

# Find dependency file
if [ -f "$PROJECT_DIR/pyproject.toml" ]; then
  FOUND_FILE="$PROJECT_DIR/pyproject.toml"
elif [ -f "$PROJECT_DIR/requirements.txt" ]; then
  FOUND_FILE="$PROJECT_DIR/requirements.txt"
elif [ -f "$PROJECT_DIR/Pipfile" ]; then
  FOUND_FILE="$PROJECT_DIR/Pipfile"
elif [ -f "$PROJECT_DIR/setup.py" ]; then
  FOUND_FILE="$PROJECT_DIR/setup.py"
else
  echo "Error: No Python dependency file found in $PROJECT_DIR"
  exit 1
fi

echo "=== Python Stack Detection ==="
echo "File: $FOUND_FILE"
echo ""

# Framework detection
echo "--- Framework ---"
if grep -qi 'fastapi' "$FOUND_FILE" 2>/dev/null; then
  echo "  FastAPI"
elif grep -qi 'django' "$FOUND_FILE" 2>/dev/null; then
  echo "  Django"
elif grep -qi 'flask' "$FOUND_FILE" 2>/dev/null; then
  echo "  Flask"
elif grep -qi 'starlette' "$FOUND_FILE" 2>/dev/null; then
  echo "  Starlette"
elif grep -qi 'litestar' "$FOUND_FILE" 2>/dev/null; then
  echo "  Litestar"
else
  echo "  (not detected)"
fi

# ORM / Database
echo "--- ORM / Database ---"
if grep -qi 'sqlalchemy' "$FOUND_FILE" 2>/dev/null; then
  echo "  SQLAlchemy"
fi
if grep -qi 'alembic' "$FOUND_FILE" 2>/dev/null; then
  echo "  Alembic (migrations)"
fi
if grep -qi 'django' "$FOUND_FILE" 2>/dev/null; then
  echo "  Django ORM"
fi
if grep -qi 'tortoise-orm' "$FOUND_FILE" 2>/dev/null; then
  echo "  Tortoise ORM"
fi
if grep -qi 'asyncpg' "$FOUND_FILE" 2>/dev/null; then
  echo "  asyncpg (PostgreSQL async)"
fi
if grep -qi 'psycopg' "$FOUND_FILE" 2>/dev/null; then
  echo "  psycopg (PostgreSQL)"
fi
if grep -qi 'pymongo\|motor' "$FOUND_FILE" 2>/dev/null; then
  echo "  MongoDB (pymongo/motor)"
fi

# Validation
echo "--- Validation ---"
if grep -qi 'pydantic' "$FOUND_FILE" 2>/dev/null; then
  echo "  Pydantic"
fi
if grep -qi 'marshmallow' "$FOUND_FILE" 2>/dev/null; then
  echo "  Marshmallow"
fi

# Test runner
echo "--- Test Runner ---"
if grep -qi 'pytest' "$FOUND_FILE" 2>/dev/null; then
  echo "  pytest"
fi
if grep -qi 'unittest' "$FOUND_FILE" 2>/dev/null; then
  echo "  unittest"
fi

# Task queue
echo "--- Task Queue ---"
if grep -qi 'celery' "$FOUND_FILE" 2>/dev/null; then
  echo "  Celery"
fi
if grep -qi 'dramatiq' "$FOUND_FILE" 2>/dev/null; then
  echo "  Dramatiq"
fi
if grep -qi 'arq' "$FOUND_FILE" 2>/dev/null; then
  echo "  arq"
fi

# HTTP client
echo "--- HTTP Client ---"
if grep -qi 'httpx' "$FOUND_FILE" 2>/dev/null; then
  echo "  httpx"
fi
if grep -qi 'aiohttp' "$FOUND_FILE" 2>/dev/null; then
  echo "  aiohttp"
fi
if grep -qi 'requests' "$FOUND_FILE" 2>/dev/null; then
  echo "  requests (sync)"
fi

echo ""
echo "=== Detection Complete ==="
