---
name: load-testing
description: |
  Load testing with k6: script with stages (ramp-up/hold/ramp-down), thresholds
  (p99<500ms, errors<1%), spike test for finding breaking point, k6 in CI with failure
  on thresholds, soak testing, Locust for Python teams, common bottleneck patterns.
  Use when verifying performance, finding capacity limits, load testing before launch.
allowed-tools: Read, Grep, Glob
---

# Load Testing

## When to Use This Skill
- Verifying performance before a product launch
- Finding capacity limits and breaking points
- Setting up performance regression in CI
- Diagnosing under which load specific endpoints degrade
- Comparing performance before and after optimization

## Core Principles

1. **Test in production-like environment** — load test results from dev are meaningless
2. **Warm up before measuring** — cold start skews results
3. **Define thresholds before running** — not after seeing results
4. **Soak testing finds leaks** — sustained load reveals memory leaks and connection exhaustion
5. **Watch the database, not just the app** — DB is usually the bottleneck

---

## Patterns ✅

### k6 Load Test Script

```javascript
// load-tests/orders-api.js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const orderCreationTime = new Trend('order_creation_time', true);  // true = milliseconds
const ordersCreated = new Counter('orders_created');

export const options = {
  stages: [
    { duration: '2m', target: 20 },   // Ramp up: 0 → 20 VUs over 2 minutes
    { duration: '5m', target: 20 },   // Hold: 20 VUs for 5 minutes
    { duration: '2m', target: 100 },  // Ramp up to peak: 20 → 100 VUs
    { duration: '5m', target: 100 },  // Hold peak for 5 minutes
    { duration: '2m', target: 0 },    // Ramp down: 100 → 0 VUs
  ],

  // Thresholds — test FAILS if these are violated
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],  // p95 < 500ms, p99 < 1s
    http_req_failed: ['rate<0.01'],   // Error rate < 1%
    errors: ['rate<0.01'],
    order_creation_time: ['p(95)<800'],  // Custom threshold
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';
const AUTH_TOKEN = __ENV.AUTH_TOKEN;

export function setup() {
  // Setup: verify API is reachable
  const res = http.get(`${BASE_URL}/health`);
  if (res.status !== 200) {
    throw new Error(`API health check failed: ${res.status}`);
  }
  return { token: AUTH_TOKEN };
}

export default function (data) {
  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${data.token}`,
  };

  // Scenario 1: List orders (read-heavy, most traffic)
  const listResponse = http.get(`${BASE_URL}/api/orders?page=1&limit=20`, { headers });
  check(listResponse, {
    'list orders status 200': (r) => r.status === 200,
    'list orders has data': (r) => JSON.parse(r.body).data.length > 0,
  });
  errorRate.add(listResponse.status !== 200);

  sleep(1);  // 1 second think time between requests

  // Scenario 2: Create order (write, lower frequency)
  const start = Date.now();
  const createResponse = http.post(
    `${BASE_URL}/api/orders`,
    JSON.stringify({
      customerId: 'cus_test_123',
      items: [{ productId: 'prod_456', quantity: 1 }],
    }),
    { headers }
  );

  const duration = Date.now() - start;
  orderCreationTime.add(duration);

  check(createResponse, {
    'create order status 201': (r) => r.status === 201,
    'create order has id': (r) => JSON.parse(r.body).id !== undefined,
  });

  if (createResponse.status === 201) {
    ordersCreated.add(1);
  }
  errorRate.add(createResponse.status !== 201);

  sleep(Math.random() * 3);  // Random think time 0-3 seconds
}
```

### Spike Test (Finding Breaking Point)

```javascript
// spike-test.js — sudden traffic spike to find breaking point
export const options = {
  stages: [
    { duration: '1m', target: 10 },    // Warm up
    { duration: '30s', target: 500 },  // Spike: 10 → 500 VUs suddenly
    { duration: '5m', target: 500 },   // Hold spike
    { duration: '30s', target: 10 },   // Drop back
    { duration: '5m', target: 10 },    // Recovery period — does it recover?
  ],
  thresholds: {
    http_req_duration: ['p(99)<5000'],  // Relaxed threshold for spike test
    http_req_failed: ['rate<0.10'],     // Accept up to 10% errors during spike
  },
};
```

### k6 in CI/CD

```yaml
# .github/workflows/performance.yml
name: Performance Tests

