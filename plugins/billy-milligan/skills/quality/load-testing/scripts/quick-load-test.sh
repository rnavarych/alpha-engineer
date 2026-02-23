#!/usr/bin/env bash
# quick-load-test.sh — Generates and runs a k6 load test script
# Usage: ./quick-load-test.sh <URL> [RPS] [DURATION_SECONDS]
set -euo pipefail

URL="${1:-}"
RPS="${2:-50}"
DURATION="${3:-60}"

if [ -z "$URL" ]; then
  echo "Usage: $0 <URL> [RPS] [DURATION_SECONDS]"
  echo "Example: $0 https://api.example.com/health 100 120"
  exit 1
fi

if ! command -v k6 &>/dev/null; then
  echo "k6 not found. Install: brew install k6 (macOS) or see https://k6.io/docs/get-started/installation/"
  exit 1
fi

SCRIPT_FILE=$(mktemp /tmp/k6-script-XXXXXX.js)

cat > "$SCRIPT_FILE" << ENDSCRIPT
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  scenarios: {
    load_test: {
      executor: 'constant-arrival-rate',
      rate: ${RPS},
      timeUnit: '1s',
      duration: '${DURATION}s',
      preAllocatedVUs: Math.ceil(${RPS} * 2),
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  const res = http.get('${URL}');
  check(res, {
    'status is 2xx': (r) => r.status >= 200 && r.status < 300,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
}
ENDSCRIPT

echo "=== Quick Load Test ==="
echo "URL: $URL"
echo "Target: $RPS RPS for ${DURATION}s"
echo "Script: $SCRIPT_FILE"
echo ""

k6 run "$SCRIPT_FILE"

rm -f "$SCRIPT_FILE"
