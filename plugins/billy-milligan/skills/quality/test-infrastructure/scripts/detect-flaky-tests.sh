#!/usr/bin/env bash
# detect-flaky-tests.sh — Runs tests N times to identify flaky tests
# Usage: ./detect-flaky-tests.sh [test-command] [runs]
set -euo pipefail

TEST_CMD="${1:-npx vitest run}"
RUNS="${2:-5}"
RESULTS_DIR=$(mktemp -d)
FLAKY_TESTS=()

echo "=== Flaky Test Detection ==="
echo "Command: $TEST_CMD"
echo "Runs: $RUNS"
echo "Results: $RESULTS_DIR"
echo ""

for i in $(seq 1 "$RUNS"); do
  echo "--- Run $i/$RUNS ---"
  if $TEST_CMD --reporter=json > "$RESULTS_DIR/run-$i.json" 2>&1; then
    echo "  PASSED"
  else
    echo "  FAILED (some tests failed)"
  fi
done

echo ""
echo "=== Analysis ==="

# Compare results across runs
PASS_COUNTS=()
FAIL_COUNTS=()

echo "Tests that passed in some runs and failed in others are FLAKY."
echo ""

# Simple analysis: count unique failure sets
FAILURES_PER_RUN=""
for i in $(seq 1 "$RUNS"); do
  if [ -f "$RESULTS_DIR/run-$i.json" ]; then
    FAIL_COUNT=$(python3 -c "
import json, sys
try:
    with open('$RESULTS_DIR/run-$i.json') as f:
        data = json.load(f)
    failed = [t['name'] for t in data.get('testResults', [])
              for r in t.get('assertionResults', [])
              if r.get('status') == 'failed']
    for name in failed:
        print(name)
except:
    pass
" 2>/dev/null || echo "")
    if [ -n "$FAIL_COUNT" ]; then
      echo "Run $i failures:"
      echo "$FAIL_COUNT" | while read -r line; do echo "  - $line"; done
    fi
  fi
done

echo ""
echo "If the same test fails in some runs but not all, it is flaky."
echo "Review results in: $RESULTS_DIR"
echo ""
echo "=== Done ==="