on:
  schedule:
    - cron: '0 2 * * *'  # Nightly
  workflow_dispatch:      # Manual trigger

jobs:
  load-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run load test
        uses: grafana/k6-action@v0.3.0
        with:
          filename: load-tests/orders-api.js
          flags: --vus 10 --duration 2m  # Quick validation in CI
        env:
          BASE_URL: ${{ secrets.STAGING_URL }}
          AUTH_TOKEN: ${{ secrets.LOAD_TEST_TOKEN }}
          K6_CLOUD_TOKEN: ${{ secrets.K6_CLOUD_TOKEN }}

      # k6 returns exit code 1 if thresholds violated — CI fails automatically
```

### Observing During Load Test

```bash
# Run load test + watch metrics simultaneously

# Terminal 1: run k6
k6 run --vus 50 --duration 5m load-tests/orders-api.js

# Terminal 2: watch PostgreSQL connections
watch -n 5 'psql $DATABASE_URL -c "SELECT count(*) FROM pg_stat_activity"'

# Terminal 3: watch application metrics
# In Grafana: RED dashboard during test
# Watch: http_request_duration_seconds (p99), error rate, active DB connections

# PostgreSQL: slow queries during load test
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
WHERE mean_exec_time > 100  -- Queries taking >100ms on average
ORDER BY total_exec_time DESC
LIMIT 10;
```

### Performance Thresholds Reference

```
API endpoint thresholds (typical production targets):
  Auth endpoints:     p99 < 200ms
  Read endpoints:     p99 < 500ms
  Write endpoints:    p99 < 1000ms
  Complex reports:    p99 < 3000ms

Error rate thresholds:
  During normal load: < 0.1%
  During peak load:   < 1%
  During spike:       < 5%

Database thresholds (watch during load test):
  Query execution:     p99 < 100ms (simple), < 500ms (complex)
  Connection count:    < 80% of max_connections
  Lock wait time:      < 10ms average
```

---

## Anti-Patterns ❌

### Testing in Development Environment
**What it is**: Running load tests against `localhost` or a dev environment.
**What breaks**: No network latency, different hardware, no production caching config, no load balancer. Results are meaningless. You'll either over-optimize for fake conditions or miss real bottlenecks.
**Fix**: Test against staging with production-equivalent infrastructure.

### Not Defining Thresholds Beforehand
**What it is**: Running the test, seeing results, then deciding if they're acceptable.
**What breaks**: "Well, p99 of 2 seconds is okay I guess." Threshold becomes the measured result. No performance regression detection.
**Fix**: Define thresholds in test file before running. Thresholds must come from SLOs or business requirements.

### Only Testing Happy Path Under Load
**What it is**: Load test only successful requests, no errors simulated.
**What breaks**: Real traffic has 5-10% error retry patterns. Payment failures trigger retry logic. Under load with retries, throughput is lower than predicted.
**Fix**: Include error scenarios in load test. Mixed read/write traffic. Include retry behavior.

---

## Quick Reference

```
k6 stages: ramp-up (2m) → hold (5m) → peak (2m) → hold-peak (5m) → ramp-down (2m)
Thresholds: p95 < 500ms, p99 < 1000ms, error rate < 1%
Spike test: sudden 10x→50x spike, then measure recovery
Soak test: 24h+ at normal load → find memory leaks, connection exhaustion
CI integration: k6 exits 1 on threshold violation → CI fails
DB connection monitoring: watch during test (should stay < 80% max_connections)
Think time: sleep(1) to sleep(3) — simulates real user pace between requests
```
