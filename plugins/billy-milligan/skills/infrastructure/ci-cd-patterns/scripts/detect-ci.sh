#!/usr/bin/env bash
# Detects CI/CD platform from project files
# Usage: ./detect-ci.sh [project-root]

set -euo pipefail

ROOT="${1:-.}"
DETECTED=()

[[ -d "$ROOT/.github/workflows" ]] && DETECTED+=("github-actions")
[[ -f "$ROOT/.gitlab-ci.yml" ]] && DETECTED+=("gitlab-ci")
[[ -f "$ROOT/Jenkinsfile" ]] && DETECTED+=("jenkins")
[[ -d "$ROOT/.circleci" ]] && DETECTED+=("circleci")
[[ -f "$ROOT/bitbucket-pipelines.yml" ]] && DETECTED+=("bitbucket-pipelines")
[[ -f "$ROOT/azure-pipelines.yml" ]] && DETECTED+=("azure-devops")
[[ -f "$ROOT/.travis.yml" ]] && DETECTED+=("travis-ci")
[[ -f "$ROOT/cloudbuild.yaml" || -f "$ROOT/cloudbuild.json" ]] && DETECTED+=("google-cloud-build")

if [[ ${#DETECTED[@]} -eq 0 ]]; then
  echo "No CI/CD platform detected."
  exit 1
fi

echo "Detected CI/CD platform(s): ${DETECTED[*]}"
for ci in "${DETECTED[@]}"; do
  case "$ci" in
    github-actions)
      count=$(find "$ROOT/.github/workflows" -name '*.yml' -o -name '*.yaml' 2>/dev/null | wc -l | tr -d ' ')
      echo "  GitHub Actions: ${count} workflow file(s)"
      ;;
    gitlab-ci)
      echo "  GitLab CI: .gitlab-ci.yml found"
      ;;
    jenkins)
      echo "  Jenkins: Jenkinsfile found"
      ;;
    circleci)
      echo "  CircleCI: .circleci/ directory found"
      ;;
    bitbucket-pipelines)
      echo "  Bitbucket Pipelines: bitbucket-pipelines.yml found"
      ;;
    azure-devops)
      echo "  Azure DevOps: azure-pipelines.yml found"
      ;;
    travis-ci)
      echo "  Travis CI: .travis.yml found"
      ;;
    google-cloud-build)
      echo "  Google Cloud Build: cloudbuild config found"
      ;;
  esac
done
