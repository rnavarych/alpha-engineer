#!/usr/bin/env bash
# detect-architecture.sh — Analyzes project structure to identify architectural pattern
# Usage: ./detect-architecture.sh [project-root]
# Output: Architectural pattern + key indicators found

set -euo pipefail

PROJECT_ROOT="${1:-$PWD}"
INDICATORS=()
PATTERN="unknown"

# Check for microservices indicators
if [ -d "$PROJECT_ROOT/services" ] || [ -d "$PROJECT_ROOT/apps" ]; then
  SERVICE_COUNT=$(find "$PROJECT_ROOT/services" "$PROJECT_ROOT/apps" -maxdepth 1 -type d 2>/dev/null | wc -l)
  if [ "$SERVICE_COUNT" -gt 3 ]; then
    INDICATORS+=("multiple service directories ($SERVICE_COUNT)")
    PATTERN="microservices"
  fi
fi

# Check for docker-compose with multiple services
if [ -f "$PROJECT_ROOT/docker-compose.yml" ] || [ -f "$PROJECT_ROOT/docker-compose.yaml" ]; then
  COMPOSE_FILE=$(find "$PROJECT_ROOT" -maxdepth 1 -name "docker-compose*" | head -1)
  COMPOSE_SERVICES=$(grep -c "^\s*[a-z].*:" "$COMPOSE_FILE" 2>/dev/null || echo 0)
  if [ "$COMPOSE_SERVICES" -gt 5 ]; then
    INDICATORS+=("docker-compose with $COMPOSE_SERVICES services")
    [ "$PATTERN" = "unknown" ] && PATTERN="microservices"
  fi
fi

# Check for Kubernetes manifests
if [ -d "$PROJECT_ROOT/k8s" ] || [ -d "$PROJECT_ROOT/kubernetes" ] || [ -d "$PROJECT_ROOT/deploy" ]; then
  K8S_DEPLOYMENTS=$(find "$PROJECT_ROOT" -name "*.yaml" -path "*/k8s/*" -o -name "*.yaml" -path "*/kubernetes/*" -o -name "*.yaml" -path "*/deploy/*" 2>/dev/null | head -20 | wc -l)
  if [ "$K8S_DEPLOYMENTS" -gt 3 ]; then
    INDICATORS+=("kubernetes manifests ($K8S_DEPLOYMENTS files)")
  fi
fi

# Check for modular monolith
if [ -d "$PROJECT_ROOT/src/modules" ] || [ -d "$PROJECT_ROOT/lib/modules" ]; then
  MODULE_COUNT=$(find "$PROJECT_ROOT/src/modules" "$PROJECT_ROOT/lib/modules" -maxdepth 1 -type d 2>/dev/null | wc -l)
  if [ "$MODULE_COUNT" -gt 2 ]; then
    INDICATORS+=("module directories ($MODULE_COUNT modules)")
    [ "$PATTERN" = "unknown" ] && PATTERN="modular-monolith"
  fi
fi

# Check for serverless
if [ -f "$PROJECT_ROOT/serverless.yml" ] || [ -f "$PROJECT_ROOT/serverless.ts" ]; then
  INDICATORS+=("serverless framework config")
  [ "$PATTERN" = "unknown" ] && PATTERN="serverless"
fi
if [ -f "$PROJECT_ROOT/template.yaml" ] && grep -q "AWS::Serverless" "$PROJECT_ROOT/template.yaml" 2>/dev/null; then
  INDICATORS+=("AWS SAM template")
  [ "$PATTERN" = "unknown" ] && PATTERN="serverless"
fi
if [ -f "$PROJECT_ROOT/firebase.json" ] && grep -q "functions" "$PROJECT_ROOT/firebase.json" 2>/dev/null; then
  INDICATORS+=("Firebase Functions config")
  [ "$PATTERN" = "unknown" ] && PATTERN="serverless"
fi

# Check for monolith (single src/ without modules)
if [ -d "$PROJECT_ROOT/src" ] && [ ! -d "$PROJECT_ROOT/src/modules" ] && [ ! -d "$PROJECT_ROOT/services" ]; then
  SRC_DIRS=$(find "$PROJECT_ROOT/src" -maxdepth 1 -type d | wc -l)
  if [ "$SRC_DIRS" -lt 10 ]; then
    INDICATORS+=("single src/ directory without module structure")
    [ "$PATTERN" = "unknown" ] && PATTERN="monolith"
  fi
fi

# Output results
echo "## Architecture Detection Results"
echo ""
echo "**Pattern**: $PATTERN"
echo ""
echo "**Indicators found**:"
for indicator in "${INDICATORS[@]:-}"; do
  [ -n "$indicator" ] && echo "  - $indicator"
done

if [ ${#INDICATORS[@]} -eq 0 ]; then
  echo "  - No strong architectural indicators found"
  echo "  - Check: is this a library/package rather than an application?"
fi
