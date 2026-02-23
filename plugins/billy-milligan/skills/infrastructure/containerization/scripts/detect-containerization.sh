#!/usr/bin/env bash
# Detects containerization setup from project files
# Usage: ./detect-containerization.sh [project-root]

set -euo pipefail

ROOT="${1:-.}"
DETECTED=()

# Docker
[[ -f "$ROOT/Dockerfile" ]] && DETECTED+=("dockerfile")
for f in "$ROOT"/Dockerfile.*; do
  [[ -f "$f" ]] && DETECTED+=("dockerfile-variant:$(basename "$f")") && break
done

# Docker Compose
[[ -f "$ROOT/docker-compose.yml" || -f "$ROOT/docker-compose.yaml" || -f "$ROOT/compose.yml" || -f "$ROOT/compose.yaml" ]] && DETECTED+=("docker-compose")

# Kubernetes manifests
if find "$ROOT" -maxdepth 3 -name '*.yaml' -o -name '*.yml' 2>/dev/null | xargs grep -l 'kind: Deployment\|kind: Service\|kind: Pod' 2>/dev/null | head -1 > /dev/null 2>&1; then
  DETECTED+=("kubernetes")
fi

# Helm charts
[[ -f "$ROOT/Chart.yaml" || -d "$ROOT/charts" ]] && DETECTED+=("helm")

# Kustomize
[[ -f "$ROOT/kustomization.yaml" || -f "$ROOT/kustomization.yml" ]] && DETECTED+=("kustomize")

# .dockerignore
[[ -f "$ROOT/.dockerignore" ]] && DETECTED+=("dockerignore")

if [[ ${#DETECTED[@]} -eq 0 ]]; then
  echo "No containerization setup detected."
  exit 1
fi

echo "Detected containerization: ${DETECTED[*]}"
for item in "${DETECTED[@]}"; do
  case "$item" in
    dockerfile)
      echo "  Dockerfile found"
      if grep -q 'FROM.*AS' "$ROOT/Dockerfile" 2>/dev/null; then
        echo "    Multi-stage build: yes"
      else
        echo "    Multi-stage build: no (consider adding)"
      fi
      if grep -q '^USER' "$ROOT/Dockerfile" 2>/dev/null; then
        echo "    Non-root user: yes"
      else
        echo "    Non-root user: NO (security risk)"
      fi
      ;;
    docker-compose) echo "  Docker Compose config found" ;;
    kubernetes) echo "  Kubernetes manifests found" ;;
    helm) echo "  Helm chart found" ;;
    kustomize) echo "  Kustomize config found" ;;
    dockerignore) echo "  .dockerignore found" ;;
  esac
done

# Check for missing .dockerignore
if [[ -f "$ROOT/Dockerfile" ]] && [[ ! -f "$ROOT/.dockerignore" ]]; then
  echo ""
  echo "WARNING: Dockerfile exists but .dockerignore is missing."
  echo "  node_modules/ and .git/ will be sent to Docker daemon on every build."
fi
