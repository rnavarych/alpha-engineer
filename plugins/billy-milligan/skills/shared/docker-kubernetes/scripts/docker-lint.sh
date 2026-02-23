#!/usr/bin/env bash
# Docker/Kubernetes lint: validate Dockerfile + K8s manifests
# Usage: docker-lint.sh [path]
set -euo pipefail

DIR="${1:-.}"
ERRORS=0

echo "=== Docker & Kubernetes Linter ==="
echo "Scanning: $DIR"
echo ""

# --- Dockerfile checks ---
find "$DIR" -name "Dockerfile*" -not -path "*node_modules*" | while read -r dockerfile; do
  echo "--- Checking: $dockerfile ---"

  # Check: running as root
  if ! grep -q "^USER " "$dockerfile" 2>/dev/null; then
    echo "  WARN: No USER directive — container runs as root"
  fi

  # Check: using latest tag
  if grep -qE "^FROM .+:latest" "$dockerfile" 2>/dev/null; then
    echo "  ERROR: Using :latest tag — pin to specific version"
    ERRORS=$((ERRORS + 1))
  fi

  # Check: no HEALTHCHECK
  if ! grep -q "^HEALTHCHECK " "$dockerfile" 2>/dev/null; then
    echo "  WARN: No HEALTHCHECK directive"
  fi

  # Check: COPY . . before package install (cache bust)
  COPY_ALL_LINE=$(grep -n "^COPY \. \." "$dockerfile" 2>/dev/null | head -1 | cut -d: -f1)
  NPM_INSTALL_LINE=$(grep -n "npm ci\|npm install\|yarn install\|pnpm install" "$dockerfile" 2>/dev/null | head -1 | cut -d: -f1)
  if [ -n "$COPY_ALL_LINE" ] && [ -n "$NPM_INSTALL_LINE" ]; then
    if [ "$COPY_ALL_LINE" -lt "$NPM_INSTALL_LINE" ]; then
      echo "  WARN: COPY . . before package install — busts layer cache"
    fi
  fi

  # Check: .dockerignore exists
  DOCKER_DIR=$(dirname "$dockerfile")
  if [ ! -f "$DOCKER_DIR/.dockerignore" ] && [ ! -f "$DIR/.dockerignore" ]; then
    echo "  WARN: No .dockerignore found"
  fi

  echo ""
done

# --- Kubernetes manifest checks ---
find "$DIR" -name "*.yaml" -o -name "*.yml" | while read -r manifest; do
  # Only check K8s manifests (must have apiVersion)
  if ! grep -q "apiVersion:" "$manifest" 2>/dev/null; then
    continue
  fi

  echo "--- Checking: $manifest ---"

  # Check: no resource limits
  if grep -q "kind: Deployment\|kind: StatefulSet" "$manifest" && ! grep -q "limits:" "$manifest" 2>/dev/null; then
    echo "  WARN: No resource limits defined"
  fi

  # Check: no readiness probe
  if grep -q "kind: Deployment" "$manifest" && ! grep -q "readinessProbe:" "$manifest" 2>/dev/null; then
    echo "  WARN: No readinessProbe defined"
  fi

  # Check: using latest tag
  if grep -qE "image:.*:latest" "$manifest" 2>/dev/null; then
    echo "  ERROR: Using :latest image tag"
    ERRORS=$((ERRORS + 1))
  fi

  # Check: secrets in plain text (stringData in non-sealed secrets)
  if grep -q "kind: Secret" "$manifest" && grep -q "stringData:" "$manifest" 2>/dev/null; then
    echo "  WARN: Plain-text secrets in manifest — use External Secrets or Sealed Secrets"
  fi

  echo ""
done

echo "=== Done ==="
if [ "$ERRORS" -gt 0 ]; then
  echo "Found $ERRORS error(s)"
  exit 1
else
  echo "All checks passed"
fi
